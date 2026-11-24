import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider({ReportRepository? repository})
      : _repository = repository ?? ReportRepository() {
    loadReports();
  }

  ReportSummaryModel? _summary;
  List<DailyTrendModel> _dailyTrends = [];
  bool _isLoading = false;

  ReportSummaryModel? get summary => _summary;
  List<DailyTrendModel> get dailyTrends => _dailyTrends;
  bool get isLoading => _isLoading;

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    _summary = await _repository.getReportSummary();
    _dailyTrends = await _repository.getDailyTrends();
    _isLoading = false;
    notifyListeners();
  }
}
