class TestSuiteModel {
  final String id;
  final String name;
  final String description;
  final String buildName;
  final String version;
  final int totalCases;
  final int passedCases;
  final int failedCases;
  final int blockedCases;
  final String createdBy;
  final DateTime createdAt;

  const TestSuiteModel({
    required this.id,
    required this.name,
    required this.description,
    this.buildName = 'Build v1.0.4 - Release Candidate',
    this.version = 'v1.0.0',
    required this.totalCases,
    required this.passedCases,
    required this.failedCases,
    required this.blockedCases,
    required this.createdBy,
    required this.createdAt,
  });

  factory TestSuiteModel.empty() => TestSuiteModel(
        id: '',
        name: 'Test Suite',
        description: '',
        buildName: 'Build QA',
        version: 'v1.0.0',
        totalCases: 0,
        passedCases: 0,
        failedCases: 0,
        blockedCases: 0,
        createdBy: 'QA Member',
        createdAt: DateTime.now(),
      );

  double get passRate => totalCases == 0 ? 0.0 : (passedCases / totalCases) * 100;

  static bool _isValidUuid(String? str) {
    if (str == null) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

  factory TestSuiteModel.fromJson(Map<String, dynamic> json) {
    return TestSuiteModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      buildName: json['build_name'] ?? json['buildName'] ?? 'Build v1.0.4 - Release Candidate',
      version: json['version'] ?? 'v1.0.0',
      totalCases: json['total_cases'] ?? json['totalCases'] ?? 0,
      passedCases: json['passed_cases'] ?? json['passedCases'] ?? 0,
      failedCases: json['failed_cases'] ?? json['failedCases'] ?? 0,
      blockedCases: json['blocked_cases'] ?? json['blockedCases'] ?? 0,
      createdBy: json['created_by'] ?? json['createdBy'] ?? 'System',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }

  // Full JSON for local storage & state cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'build_name': buildName,
      'version': version,
      'total_cases': totalCases,
      'passed_cases': passedCases,
      'failed_cases': failedCases,
      'blocked_cases': blockedCases,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Safe subset of columns for Supabase database table schema
  Map<String, dynamic> toSupabaseJson({String? fallbackUserId}) {
    // Only proceed if our own id is a valid UUID; skip sync otherwise
    if (!_isValidUuid(id)) {
      return {}; // Caller must check for empty map and skip upsert
    }

    String? validCreatedBy;
    if (_isValidUuid(createdBy)) {
      validCreatedBy = createdBy;
    } else if (fallbackUserId != null && _isValidUuid(fallbackUserId)) {
      validCreatedBy = fallbackUserId;
    }

    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };

    if (validCreatedBy != null) {
      map['created_by'] = validCreatedBy;
    }

    return map;
  }

  TestSuiteModel copyWith({
    String? id,
    String? name,
    String? description,
    String? buildName,
    String? version,
    int? totalCases,
    int? passedCases,
    int? failedCases,
    int? blockedCases,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TestSuiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      buildName: buildName ?? this.buildName,
      version: version ?? this.version,
      totalCases: totalCases ?? this.totalCases,
      passedCases: passedCases ?? this.passedCases,
      failedCases: failedCases ?? this.failedCases,
      blockedCases: blockedCases ?? this.blockedCases,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
