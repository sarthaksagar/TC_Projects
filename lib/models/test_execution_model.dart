import 'test_case_model.dart';

class TestExecutionModel {
  final String id;
  final String executionName; // e.g. Sprint 24 Regression Run
  final String testPlanName;
  final String environment; // Staging, Production, Dev, QA
  final TestCaseStatus status;
  final DateTime executedAt;
  final String executedBy;
  final int totalCount;
  final int passedCount;
  final int failedCount;
  final int blockedCount;
  final Duration duration;

  const TestExecutionModel({
    required this.id,
    required this.executionName,
    required this.testPlanName,
    required this.environment,
    required this.status,
    required this.executedAt,
    required this.executedBy,
    required this.totalCount,
    required this.passedCount,
    required this.failedCount,
    required this.blockedCount,
    required this.duration,
  });

  factory TestExecutionModel.fromJson(Map<String, dynamic> json) {
    TestCaseStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'passed': return TestCaseStatus.passed;
        case 'failed': return TestCaseStatus.failed;
        case 'blocked': return TestCaseStatus.blocked;
        case 'running':
        case 'inprogress': return TestCaseStatus.inProgress;
        default: return TestCaseStatus.untested;
      }
    }

    return TestExecutionModel(
      id: json['id']?.toString() ?? '',
      executionName: json['execution_name'] ?? json['executionName'] ?? 'Test Run',
      testPlanName: json['test_plan_name'] ?? json['testPlanName'] ?? 'Main Plan',
      environment: json['environment'] ?? 'QA Environment',
      status: parseStatus(json['status']?.toString()),
      executedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : (json['executedAt'] != null ? DateTime.parse(json['executedAt']) : DateTime.now()),
      executedBy: json['executed_by'] ?? json['executedBy'] ?? 'Tester',
      totalCount: json['total_count'] ?? json['totalCount'] ?? 0,
      passedCount: json['passed_count'] ?? json['passedCount'] ?? 0,
      failedCount: json['failed_count'] ?? json['failedCount'] ?? 0,
      blockedCount: json['blocked_count'] ?? json['blockedCount'] ?? 0,
      duration: Duration(minutes: json['duration_minutes'] ?? 25),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'execution_name': executionName,
      'test_plan_name': testPlanName,
      'environment': environment,
      'status': status.name,
      'started_at': executedAt.toIso8601String(),
      'executed_by': executedBy,
      'total_count': totalCount,
      'passed_count': passedCount,
      'failed_count': failedCount,
      'blocked_count': blockedCount,
      'duration_minutes': duration.inMinutes,
    };
  }

  TestExecutionModel copyWith({
    String? id,
    String? executionName,
    String? testPlanName,
    String? environment,
    TestCaseStatus? status,
    DateTime? executedAt,
    String? executedBy,
    int? totalCount,
    int? passedCount,
    int? failedCount,
    int? blockedCount,
    Duration? duration,
  }) {
    return TestExecutionModel(
      id: id ?? this.id,
      executionName: executionName ?? this.executionName,
      testPlanName: testPlanName ?? this.testPlanName,
      environment: environment ?? this.environment,
      status: status ?? this.status,
      executedAt: executedAt ?? this.executedAt,
      executedBy: executedBy ?? this.executedBy,
      totalCount: totalCount ?? this.totalCount,
      passedCount: passedCount ?? this.passedCount,
      failedCount: failedCount ?? this.failedCount,
      blockedCount: blockedCount ?? this.blockedCount,
      duration: duration ?? this.duration,
    );
  }
}
