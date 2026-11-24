import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';

class ModuleCoverageItem {
  final String name;
  final double progress;
  final String percentageText;

  const ModuleCoverageItem({
    required this.name,
    required this.progress,
    required this.percentageText,
  });
}

class DashboardProvider extends ChangeNotifier {
  final ReportRepository _reportRepository;
  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _totalCases = 0;
  int _passedCases = 0;
  int _failedCases = 0;
  int _blockedCases = 0;
  int _openBugs = 0;
  int _activePlans = 0;

  int get totalCases => _totalCases;
  int get passedCases => _passedCases;
  int get failedCases => _failedCases;
  int get blockedCases => _blockedCases;
  int get openBugs => _openBugs;
  int get activePlans => _activePlans;

  double get passPercentage => _totalCases == 0 ? 0.0 : (_passedCases / _totalCases) * 100;
  double get failPercentage => _totalCases == 0 ? 0.0 : (_failedCases / _totalCases) * 100;
  double get blockedPercentage => _totalCases == 0 ? 0.0 : (_blockedCases / _totalCases) * 100;

  List<ActivityModel> _activities = [];
  List<DailyTrendModel> _dailyTrends = [];

  List<ActivityModel> get activities => _activities;
  List<DailyTrendModel> get dailyTrends => _dailyTrends;

  /// Module coverage items are derived from live suite data fetched by TestSuiteProvider.
  /// Call [updateModuleCoverage] from the UI after suites load.
  List<ModuleCoverageItem> _moduleCoverage = [];
  List<ModuleCoverageItem> get moduleCoverage => _moduleCoverage;

  void updateModuleCoverage(List<ModuleCoverageItem> items) {
    _moduleCoverage = items;
    notifyListeners();
  }

  DashboardProvider({ReportRepository? repository})
      : _reportRepository = repository ?? ReportRepository() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    if (_totalCases == 0) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final summary = await _reportRepository
          .getReportSummary()
          .timeout(const Duration(seconds: 10));
      _totalCases = summary.totalTestCases;
      _passedCases = summary.passedTestCases;
      _failedCases = summary.failedTestCases;
      _blockedCases = summary.blockedTestCases;
      _openBugs = summary.openBugs;
      _activePlans = summary.activeTestPlans;
      _dailyTrends = await _reportRepository
          .getDailyTrends()
          .timeout(const Duration(seconds: 10));
      _activities = [];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
