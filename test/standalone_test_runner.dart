import 'models/test_case_model_test.dart' as test_case_model_test;
import 'models/bug_model_test.dart' as bug_model_test;
import 'models/test_suite_model_test.dart' as test_suite_model_test;
import 'models/user_model_test.dart' as user_model_test;
import 'models/test_plan_model_test.dart' as test_plan_model_test;
import 'models/report_model_test.dart' as report_model_test;

int _totalTests = 0;
int _passedTests = 0;
int _failedTests = 0;

void expect(dynamic actual, dynamic expected, {String? reason}) {
  if (actual != expected) {
    throw Exception('Expected <$expected> but got <$actual>${reason != null ? " ($reason)" : ""}');
  }
}

Future<void> runTest(String name, dynamic Function() body) async {
  _totalTests++;
  try {
    final res = body();
    if (res is Future) await res;
    _passedTests++;
    print('  [PASS] $name');
  } catch (e) {
    _failedTests++;
    print('  [FAIL] $name: $e');
  }
}

Future<void> main() async {
  print('====================================================');
  print('    VG_QATC COMPREHENSIVE AUTOMATED TEST SUITE      ');
  print('====================================================\n');

  print('>> Running Unit Tests for Models and Business Logic...');

  // 1. TestCaseModel Tests
  print('\n-- Suite: TestCaseModel --');
  await runTest('parses a fully populated JSON map correctly', () {
    test_case_model_test.main();
  });

  // 2. BugModel Tests
  print('\n-- Suite: BugModel --');
  await runTest('parses and serializes BugModel correctly', () {
    bug_model_test.main();
  });

  // 3. TestSuiteModel Tests
  print('\n-- Suite: TestSuiteModel --');
  await runTest('handles passRate and Supabase payloads', () {
    test_suite_model_test.main();
  });

  // 4. UserModel Tests
  print('\n-- Suite: UserModel --');
  await runTest('validates UserModel roles and immutability', () {
    user_model_test.main();
  });

  // 5. TestPlanModel Tests
  print('\n-- Suite: TestPlanModel --');
  await runTest('validates TestPlan dates, defaults, and aliases', () {
    test_plan_model_test.main();
  });

  // 6. ReportModel Tests
  print('\n-- Suite: ReportModel --');
  await runTest('computes ReportSummary and DailyTrend metrics', () {
    report_model_test.main();
  });

  print('\n====================================================');
  print('                   TEST SUMMARY                     ');
  print('====================================================');
  print('Total Test Suites Executed: $_totalTests');
  print('Total Passed              : $_passedTests');
  print('Total Failed              : $_failedTests');
  print('Status                    : ${_failedTests == 0 ? "ALL PASSING (100% SUCCESS)" : "FAILURES DETECTED"}');
  print('====================================================\n');

  if (_failedTests > 0) {
    throw Exception('Some tests failed!');
  }
}

