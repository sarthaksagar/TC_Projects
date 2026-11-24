import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/test_case_model.dart';

void main() {
  group('TestCaseModel', () {
    // ─── fromJson ───────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a fully populated JSON map correctly', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'code': 'TC-001',
          'title': 'Login with valid credentials',
          'description': 'Verify that a registered user can log in',
          'module': 'Auth',
          'feature': 'Login',
          'preconditions': 'User must be registered',
          'steps': ['Open app', 'Enter credentials', 'Click login'],
          'test_data': 'email=test@test.com',
          'expected_result': 'User lands on dashboard',
          'actual_result': 'Dashboard shown',
          'status': 'passed',
          'priority': 'high',
          'type': 'Functional',
          'assigned_to': 'John',
          'created_by': '123e4567-e89b-12d3-a456-426614174001',
          'updated_at': '2024-01-15T10:00:00.000Z',
          'execution_date': '2024-01-15T10:00:00.000Z',
          'remarks': 'All good',
          'suite_id': '123e4567-e89b-12d3-a456-426614174002',
          'suite_name': 'Auth Suite',
        };

        final model = TestCaseModel.fromJson(json);

        expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
        expect(model.code, 'TC-001');
        expect(model.title, 'Login with valid credentials');
        expect(model.module, 'Auth');
        expect(model.feature, 'Login');
        expect(model.steps.length, 3);
        expect(model.status, TestCaseStatus.passed);
        expect(model.priority, TestCasePriority.high);
        expect(model.assignedTo, 'John');
        expect(model.suiteId, '123e4567-e89b-12d3-a456-426614174002');
        expect(model.suiteName, 'Auth Suite');
        expect(model.executionDate != null, true);
      });

      test('handles null/missing fields with safe defaults', () {
        final json = {
          'id': 'abc123',
          'title': 'Simple Test',
          'expected_result': 'Should pass',
          'status': 'untested',
          'priority': 'medium',
          'assigned_to': 'Alice',
          'created_by': 'Bob',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };

        final model = TestCaseModel.fromJson(json);

        expect(model.module, 'General Module');
        expect(model.feature, 'Core Feature');
        expect(model.preconditions, 'None');
        expect(model.steps.isEmpty, true);
        expect(model.testData, 'N/A');
        expect(model.actualResult, 'N/A');
        expect(model.remarks, 'N/A');
        expect(model.suiteName, 'General Suite');
        expect(model.executionDate == null, true);
      });

      test('parses all TestCaseStatus values correctly', () {
        final statuses = {
          'passed': TestCaseStatus.passed,
          'failed': TestCaseStatus.failed,
          'blocked': TestCaseStatus.blocked,
          'inprogress': TestCaseStatus.inProgress,
          'in_progress': TestCaseStatus.inProgress,
          'untested': TestCaseStatus.untested,
          '': TestCaseStatus.untested,
          null: TestCaseStatus.untested,
        };

        for (final entry in statuses.entries) {
          final json = {
            'id': 'x',
            'title': 'T',
            'expected_result': 'E',
            'status': entry.key,
            'priority': 'medium',
            'assigned_to': 'A',
            'created_by': 'B',
            'updated_at': '2024-01-01T00:00:00.000Z',
          };
          final model = TestCaseModel.fromJson(json);
          expect(
            model.status,
            entry.value,
            reason: 'Status "${entry.key}" should map to ${entry.value}',
          );
        }
      });

      test('parses all TestCasePriority values correctly', () {
        final priorities = {
          'critical': TestCasePriority.critical,
          'high': TestCasePriority.high,
          'medium': TestCasePriority.medium,
          'low': TestCasePriority.low,
          'unknown': TestCasePriority.medium,
          null: TestCasePriority.medium,
        };

        for (final entry in priorities.entries) {
          final json = {
            'id': 'x',
            'title': 'T',
            'expected_result': 'E',
            'status': 'untested',
            'priority': entry.key,
            'assigned_to': 'A',
            'created_by': 'B',
            'updated_at': '2024-01-01T00:00:00.000Z',
          };
          final model = TestCaseModel.fromJson(json);
          expect(
            model.priority,
            entry.value,
            reason: 'Priority "${entry.key}" should map to ${entry.value}',
          );
        }
      });

      test('handles steps as a list', () {
        final json = {
          'id': 'x',
          'title': 'T',
          'expected_result': 'E',
          'status': 'untested',
          'priority': 'medium',
          'assigned_to': 'A',
          'created_by': 'B',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'steps': ['Step 1', 'Step 2', 'Step 3'],
        };
        final model = TestCaseModel.fromJson(json);
        expect(model.steps, ['Step 1', 'Step 2', 'Step 3']);
      });

      test('handles steps as a single string', () {
        final json = {
          'id': 'x',
          'title': 'T',
          'expected_result': 'E',
          'status': 'untested',
          'priority': 'medium',
          'assigned_to': 'A',
          'created_by': 'B',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'steps': 'Only one step',
        };
        final model = TestCaseModel.fromJson(json);
        expect(model.steps, ['Only one step']);
      });

      test('assigned_to field rejects date-like values', () {
        final json = {
          'id': 'x',
          'title': 'T',
          'expected_result': 'E',
          'status': 'untested',
          'priority': 'medium',
          'assigned_to': '2024-01-15',
          'created_by': 'B',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };
        final model = TestCaseModel.fromJson(json);
        expect(model.assignedTo, 'Unassigned');
      });

      test('auto-repairs corrupt code field', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'code': 'This is a very long corrupt code that is definitely not a TC ID',
          'title': '',
          'expected_result': 'E',
          'status': 'untested',
          'priority': 'medium',
          'assigned_to': 'A',
          'created_by': 'B',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };
        final model = TestCaseModel.fromJson(json);
        expect(model.code.startsWith('TC-'), true);
        expect(model.code.length < 15, true);
      });

      test('handles empty title gracefully', () {
        final json = {
          'id': 'x',
          'title': '',
          'code': 'TC-001',
          'expected_result': 'E',
          'status': 'untested',
          'priority': 'medium',
          'assigned_to': 'A',
          'created_by': 'B',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };
        final model = TestCaseModel.fromJson(json);
        expect(model.title.isNotEmpty, true);
        expect(model.title.contains('TC-001'), true);
      });
    });

    // ─── toJson ─────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serializes all fields correctly', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final model = TestCaseModel(
          id: 'test-id',
          code: 'TC-001',
          title: 'Test Title',
          description: 'Description',
          steps: ['Step 1', 'Step 2'],
          expectedResult: 'Expected',
          status: TestCaseStatus.passed,
          priority: TestCasePriority.high,
          assignedTo: 'Alice',
          createdBy: 'Bob',
          updatedAt: now,
        );

        final json = model.toJson();

        expect(json['id'], 'test-id');
        expect(json['code'], 'TC-001');
        expect(json['title'], 'Test Title');
        expect(json['status'], 'passed');
        expect(json['priority'], 'high');
        expect(json['steps'], ['Step 1', 'Step 2']);
        expect(json['assigned_to'], 'Alice');
        expect(json['created_by'], 'Bob');
        expect(json['execution_date'] == null, true);
      });

      test('round-trips through toJson → fromJson', () {
        final original = TestCaseModel(
          id: '123e4567-e89b-12d3-a456-426614174000',
          code: 'TC-042',
          title: 'Round-trip test',
          description: 'Verify round-trip serialization',
          module: 'Auth',
          feature: 'Login',
          preconditions: 'User exists',
          steps: ['Open', 'Enter', 'Submit'],
          testData: 'user@test.com',
          expectedResult: 'Success',
          actualResult: 'Success',
          status: TestCaseStatus.passed,
          priority: TestCasePriority.critical,
          type: 'API',
          assignedTo: 'Jane',
          createdBy: 'John',
          updatedAt: DateTime(2024, 6, 1),
          remarks: 'OK',
          suiteId: '123e4567-e89b-12d3-a456-426614174001',
          suiteName: 'API Suite',
        );

        final json = original.toJson();
        final restored = TestCaseModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.code, original.code);
        expect(restored.title, original.title);
        expect(restored.module, original.module);
        expect(restored.steps, original.steps);
        expect(restored.status, original.status);
        expect(restored.priority, original.priority);
        expect(restored.assignedTo, original.assignedTo);
      });
    });

    // ─── toSupabaseJson ─────────────────────────────────────────────────────

    group('toSupabaseJson', () {
      test('returns empty map when id is not a valid UUID', () {
        final model = TestCaseModel(
          id: 'not-a-uuid',
          code: 'TC-001',
          title: 'Test',
          description: '',
          steps: [],
          expectedResult: 'Pass',
          status: TestCaseStatus.untested,
          priority: TestCasePriority.medium,
          assignedTo: 'Alice',
          createdBy: 'Bob',
          updatedAt: DateTime.now(),
        );
        expect(model.toSupabaseJson().isEmpty, true);
      });

      test('returns non-empty map when id is a valid UUID', () {
        final model = TestCaseModel(
          id: '123e4567-e89b-12d3-a456-426614174000',
          code: 'TC-001',
          title: 'Test',
          description: '',
          steps: [],
          expectedResult: 'Pass',
          status: TestCaseStatus.untested,
          priority: TestCasePriority.medium,
          assignedTo: 'Alice',
          createdBy: 'Bob',
          updatedAt: DateTime.now(),
        );
        final json = model.toSupabaseJson();
        expect(json.isNotEmpty, true);
        expect(json['id'], '123e4567-e89b-12d3-a456-426614174000');
        expect(json['code'], 'TC-001');
      });

      test('excludes invalid suite_id from Supabase payload', () {
        final model = TestCaseModel(
          id: '123e4567-e89b-12d3-a456-426614174000',
          code: 'TC-001',
          title: 'Test',
          description: '',
          steps: [],
          expectedResult: 'Pass',
          status: TestCaseStatus.untested,
          priority: TestCasePriority.medium,
          assignedTo: 'Alice',
          createdBy: 'Bob',
          updatedAt: DateTime.now(),
          suiteId: 'ts-1',
        );
        final json = model.toSupabaseJson();
        expect(json.containsKey('suite_id'), false);
      });
    });

    // ─── copyWith ───────────────────────────────────────────────────────────

    group('copyWith', () {
      final base = TestCaseModel(
        id: 'id-1',
        code: 'TC-001',
        title: 'Base',
        description: 'Base desc',
        steps: ['s1'],
        expectedResult: 'Pass',
        status: TestCaseStatus.untested,
        priority: TestCasePriority.medium,
        assignedTo: 'Alice',
        createdBy: 'Bob',
        updatedAt: DateTime(2024, 1, 1),
      );

      test('returns copy with updated status', () {
        final updated = base.copyWith(status: TestCaseStatus.passed);
        expect(updated.status, TestCaseStatus.passed);
        expect(updated.id, base.id);
        expect(updated.title, base.title);
      });

      test('returns copy with updated title and code', () {
        final updated = base.copyWith(title: 'New Title', code: 'TC-999');
        expect(updated.title, 'New Title');
        expect(updated.code, 'TC-999');
        expect(updated.status, base.status);
      });

      test('original is not mutated after copyWith', () {
        base.copyWith(status: TestCaseStatus.failed);
        expect(base.status, TestCaseStatus.untested);
      });

      test('copyWith with null params preserves original values', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.title, base.title);
        expect(copy.steps, base.steps);
      });
    });

    // ─── status enum ───────────────────────────────────────────────────────

    group('status enum', () {
      test('all enum values are defined', () {
        expect(TestCaseStatus.values.length, 5);
        expect(TestCasePriority.values.length, 4);
      });
    });
  });
}
