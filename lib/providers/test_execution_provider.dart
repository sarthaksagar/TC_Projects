import 'package:flutter/material.dart';
import '../models/test_execution_model.dart';
import '../repositories/test_execution_repository.dart';
import '../utils/app_logger.dart';

class TestExecutionProvider extends ChangeNotifier {
  final TestExecutionRepository _repository;

  TestExecutionProvider({TestExecutionRepository? repository})
      : _repository = repository ?? TestExecutionRepository() {
    loadExecutions();
  }

  List<TestExecutionModel> _executions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TestExecutionModel> get executions => _executions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadExecutions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _executions = await _repository.getExecutions();
      AppLogger.success('TestExecutionProvider', 'Loaded ${_executions.length} executions');
    } catch (e) {
      _errorMessage = 'Failed to load test executions.';
      AppLogger.error('TestExecutionProvider', 'Failed to load executions', e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExecution(TestExecutionModel execution) async {
    final newExecution = await _repository.addExecution(execution);
    _executions.insert(0, newExecution);
    notifyListeners();
  }
}
