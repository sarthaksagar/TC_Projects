import 'dart:convert';
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/test_case_model.dart';
import '../utils/app_logger.dart';

class TestCaseRepository {
  SupabaseClient get _client => Supabase.instance.client;
  List<TestCaseModel> _items = [];
  bool _hasFetchedFromRemote = false;

  TestCaseRepository() {
    _loadFromLocalStorage();
  }

  List<TestCaseModel> get cachedItems => _items.where((tc) => !_isDummyMock(tc)).toList();

  bool _isDummyMock(TestCaseModel tc) {
    final title = tc.title.toLowerCase().trim();
    final code = tc.code.toLowerCase().trim();
    return title.contains('verify valid user login') ||
        title.contains('verify invalid login credentials') ||
        title.contains('verify session management') ||
        title.contains('verify oauth2 google single sign-on') ||
        code.startsWith('tc-14c4') ||
        code.startsWith('tc-2c44') ||
        code.startsWith('tc-9314') ||
        code == 'tc-101' ||
        code == 'tc-102' ||
        code == 'tc-103' ||
        code == 'tc-104' ||
        code == 'tc-105' ||
        code == 'tc-106';
  }

  void _loadFromLocalStorage() {
    try {
      final cached = html.window.localStorage['saved_test_cases_json'];
      if (cached != null && cached.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cached);
        final loaded = list.map((e) => TestCaseModel.fromJson(Map<String, dynamic>.from(e))).toList();
        _items = loaded.where((tc) => !_isDummyMock(tc)).toList();
        AppLogger.info('TestCaseRepository', 'Loaded ${_items.length} test cases from browser localStorage');
      }
    } catch (e) {
      AppLogger.error('TestCaseRepository', 'Failed to read localStorage', e);
    }
  }

  void _saveToLocalStorage() {
    try {
      final clean = _items.where((tc) => !_isDummyMock(tc)).toList();
      final jsonStr = jsonEncode(clean.map((e) => e.toJson()).toList());
      html.window.localStorage['saved_test_cases_json'] = jsonStr;
      AppLogger.log('TestCaseRepository', 'Saved ${clean.length} test cases to browser localStorage');
    } catch (e) {
      AppLogger.error('TestCaseRepository', 'Failed to save to localStorage', e);
    }
  }

  Future<List<TestCaseModel>> getTestCases() async {
    if (_hasFetchedFromRemote && _items.isNotEmpty) {
      AppLogger.log('TestCaseRepository', 'Returning cached list (${_items.length} cases)');
      return cachedItems;
    }

    try {
      AppLogger.info('TestCaseRepository', 'Fetching test cases from Supabase...');
      final res = await _client
          .from('test_cases')
          .select()
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 3));

      final list = (res as List<dynamic>).map((e) => TestCaseModel.fromJson(Map<String, dynamic>.from(e))).toList();
      _hasFetchedFromRemote = true;

      // Filter out and delete mock dummy cases from database
      final dummyCases = list.where(_isDummyMock).toList();
      for (final d in dummyCases) {
        AppLogger.warn('TestCaseRepository', 'Purging dummy mock case from database: ${d.code}');
        _client.from('test_cases').delete().eq('id', d.id).then((_) {}).catchError((_) {});
      }

      final cleanRemote = list.where((tc) => !_isDummyMock(tc)).toList();
      if (cleanRemote.isNotEmpty) {
        // Merge remote with local cache so rich local fields are NEVER wiped by partial remote columns
        final map = <String, TestCaseModel>{};
        for (final tc in _items) {
          if (!_isDummyMock(tc)) map[tc.id] = tc;
        }
        for (final remote in cleanRemote) {
          if (map.containsKey(remote.id)) {
            map[remote.id] = _merge(map[remote.id]!, remote);
          } else {
            map[remote.id] = remote;
          }
        }
        _items = map.values.toList();
        _saveToLocalStorage();
      }

      AppLogger.success('TestCaseRepository', 'Loaded ${_items.length} clean test cases');
      return cachedItems;
    } catch (e) {
      AppLogger.warn('TestCaseRepository', 'Supabase fetch timed out or offline, returning cached (${_items.length} cases)');
      return cachedItems;
    }
  }

  TestCaseModel _merge(TestCaseModel local, TestCaseModel remote) {
    return TestCaseModel(
      id: remote.id.isNotEmpty ? remote.id : local.id,
      code: remote.code.isNotEmpty && !remote.code.startsWith('TC-100') ? remote.code : local.code,
      title: remote.title.isNotEmpty ? remote.title : local.title,
      description: remote.description.isNotEmpty ? remote.description : local.description,
      module: remote.module.isNotEmpty && remote.module != 'General Module' ? remote.module : local.module,
      feature: remote.feature.isNotEmpty && remote.feature != 'Core Feature' ? remote.feature : local.feature,
      preconditions: remote.preconditions.isNotEmpty && remote.preconditions != 'None' ? remote.preconditions : local.preconditions,
      steps: remote.steps.isNotEmpty ? remote.steps : local.steps,
      testData: remote.testData.isNotEmpty && remote.testData != 'N/A' ? remote.testData : local.testData,
      expectedResult: remote.expectedResult.isNotEmpty ? remote.expectedResult : local.expectedResult,
      actualResult: remote.actualResult.isNotEmpty && remote.actualResult != 'N/A' ? remote.actualResult : local.actualResult,
      status: remote.status,
      priority: remote.priority,
      type: remote.type.isNotEmpty && remote.type != 'Functional' ? remote.type : local.type,
      assignedTo: remote.assignedTo.isNotEmpty && remote.assignedTo != 'Unassigned' ? remote.assignedTo : local.assignedTo,
      createdBy: remote.createdBy.isNotEmpty && remote.createdBy != 'System' ? remote.createdBy : local.createdBy,
      updatedAt: remote.updatedAt.isAfter(local.updatedAt) ? remote.updatedAt : local.updatedAt,
      executionDate: remote.executionDate ?? local.executionDate,
      remarks: remote.remarks.isNotEmpty && remote.remarks != 'N/A' ? remote.remarks : local.remarks,
      suiteId: remote.suiteId.isNotEmpty ? remote.suiteId : local.suiteId,
      suiteName: remote.suiteName.isNotEmpty && remote.suiteName != 'General Suite' ? remote.suiteName : local.suiteName,
    );
  }

  Future<TestCaseModel> addTestCase(TestCaseModel testCase) async {
    _items.insert(0, testCase);
    _saveToLocalStorage();
    await _upsertToSupabase(testCase);
    return testCase;
  }

  Future<void> addTestCasesBatch(List<TestCaseModel> testCases) async {
    _items.insertAll(0, testCases);
    _saveToLocalStorage();
    await _upsertBatchToSupabase(testCases, label: 'insert batch');
  }

  Future<TestCaseModel> updateTestCase(TestCaseModel testCase) async {
    final index = _items.indexWhere((tc) => tc.id == testCase.id);
    if (index != -1) {
      _items[index] = testCase;
      _saveToLocalStorage();
    }
    await _upsertToSupabase(testCase);
    return testCase;
  }

  Future<void> updateTestCasesBatch(List<TestCaseModel> updatedCases) async {
    for (final updated in updatedCases) {
      final index = _items.indexWhere((tc) => tc.id == updated.id);
      if (index != -1) {
        _items[index] = updated;
      }
    }
    _saveToLocalStorage();
    await _upsertBatchToSupabase(updatedCases, label: 'update batch');
  }

  Future<void> deleteTestCase(String id) async {
    _items.removeWhere((tc) => tc.id == id);
    _saveToLocalStorage();
    AppLogger.warn('TestCaseRepository', 'Deleting test case ID $id from Supabase');
    try {
      await _client.from('test_cases').delete().eq('id', id);
      AppLogger.success('TestCaseRepository', 'Deleted test case ID $id from Supabase');
    } catch (e) {
      AppLogger.error('TestCaseRepository', 'Failed to delete $id from Supabase', e);
    }
  }

  Future<void> clearAll() async {
    _items.clear();
    _saveToLocalStorage();
    AppLogger.warn('TestCaseRepository', 'Clearing all test cases from storage and database');
    try {
      html.window.localStorage.remove('saved_test_cases_json');
    } catch (_) {}
    try {
      await _client.from('test_cases').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      AppLogger.success('TestCaseRepository', 'Cleared all records from Supabase table test_cases');
    } catch (e) {
      AppLogger.error('TestCaseRepository', 'Failed to clear Supabase test_cases table', e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _upsertToSupabase(TestCaseModel tc) async {
    final currentUserId = _client.auth.currentUser?.id;
    final payload = tc.toSupabaseJson(fallbackUserId: currentUserId);
    if (payload.isEmpty) {
      AppLogger.warn('TestCaseRepository', 'Skipping Supabase sync for ${tc.code} — non-UUID id: ${tc.id}');
      return;
    }
    AppLogger.info('TestCaseRepository', 'Syncing test case to Supabase: ${tc.code} (id: ${tc.id})');
    try {
      await _client.from('test_cases').upsert(payload);
      AppLogger.success('TestCaseRepository', '✅ Supabase upsert OK: ${tc.code}');
    } catch (e) {
      if (e.toString().contains('42501') || e.toString().contains('row-level security')) {
        AppLogger.warn('TestCaseRepository', '⚠️ Supabase RLS blocked write for ${tc.code}. Saved in local storage.');
      } else {
        AppLogger.error('TestCaseRepository', '❌ Supabase upsert FAILED for ${tc.code}', e);
      }
    }
  }

  Future<void> _upsertBatchToSupabase(List<TestCaseModel> cases, {required String label}) async {
    final currentUserId = _client.auth.currentUser?.id;
    final validCases = cases.where((tc) => tc.toSupabaseJson(fallbackUserId: currentUserId).isNotEmpty).toList();
    final skipped = cases.length - validCases.length;

    if (skipped > 0) {
      AppLogger.warn('TestCaseRepository', 'Skipping $skipped non-UUID test cases from Supabase $label');
    }
    if (validCases.isEmpty) {
      AppLogger.warn('TestCaseRepository', 'No valid UUID test cases to sync in $label');
      return;
    }

    AppLogger.info('TestCaseRepository', 'Supabase $label: ${validCases.length} cases');
    final jsonList = validCases.map((tc) => tc.toSupabaseJson(fallbackUserId: currentUserId)).toList();
    try {
      await _client.from('test_cases').upsert(jsonList);
      AppLogger.success('TestCaseRepository', '✅ Supabase $label upsert OK: ${validCases.length} cases');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('42501') || errStr.contains('row-level security')) {
        AppLogger.warn('TestCaseRepository', '⚠️ Supabase Row-Level Security (RLS) blocked cloud sync (Code 42501). Data is safely saved in local storage. To enable cloud sync, apply the RLS policy in Supabase SQL Editor.');
        return;
      }
      AppLogger.error('TestCaseRepository', '❌ Supabase $label upsert FAILED — retrying individually', e);
      // Retry individually to salvage as many as possible
      int successCount = 0;
      for (final tc in validCases) {
        try {
          await _client.from('test_cases').upsert(tc.toSupabaseJson(fallbackUserId: currentUserId));
          successCount++;
        } catch (indivErr) {
          AppLogger.error('TestCaseRepository', '❌ Individual upsert failed for ${tc.code}', indivErr);
        }
      }
      AppLogger.info('TestCaseRepository', 'Individual retry: $successCount/${validCases.length} succeeded');
    }
  }
}
