enum TestCaseStatus { passed, failed, blocked, untested, inProgress }
enum TestCasePriority { critical, high, medium, low }

class TestCaseModel {
  final String id;
  final String code; // TC_ID e.g. TC-101
  final String title; // Test Case Scenario
  final String description;
  final String module;
  final String feature;
  final String preconditions;
  final List<String> steps;
  final String testData;
  final String expectedResult;
  final String actualResult;
  final TestCaseStatus status;
  final TestCasePriority priority;
  final String type; // Functional, UI, API, Security, Performance
  final String assignedTo; // Tester
  final String createdBy;
  final DateTime updatedAt;
  final DateTime? executionDate;
  final String remarks;
  final String suiteId;
  final String suiteName;

  const TestCaseModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.module = 'General Module',
    this.feature = 'Core Feature',
    this.preconditions = 'None',
    required this.steps,
    this.testData = 'N/A',
    required this.expectedResult,
    this.actualResult = 'N/A',
    required this.status,
    required this.priority,
    this.type = 'Functional',
    required this.assignedTo,
    required this.createdBy,
    required this.updatedAt,
    this.executionDate,
    this.remarks = 'N/A',
    this.suiteId = 'ts-1',
    this.suiteName = 'General Suite',
  });

  factory TestCaseModel.fromJson(Map<String, dynamic> json) {
    TestCaseStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'passed': return TestCaseStatus.passed;
        case 'failed': return TestCaseStatus.failed;
        case 'blocked': return TestCaseStatus.blocked;
        case 'inprogress':
        case 'in_progress': return TestCaseStatus.inProgress;
        default: return TestCaseStatus.untested;
      }
    }

    TestCasePriority parsePriority(String? p) {
      switch (p?.toLowerCase()) {
        case 'critical': return TestCasePriority.critical;
        case 'high': return TestCasePriority.high;
        case 'low': return TestCasePriority.low;
        default: return TestCasePriority.medium;
      }
    }

    List<String> parseSteps(dynamic rawSteps) {
      if (rawSteps == null) return [];
      if (rawSteps is List) return rawSteps.map((e) => e.toString()).toList();
      return [rawSteps.toString()];
    }

    final rawId = json['id']?.toString() ?? '';
    String rawCode = json['code']?.toString() ?? json['tc_id']?.toString() ?? '';
    String rawTitle = json['title']?.toString() ?? json['scenario']?.toString() ?? '';

    // Auto-repair corrupt code fields that absorbed comma-separated rows or sentence text
    if (rawCode.contains(',') || rawCode.length > 25 || rawCode.trim().contains(' ')) {
      if (rawTitle.isEmpty || rawTitle.startsWith('Imported Test Case')) {
        final parts = rawCode.split(',');
        rawTitle = parts.first.trim();
      }
      final shortId = rawId.length >= 4 ? rawId.substring(0, 4).toUpperCase() : '100';
      rawCode = 'TC-$shortId';
    } else if (rawCode.isEmpty) {
      final shortId = rawId.length >= 4 ? rawId.substring(0, 4).toUpperCase() : '100';
      rawCode = 'TC-$shortId';
    }

    if (rawTitle.isEmpty) {
      rawTitle = 'Test Scenario ($rawCode)';
    }

    return TestCaseModel(
      id: rawId,
      code: rawCode,
      title: rawTitle,
      description: json['description'] ?? rawTitle,
      module: json['module'] ?? 'General Module',
      feature: json['feature'] ?? 'Core Feature',
      preconditions: json['preconditions'] ?? 'None',
      steps: parseSteps(json['steps']),
      testData: json['test_data'] ?? json['testData'] ?? 'N/A',
      expectedResult: json['expected_result'] ?? json['expectedResult'] ?? '',
      actualResult: json['actual_result'] ?? json['actualResult'] ?? 'N/A',
      status: parseStatus(json['status']?.toString()),
      priority: parsePriority(json['priority']?.toString()),
      type: json['type'] ?? 'Functional',
      assignedTo: () {
        final raw = (json['assigned_to'] ?? json['assignedTo'] ?? json['tester'] ?? '').toString().trim();
        // If the value looks like a date (column shift artefact), discard it
        if (RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$').hasMatch(raw)) {
          return 'Unassigned';
        }
        return raw.isEmpty ? 'Unassigned' : raw;
      }(),
      createdBy: json['created_by'] ?? json['createdBy'] ?? 'System',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now()),
      executionDate: json['execution_date'] != null ? DateTime.parse(json['execution_date']) : null,
      remarks: json['remarks'] ?? 'N/A',
      suiteId: json['suite_id'] ?? json['suiteId'] ?? '',
      suiteName: json['suite_name'] ?? json['suiteName'] ?? 'General Suite',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'module': module,
      'feature': feature,
      'preconditions': preconditions,
      'steps': steps,
      'test_data': testData,
      'expected_result': expectedResult,
      'actual_result': actualResult,
      'status': status.name,
      'priority': priority.name,
      'type': type,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'updated_at': updatedAt.toIso8601String(),
      'execution_date': executionDate?.toIso8601String(),
      'remarks': remarks,
      'suite_id': suiteId.isNotEmpty ? suiteId : null,
      'suite_name': suiteName,
    };
  }

  static bool _isValidUuid(String? str) {
    if (str == null) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

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

    // Only include suite_id if it's a valid UUID
    final validSuiteId = _isValidUuid(suiteId) ? suiteId : null;

    // ⚠️ IMPORTANT: Only send columns that exist in the Supabase schema.
    // Run the SQL migration in Supabase Dashboard to add all missing columns,
    // then restore the full payload here.
    final map = <String, dynamic>{
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'module': module,
      'feature': feature,
      'preconditions': preconditions,
      'steps': steps,
      'test_data': testData,
      'expected_result': expectedResult,
      'actual_result': actualResult,
      'status': status.name,
      'priority': priority.name,
      'type': type,
      'assigned_to': assignedTo,
      'updated_at': updatedAt.toIso8601String(),
      'execution_date': executionDate?.toIso8601String(),
      'remarks': remarks,
      'suite_name': suiteName,
    };

    if (validCreatedBy != null) map['created_by'] = validCreatedBy;
    if (validSuiteId != null) map['suite_id'] = validSuiteId;

    return map;
  }


  TestCaseModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? module,
    String? feature,
    String? preconditions,
    List<String>? steps,
    String? testData,
    String? expectedResult,
    String? actualResult,
    TestCaseStatus? status,
    TestCasePriority? priority,
    String? type,
    String? assignedTo,
    String? createdBy,
    DateTime? updatedAt,
    DateTime? executionDate,
    String? remarks,
    String? suiteId,
    String? suiteName,
  }) {
    return TestCaseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      module: module ?? this.module,
      feature: feature ?? this.feature,
      preconditions: preconditions ?? this.preconditions,
      steps: steps ?? this.steps,
      testData: testData ?? this.testData,
      expectedResult: expectedResult ?? this.expectedResult,
      actualResult: actualResult ?? this.actualResult,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      executionDate: executionDate ?? this.executionDate,
      remarks: remarks ?? this.remarks,
      suiteId: suiteId ?? this.suiteId,
      suiteName: suiteName ?? this.suiteName,
    );
  }
}

