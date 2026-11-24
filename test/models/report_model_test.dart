import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/report_model.dart';

void main() {
  group('ReportSummaryModel', () {
    test('holds all required fields', () {
      const model = ReportSummaryModel(
        totalTestCases: 100,
        passedTestCases: 75,
        failedTestCases: 15,
        blockedTestCases: 5,
        untestedTestCases: 5,
        overallPassPercentage: 75.0,
        totalBugs: 20,
        openBugs: 8,
        resolvedBugs: 12,
        activeTestPlans: 3,
      );

      expect(model.totalTestCases, 100);
      expect(model.passedTestCases, 75);
      expect(model.failedTestCases, 15);
      expect(model.blockedTestCases, 5);
      expect(model.untestedTestCases, 5);
      expect(model.overallPassPercentage, 75.0);
      expect(model.totalBugs, 20);
      expect(model.openBugs, 8);
      expect(model.resolvedBugs, 12);
      expect(model.activeTestPlans, 3);
    });

    test('zero-value model is valid', () {
      const model = ReportSummaryModel(
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

      expect(model.totalTestCases, 0);
      expect(model.overallPassPercentage, 0.0);
    });

    test('pass percentage correctly reflects partial pass', () {
      const model = ReportSummaryModel(
        totalTestCases: 200,
        passedTestCases: 150,
        failedTestCases: 30,
        blockedTestCases: 10,
        untestedTestCases: 10,
        overallPassPercentage: 75.0,
        totalBugs: 0,
        openBugs: 0,
        resolvedBugs: 0,
        activeTestPlans: 1,
      );

      expect(model.overallPassPercentage, 75.0);
    });
  });

  group('DailyTrendModel', () {
    test('holds all required fields', () {
      const trend = DailyTrendModel(
        dateLabel: 'Mon',
        passed: 20,
        failed: 5,
        blocked: 2,
      );

      expect(trend.dateLabel, 'Mon');
      expect(trend.passed, 20);
      expect(trend.failed, 5);
      expect(trend.blocked, 2);
    });

    test('zero values are valid', () {
      const trend = DailyTrendModel(
        dateLabel: 'Fri',
        passed: 0,
        failed: 0,
        blocked: 0,
      );

      expect(trend.passed, 0);
      expect(trend.blocked, 0);
    });

    test('all weekday labels are valid strings', () {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final day in days) {
        final trend = DailyTrendModel(
          dateLabel: day,
          passed: 0,
          failed: 0,
          blocked: 0,
        );
        expect(trend.dateLabel.isNotEmpty, true);
        expect(days.contains(trend.dateLabel), true);
      }
    });
  });
}
