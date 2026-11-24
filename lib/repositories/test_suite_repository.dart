import 'dart:convert';
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/test_suite_model.dart';
import '../utils/app_logger.dart';

class TestSuiteRepository {
  SupabaseClient get _client => Supabase.instance.client;
  List<TestSuiteModel> _items = [];
  bool _hasFetchedFromRemote = false;

  TestSuiteRepository() {
    _loadFromLocalStorage();
  }

  List<TestSuiteModel> get cachedItems => _items;

  void _loadFromLocalStorage() {
    try {
      final cached = html.window.localStorage['saved_test_suites_json'];
      if (cached != null && cached.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cached);
        final raw = list.map((e) => TestSuiteModel.fromJson(Map<String, dynamic>.from(e))).toList();
        
        // Deduplicate suites by id and name
        final seen = <String>{};
        _items = [];
        for (final s in raw) {
          final key = '${s.id}_${s.name.toLowerCase()}';
          if (!seen.contains(key)) {
            seen.add(key);
            _items.add(s);
          }
        }
        AppLogger.info('TestSuiteRepository', 'Loaded ${_items.length} unique suites from browser localStorage');
        _saveToLocalStorage();
      }
    } catch (e) {
      AppLogger.error('TestSuiteRepository', 'Failed to read suites from localStorage', e);
    }
  }

  void _saveToLocalStorage() {
    try {
      // Deduplicate before saving
      final seen = <String>{};
      final clean = <TestSuiteModel>[];
      for (final s in _items) {
        final key = '${s.id}_${s.name.toLowerCase()}';
        if (!seen.contains(key)) {
          seen.add(key);
          clean.add(s);
        }
      }
      _items = clean;
      final jsonStr = jsonEncode(clean.map((e) => e.toJson()).toList());
      html.window.localStorage['saved_test_suites_json'] = jsonStr;
      AppLogger.log('TestSuiteRepository', 'Saved ${clean.length} unique suites to browser localStorage');
    } catch (e) {
      AppLogger.error('TestSuiteRepository', 'Failed to save suites to localStorage', e);
    }
  }

  Future<List<TestSuiteModel>> getTestSuites() async {
    if (_hasFetchedFromRemote && _items.isNotEmpty) {
      return _items;
    }

    try {
      AppLogger.info('TestSuiteRepository', 'Fetching test suites from Supabase...');
      final res = await _client.from('test_suites').select().order('created_at', ascending: false).timeout(const Duration(seconds: 3));
      final list = (res as List<dynamic>).map((e) => TestSuiteModel.fromJson(Map<String, dynamic>.from(e))).toList();
      _hasFetchedFromRemote = true;

      // Merge and deduplicate with local cache
      final seen = <String>{};
      final merged = <TestSuiteModel>[];
      for (final s in [..._items, ...list]) {
        final key = '${s.id}_${s.name.toLowerCase()}';
        if (!seen.contains(key)) {
          seen.add(key);
          merged.add(s);
        }
      }
      _items = merged;
      _saveToLocalStorage();
      AppLogger.success('TestSuiteRepository', 'Loaded ${_items.length} test suites');
      return _items;
    } catch (e) {
      AppLogger.warn('TestSuiteRepository', 'Supabase fetch timed out or offline, using local cache (${_items.length} suites)');
      return _items;
    }
  }

  Future<TestSuiteModel> addTestSuite(TestSuiteModel suite) async {
    final existingIdx = _items.indexWhere((s) => s.id == suite.id || s.name.toLowerCase() == suite.name.toLowerCase());
    if (existingIdx != -1) {
      _items[existingIdx] = suite;
    } else {
      _items.insert(0, suite);
    }
    _saveToLocalStorage();
    await _upsertToSupabase(suite, label: 'addTestSuite');
    return suite;
  }

  Future<void> updateTestSuite(TestSuiteModel suite) async {
    final index = _items.indexWhere((s) => s.id == suite.id || s.name.toLowerCase() == suite.name.toLowerCase());
    if (index != -1) {
      _items[index] = suite;
      _saveToLocalStorage();
    }
    await _upsertToSupabase(suite, label: 'updateTestSuite');
  }

  Future<void> deleteTestSuite(String id) async {
    _items.removeWhere((s) => s.id == id);
    _saveToLocalStorage();
    AppLogger.warn('TestSuiteRepository', 'Deleting suite ID: $id from Supabase');
    try {
      await _client.from('test_suites').delete().eq('id', id);
      AppLogger.success('TestSuiteRepository', 'Deleted suite ID: $id from Supabase');
    } catch (e) {
      AppLogger.error('TestSuiteRepository', 'Failed to delete suite ID: $id from Supabase', e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _upsertToSupabase(TestSuiteModel suite, {required String label}) async {
    final payload = suite.toSupabaseJson(fallbackUserId: _client.auth.currentUser?.id);
    if (payload.isEmpty) {
      AppLogger.warn('TestSuiteRepository', 'Skipping Supabase sync for "${suite.name}" ($label) — non-UUID id: ${suite.id}');
      return;
    }
    AppLogger.info('TestSuiteRepository', 'Syncing suite to Supabase [$label]: ${suite.name} (id: ${suite.id})');
    try {
      await _client.from('test_suites').upsert(payload);
      AppLogger.success('TestSuiteRepository', '✅ Supabase upsert OK [$label]: ${suite.name}');
    } catch (e) {
      AppLogger.error('TestSuiteRepository', '❌ Supabase upsert FAILED [$label]: ${suite.name}', e);
    }
  }
}
