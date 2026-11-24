import 'package:flutter/material.dart';
import '../models/test_suite_model.dart';
import '../repositories/test_suite_repository.dart';
import '../utils/app_logger.dart';

class TestSuiteProvider extends ChangeNotifier {
  final TestSuiteRepository _repository;

  TestSuiteProvider({TestSuiteRepository? repository})
      : _repository = repository ?? TestSuiteRepository() {
    _suites = _repository.cachedItems;
    AppLogger.info('TestSuiteProvider', 'Initialized TestSuiteProvider with ${_suites.length} cached suites');
    loadTestSuites();
  }

  List<TestSuiteModel> _suites = [];
  bool _isLoading = false;

  List<TestSuiteModel> get suites => _suites;
  List<TestSuiteModel> get testSuites => _suites;
  bool get isLoading => _isLoading;

  Future<void> loadTestSuites() async {
    AppLogger.info('TestSuiteProvider', 'Loading test suites...');
    _isLoading = true;
    notifyListeners();

    _suites = await _repository.getTestSuites();
    _isLoading = false;
    AppLogger.success('TestSuiteProvider', 'Loaded ${_suites.length} test suites into provider');
    notifyListeners();
  }

  Future<void> addTestSuite(TestSuiteModel suite) async {
    AppLogger.info('TestSuiteProvider', 'Adding new test suite: ${suite.name} (Build: ${suite.buildName}, Version: ${suite.version})');
    final newSuite = await _repository.addTestSuite(suite);
    final idx = _suites.indexWhere((s) => s.id == newSuite.id || s.name.toLowerCase() == newSuite.name.toLowerCase());
    if (idx != -1) {
      _suites[idx] = newSuite;
    } else {
      _suites.insert(0, newSuite);
    }
    notifyListeners();
    AppLogger.success('TestSuiteProvider', 'Test suite ${suite.name} added/updated');
  }

  Future<void> updateTestSuite(TestSuiteModel suite) async {
    AppLogger.info('TestSuiteProvider', 'Updating test suite: ${suite.name} (${suite.totalCases} cases)');
    final index = _suites.indexWhere((s) => s.id == suite.id);
    if (index != -1) {
      _suites[index] = suite;
      notifyListeners();
    }
    await _repository.updateTestSuite(suite);
    AppLogger.success('TestSuiteProvider', 'Test suite ${suite.name} updated');
  }

  Future<void> deleteTestSuite(String id) async {
    AppLogger.warn('TestSuiteProvider', 'Deleting test suite ID: $id');
    _suites.removeWhere((s) => s.id == id);
    notifyListeners();
    await _repository.deleteTestSuite(id);
    AppLogger.success('TestSuiteProvider', 'Test suite $id deleted');
  }
}
