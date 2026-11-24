class ReportSummaryModel {
  final int totalTestCases;
  final int passedTestCases;
  final int failedTestCases;
  final int blockedTestCases;
  final int untestedTestCases;
  final double overallPassPercentage;
  final int totalBugs;
  final int openBugs;
  final int resolvedBugs;
  final int activeTestPlans;

  const ReportSummaryModel({
    required this.totalTestCases,
    required this.passedTestCases,
    required this.failedTestCases,
    required this.blockedTestCases,
    required this.untestedTestCases,
    required this.overallPassPercentage,
    required this.totalBugs,
    required this.openBugs,
    required this.resolvedBugs,
    required this.activeTestPlans,
  });
}

class DailyTrendModel {
  final String dateLabel; // e.g. Mon, Tue
  final int passed;
  final int failed;
  final int blocked;

  const DailyTrendModel({
    required this.dateLabel,
    required this.passed,
    required this.failed,
    required this.blocked,
  });
}
