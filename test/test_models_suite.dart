import 'package:vg_qatc/models/test_case_model.dart';
import 'package:vg_qatc/models/test_suite_model.dart';
import 'package:vg_qatc/models/bug_model.dart';
import 'package:vg_qatc/models/user_model.dart';
import 'package:vg_qatc/models/test_plan_model.dart';
import 'package:vg_qatc/models/report_model.dart';

int _passed = 0;
int _failed = 0;

void assertEq(dynamic actual, dynamic expected, String scenario) {
  if (actual != expected) {
    _failed++;
    print('  ❌ [FAIL] $scenario: Expected <$expected> but got <$actual>');
  } else {
    _passed++;
    print('  ✅ [PASS] $scenario');
  }
}

void assertTrue(bool condition, String scenario) {
  assertEq(condition, true, scenario);
}

void assertFalse(bool condition, String scenario) {
  assertEq(condition, false, scenario);
}

void main() {
  print('================================================================');
  print('     VG_QATC COMPLETE DATA MODEL & LOGIC TEST SUITE            ');
  print('================================================================\n');

  // ====================================================================
  // 1. TEST CASE MODEL TESTS
  // ====================================================================
  print('--- [Suite 1/6] TestCaseModel Validation ---');
  final tcJson = {
    'id': '123e4567-e89b-12d3-a456-426614174000',
    'code': 'TC-001',
    'title': 'Verify user login with valid credentials',
    'description': 'Validates successful JWT token generation',
    'module': 'Authentication',
    'feature': 'Login Flow',
    'preconditions': 'Account must exist in Supabase',
    'steps': ['Navigate to /login', 'Enter email', 'Enter password', 'Submit form'],
    'test_data': 'email=lead@company.com',
    'expected_result': 'User redirected to /dashboard',
    'actual_result': 'Dashboard loaded',
    'status': 'passed',
    'priority': 'critical',
    'type': 'Security',
    'assigned_to': 'Lead Tester',
    'created_by': '123e4567-e89b-12d3-a456-426614174001',
    'updated_at': '2024-03-01T10:00:00.000Z',
    'execution_date': '2024-03-01T10:00:00.000Z',
    'remarks': 'Tested on Chrome',
    'suite_id': '123e4567-e89b-12d3-a456-426614174002',
    'suite_name': 'Auth Suite',
  };
  final tc = TestCaseModel.fromJson(tcJson);
  assertEq(tc.id, '123e4567-e89b-12d3-a456-426614174000', 'Parses UUID id');
  assertEq(tc.code, 'TC-001', 'Parses test case code');
  assertEq(tc.status, TestCaseStatus.passed, 'Maps "passed" status enum');
  assertEq(tc.priority, TestCasePriority.critical, 'Maps "critical" priority enum');
  assertEq(tc.steps.length, 4, 'Parses 4 execution steps');
  assertTrue(tc.toSupabaseJson().isNotEmpty, 'Valid UUID produces non-empty Supabase JSON');

  final nonUuidTc = TestCaseModel(
    id: 'temp-id',
    code: 'TC-999',
    title: 'Temp case',
    description: '',
    steps: [],
    expectedResult: 'Pass',
    status: TestCaseStatus.untested,
    priority: TestCasePriority.low,
    assignedTo: 'Unassigned',
    createdBy: 'System',
    updatedAt: DateTime.now(),
  );
  assertTrue(nonUuidTc.toSupabaseJson().isEmpty, 'Non-UUID id safely returns empty map for Supabase upsert');

  // Corrupt code auto-repair
  final corruptTcJson = {
    'id': 'abc12345',
    'code': 'This is accidentally a long descriptive sentence that got saved into code column',
    'title': '',
    'expected_result': 'Pass',
    'status': 'untested',
    'priority': 'medium',
    'assigned_to': 'Tester',
    'created_by': 'System',
    'updated_at': '2024-01-01T00:00:00.000Z',
  };
  final repairedTc = TestCaseModel.fromJson(corruptTcJson);
  assertTrue(repairedTc.code.startsWith('TC-'), 'Auto-repairs corrupt sentence code to valid TC-* format');

  // Column shift cleanup
  final shiftedTcJson = {
    'id': 'tc-date-shift',
    'title': 'Test with date in assignedTo',
    'expected_result': 'Pass',
    'status': 'untested',
    'priority': 'medium',
    'assigned_to': '2024-05-12',
    'created_by': 'System',
    'updated_at': '2024-01-01T00:00:00.000Z',
  };
  final shiftedTc = TestCaseModel.fromJson(shiftedTcJson);
  assertEq(shiftedTc.assignedTo, 'Unassigned', 'Detects and cleans column-shifted dates in assigned_to field');

  // ====================================================================
  // 2. TEST SUITE MODEL TESTS
  // ====================================================================
  print('\n--- [Suite 2/6] TestSuiteModel Validation ---');
  final suite = TestSuiteModel(
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'Regression Suite v2',
    description: 'Comprehensive E2E suite',
    totalCases: 50,
    passedCases: 45,
    failedCases: 3,
    blockedCases: 2,
    createdBy: 'QA Lead',
    createdAt: DateTime.now(),
  );
  assertEq(suite.passRate, 90.0, 'passRate correctly calculates 90% (45/50)');

  final emptySuite = TestSuiteModel.empty();
  assertEq(emptySuite.passRate, 0.0, 'Empty suite passRate avoids division by zero and returns 0.0%');
  assertTrue(suite.toSupabaseJson().isNotEmpty, 'Valid UUID suite generates Supabase payload');

  // ====================================================================
  // 3. BUG MODEL TESTS
  // ====================================================================
  print('\n--- [Suite 3/6] BugModel Validation ---');
  final bugJson = {
    'id': 'b-01',
    'ticket_id': 'BUG-101',
    'title': 'Session timeout unhandled',
    'description': 'Does not redirect on 401',
    'test_case_code': 'TC-001',
    'severity': 'blocker',
    'status': 'in_progress',
    'assigned_to': 'Security Team',
    'reported_by': 'QA Lead',
    'created_at': '2024-03-02T12:00:00.000Z',
  };
  final bug = BugModel.fromJson(bugJson);
  assertEq(bug.ticketId, 'BUG-101', 'Parses ticket_id');
  assertEq(bug.severity, BugSeverity.blocker, 'Maps "blocker" severity');
  assertEq(bug.status, BugStatus.inProgress, 'Maps "in_progress" status');

  final updatedBug = bug.copyWith(status: BugStatus.resolved);
  assertEq(updatedBug.status, BugStatus.resolved, 'copyWith updates status to resolved');
  assertEq(bug.status, BugStatus.inProgress, 'Original BugModel remains immutable');

  final bugMap = updatedBug.toJson();
  assertEq(bugMap['severity'], 'blocker', 'toJson writes severity as string');
  assertEq(bugMap['status'], 'resolved', 'toJson writes status as string');

  // ====================================================================
  // 4. USER MODEL TESTS
  // ====================================================================
  print('\n--- [Suite 4/6] UserModel Validation ---');
  final userJson = {
    'id': 'usr-001',
    'full_name': 'Jane Architect',
    'email': 'jane.lead@company.com',
    'role': 'QA Lead',
    'avatar_url': 'https://avatar.test/1',
    'is_active': true,
    'created_at': '2024-01-01T00:00:00.000Z',
  };
  final user = UserModel.fromJson(userJson);
  assertEq(user.name, 'Jane Architect', 'Parses full_name alias');
  assertEq(user.role, 'QA Lead', 'Parses role');
  assertTrue(user.isActive, 'Parses active status');

  final deactivated = user.copyWith(isActive: false);
  assertFalse(deactivated.isActive, 'Deactivates user via copyWith');
  assertTrue(user.isActive, 'Original user remains unmodified');

  // ====================================================================
  // 5. TEST PLAN MODEL TESTS
  // ====================================================================
  print('\n--- [Suite 5/6] TestPlanModel Validation ---');
  final planJson = {
    'id': 'plan-100',
    'name': 'Q2 Release Test Plan',
    'version': 'v2.0',
    'target_release': 'Release 2.0-RC1',
    'status': 'Active',
    'start_date': '2024-04-01T00:00:00.000Z',
    'suite_count': 4,
    'total_cases_count': 120,
    'owner': 'QA Manager',
  };
  final plan = TestPlanModel.fromJson(planJson);
  assertEq(plan.title, 'Q2 Release Test Plan', 'Parses name alias as title');
  assertEq(plan.totalCasesCount, 120, 'Parses total cases');
  assertTrue(plan.endDate.isAfter(plan.startDate), 'Calculates default end date 14 days after start date');

  // ====================================================================
  // 6. REPORT MODEL TESTS
  // ====================================================================
  print('\n--- [Suite 6/6] ReportModel Validation ---');
  const summary = ReportSummaryModel(
    totalTestCases: 200,
    passedTestCases: 160,
    failedTestCases: 25,
    blockedTestCases: 10,
    untestedTestCases: 5,
    overallPassPercentage: 80.0,
    totalBugs: 15,
    openBugs: 4,
    resolvedBugs: 11,
    activeTestPlans: 2,
  );
  assertEq(summary.overallPassPercentage, 80.0, 'Pass percentage is 80%');
  assertEq(summary.openBugs, 4, 'Open bugs is 4');
  assertEq(summary.resolvedBugs, 11, 'Resolved bugs is 11');

  const trend = DailyTrendModel(dateLabel: 'Mon', passed: 40, failed: 2, blocked: 1);
  assertEq(trend.dateLabel, 'Mon', 'Daily trend day label is Mon');
  assertEq(trend.passed, 40, 'Daily trend passed count is 40');

  print('\n================================================================');
  print('                       FINAL TEST RESULTS                       ');
  print('================================================================');
  print('  Total Assertions Executed : ${_passed + _failed}');
  print('  Assertions Passed         : $_passed');
  print('  Assertions Failed         : $_failed');
  print('  Success Rate              : ${((_passed / (_passed + _failed)) * 100).toStringAsFixed(1)}%');
  print('================================================================\n');

  if (_failed > 0) {
    throw Exception('Test suite had $_failed failure(s).');
  } else {
    print('🎉 ALL SUITES PASSED WITH 100% SUCCESS RATE.');
  }
}
