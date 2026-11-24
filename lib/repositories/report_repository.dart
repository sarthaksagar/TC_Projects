import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import '../models/test_case_model.dart';
import '../models/bug_model.dart';

class ReportRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<ReportSummaryModel> getReportSummary() async {
    try {
      final tcRes = await _client.from('test_cases').select();
      final tcList = (tcRes as List<dynamic>)
          .map((e) => TestCaseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final bugRes = await _client.from('bugs').select();
      final bugList = (bugRes as List<dynamic>)
          .map((e) => BugModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final planRes = await _client.from('test_plans').select('id');
      final planCount = (planRes as List<dynamic>).length;

      final totalTC = tcList.length;
      final passedTC = tcList.where((tc) => tc.status == TestCaseStatus.passed).length;
      final failedTC = tcList.where((tc) => tc.status == TestCaseStatus.failed).length;
      final blockedTC = tcList.where((tc) => tc.status == TestCaseStatus.blocked).length;
      final untestedTC = tcList
          .where((tc) =>
              tc.status == TestCaseStatus.untested ||
              tc.status == TestCaseStatus.inProgress)
          .length;
      final passPct = totalTC == 0 ? 0.0 : (passedTC / totalTC) * 100;

      final totalB = bugList.length;
      final openB = bugList
          .where((b) =>
              b.status == BugStatus.open || b.status == BugStatus.inProgress)
          .length;
      final resolvedB = bugList
          .where((b) =>
              b.status == BugStatus.resolved || b.status == BugStatus.closed)
          .length;

      return ReportSummaryModel(
        totalTestCases: totalTC,
        passedTestCases: passedTC,
        failedTestCases: failedTC,
        blockedTestCases: blockedTC,
        untestedTestCases: untestedTC,
        overallPassPercentage: passPct,
        totalBugs: totalB,
        openBugs: openB,
        resolvedBugs: resolvedB,
        activeTestPlans: planCount,
      );
    } catch (_) {
      return const ReportSummaryModel(
        totalTestCases: 0,
        passedTestCases: 0,
        failedTestCases: 0,
        blockedTestCases: 0,
        untestedTestCases: 0,
        overallPassPercentage: 0.0,
        totalBugs: 0,
        openBugs: 0,
        resolvedBugs: 0,
        activeTestPlans: 0,
      );
    }
  }

  Future<List<DailyTrendModel>> getDailyTrends() async {
    try {
      // Compute daily trends from last 7 days using real test case data
      final res = await _client
          .from('test_cases')
          .select('status, updated_at')
          .gte('updated_at',
              DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      final records = (res as List<dynamic>);
      final Map<String, Map<String, int>> dayMap = {};

      for (final r in records) {
        final dateStr = r['updated_at']?.toString() ?? '';
        if (dateStr.isEmpty) continue;
        final dt = DateTime.tryParse(dateStr);
        if (dt == null) continue;
        // Key by weekday label
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = days[dt.weekday - 1];
        dayMap.putIfAbsent(label, () => {'passed': 0, 'failed': 0, 'blocked': 0});
        final status = r['status']?.toString().toLowerCase() ?? '';
        if (status == 'passed') dayMap[label]!['passed'] = dayMap[label]!['passed']! + 1;
        if (status == 'failed') dayMap[label]!['failed'] = dayMap[label]!['failed']! + 1;
        if (status == 'blocked') dayMap[label]!['blocked'] = dayMap[label]!['blocked']! + 1;
      }

      if (dayMap.isEmpty) return [];

      return dayMap.entries
          .map((e) => DailyTrendModel(
                dateLabel: e.key,
                passed: e.value['passed'] ?? 0,
                failed: e.value['failed'] ?? 0,
                blocked: e.value['blocked'] ?? 0,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
