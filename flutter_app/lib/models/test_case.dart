import 'dart:convert';

class TestCase {
  final String id;
  String title;
  String description;
  Map<String, dynamic>? steps;
  String? expectedResult;
  String? suiteId;
  String? createdBy;

  TestCase({
    required this.id,
    required this.title,
    this.description = '',
    this.steps,
    this.expectedResult,
    this.suiteId,
    this.createdBy,
  });

  factory TestCase.fromMap(Map<String, dynamic> m) => TestCase(
        id: m['id'] as String,
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        steps: m['steps'] != null ? Map<String, dynamic>.from(m['steps']) : null,
        expectedResult: m['expected_result'],
        suiteId: m['suite_id']?.toString(),
        createdBy: m['created_by']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'steps': steps != null ? steps : null,
        'expected_result': expectedResult,
        'suite_id': suiteId,
      };

  String toJson() => json.encode(toMap());
}
