import 'package:flutter/material.dart';
import '../models/test_plan_model.dart';
import '../repositories/test_plan_repository.dart';
import '../utils/app_logger.dart';

class TestPlanProvider extends ChangeNotifier {
  final TestPlanRepository _repository;

  TestPlanProvider({TestPlanRepository? repository})
      : _repository = repository ?? TestPlanRepository() {
    loadTestPlans();
  }

  List<TestPlanModel> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TestPlanModel> get plans => _plans;
  List<TestPlanModel> get testPlans => _plans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTestPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _repository.getTestPlans();
      AppLogger.success('TestPlanProvider', 'Loaded ${_plans.length} test plans');
    } catch (e) {
      _errorMessage = 'Failed to load test plans.';
      AppLogger.error('TestPlanProvider', 'Failed to load test plans', e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTestPlan(TestPlanModel plan) async {
    final newPlan = await _repository.addTestPlan(plan);
    _plans.insert(0, newPlan);
    notifyListeners();
  }

  Future<void> updateTestPlan(TestPlanModel plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
      notifyListeners();
    }
    await _repository.updateTestPlan(plan);
  }

  Future<void> deleteTestPlan(String id) async {
    AppLogger.warn('TestPlanProvider', 'Deleting test plan ID: $id');
    _plans.removeWhere((p) => p.id == id);
    notifyListeners();
    await _repository.deleteTestPlan(id);
    AppLogger.success('TestPlanProvider', 'Test plan $id deleted');
  }
}
