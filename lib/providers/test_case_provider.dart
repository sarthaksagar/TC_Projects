import 'package:flutter/material.dart';
import '../models/test_case_model.dart';
import '../repositories/test_case_repository.dart';
import '../utils/app_logger.dart';

class TestCaseProvider extends ChangeNotifier {
  final TestCaseRepository _repository;

  TestCaseProvider({TestCaseRepository? repository})
      : _repository = repository ?? TestCaseRepository() {
    _testCases = _repository.cachedItems;
    AppLogger.info('TestCaseProvider', 'Initialized TestCaseProvider with ${_testCases.length} cached cases');
    loadTestCases();
  }

  List<TestCaseModel> _testCases = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  List<TestCaseModel> get testCases {
    return _testCases.where((tc) {
      final matchesSearch = tc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.suiteName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.module.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.feature.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_selectedStatusFilter == 'All') return matchesSearch;
      return matchesSearch && tc.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();
  }

  List<TestCaseModel> get allRawCases => _testCases;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;

  Future<void> loadTestCases() async {
    AppLogger.info('TestCaseProvider', 'Loading test cases...');
    if (_testCases.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _testCases = await _repository.getTestCases();
    _isLoading = false;
    AppLogger.success('TestCaseProvider', 'Loaded ${_testCases.length} test cases into provider');
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    AppLogger.log('TestCaseProvider', 'Filter searchQuery changed: "$query"');
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    AppLogger.log('TestCaseProvider', 'Filter status changed: "$status"');
    notifyListeners();
  }

  Future<void> addTestCase(TestCaseModel testCase) async {
    AppLogger.info('TestCaseProvider', 'Adding new test case: ${testCase.code} - ${testCase.title}');
    _testCases.insert(0, testCase);
    notifyListeners();
    await _repository.addTestCase(testCase);
    AppLogger.success('TestCaseProvider', 'Test case ${testCase.code} added successfully');
  }

  Future<void> addTestCasesBatch(List<TestCaseModel> newCases) async {
    if (newCases.isEmpty) return;
    AppLogger.info('TestCaseProvider', 'Batch adding ${newCases.length} imported test cases');
    _testCases.insertAll(0, newCases);
    notifyListeners();
    await _repository.addTestCasesBatch(newCases);
    AppLogger.success('TestCaseProvider', 'Batch ${newCases.length} test cases saved successfully');
  }

  Future<void> updateTestCase(TestCaseModel testCase) async {
    AppLogger.info('TestCaseProvider', 'Updating test case: ${testCase.code} (${testCase.id})');
    final index = _testCases.indexWhere((tc) => tc.id == testCase.id);
    if (index != -1) {
      _testCases[index] = testCase;
      notifyListeners();
    }
    await _repository.updateTestCase(testCase);
    AppLogger.success('TestCaseProvider', 'Test case ${testCase.code} updated');
  }

  Future<void> updateTestCasesBatch(List<TestCaseModel> updatedCases) async {
    if (updatedCases.isEmpty) return;
    AppLogger.info('TestCaseProvider', 'Batch updating ${updatedCases.length} test cases');
    for (final updated in updatedCases) {
      final idx = _testCases.indexWhere((tc) => tc.id == updated.id);
      if (idx != -1) {
        _testCases[idx] = updated;
      }
    }
    notifyListeners();
    await _repository.updateTestCasesBatch(updatedCases);
    AppLogger.success('TestCaseProvider', 'Batch updated ${updatedCases.length} test cases');
  }

  Future<void> deleteTestCase(String id) async {
    AppLogger.warn('TestCaseProvider', 'Deleting test case ID: $id');
    _testCases.removeWhere((tc) => tc.id == id);
    notifyListeners();
    await _repository.deleteTestCase(id);
    AppLogger.success('TestCaseProvider', 'Test case $id deleted');
  }

  Future<void> clearAllTestCases() async {
    AppLogger.warn('TestCaseProvider', 'Clearing all ${_testCases.length} test cases');
    _testCases.clear();
    notifyListeners();
    await _repository.clearAll();
    AppLogger.success('TestCaseProvider', 'All test cases cleared');
  }
}
