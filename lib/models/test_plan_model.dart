class TestPlanModel {
  final String id;
  final String title;
  final String version;
  final String targetRelease;
  final String status; // Active, Draft, Completed, Archived
  final DateTime startDate;
  final DateTime endDate;
  final int suiteCount;
  final int totalCasesCount;
  final String owner;

  const TestPlanModel({
    required this.id,
    required this.title,
    required this.version,
    required this.targetRelease,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.suiteCount,
    required this.totalCasesCount,
    required this.owner,
  });

  factory TestPlanModel.fromJson(Map<String, dynamic> json) {
    return TestPlanModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      version: json['version'] ?? 'v1.0.0',
      targetRelease: json['target_release'] ?? json['targetRelease'] ?? 'Release 1.0',
      status: json['status'] ?? 'Active',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : (json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now()),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : (json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now().add(const Duration(days: 14))),
      suiteCount: json['suite_count'] ?? json['suiteCount'] ?? 1,
      totalCasesCount: json['total_cases_count'] ?? json['totalCasesCount'] ?? 0,
      owner: json['owner'] ?? json['created_by'] ?? 'QA Member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'description': title,
      'version': version,
      'target_release': targetRelease,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'suite_count': suiteCount,
      'total_cases_count': totalCasesCount,
      'owner': owner,
    };
  }

  TestPlanModel copyWith({
    String? id,
    String? title,
    String? version,
    String? targetRelease,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? suiteCount,
    int? totalCasesCount,
    String? owner,
  }) {
    return TestPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      version: version ?? this.version,
      targetRelease: targetRelease ?? this.targetRelease,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      suiteCount: suiteCount ?? this.suiteCount,
      totalCasesCount: totalCasesCount ?? this.totalCasesCount,
      owner: owner ?? this.owner,
    );
  }
}
