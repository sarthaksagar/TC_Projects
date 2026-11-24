import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/test_plan_model.dart';

void main() {
  group('TestPlanModel', () {
    group('fromJson', () {
      test('parses a fully populated JSON map', () {
        final json = {
          'id': 'plan-001',
          'title': 'Sprint 24 Test Plan',
          'version': 'v2.1',
          'target_release': 'Release 2.1',
          'status': 'Active',
          'start_date': '2024-01-01T00:00:00.000Z',
          'end_date': '2024-01-14T00:00:00.000Z',
          'suite_count': 3,
          'total_cases_count': 45,
          'owner': 'Alice',
        };

        final model = TestPlanModel.fromJson(json);

        expect(model.id, 'plan-001');
        expect(model.title, 'Sprint 24 Test Plan');
        expect(model.version, 'v2.1');
        expect(model.status, 'Active');
        expect(model.suiteCount, 3);
        expect(model.totalCasesCount, 45);
        expect(model.owner, 'Alice');
      });

      test('falls back to alias field names', () {
        final json = {
          'id': 'plan-002',
          'name': 'Plan via name alias',
          'targetRelease': 'R1',
          'startDate': '2024-03-01T00:00:00.000Z',
          'endDate': '2024-03-15T00:00:00.000Z',
          'suiteCount': 2,
          'totalCasesCount': 20,
          'created_by': 'Bob',
        };

        final model = TestPlanModel.fromJson(json);

        expect(model.title, 'Plan via name alias');
        expect(model.targetRelease, 'R1');
        expect(model.owner, 'Bob');
      });

      test('provides defaults when fields are missing', () {
        final json = {'id': 'x', 'title': 'Minimal Plan'};

        final model = TestPlanModel.fromJson(json);

        expect(model.version, 'v1.0.0');
        expect(model.targetRelease, 'Release 1.0');
        expect(model.status, 'Active');
        expect(model.suiteCount, 1);
        expect(model.totalCasesCount, 0);
        expect(model.owner, 'QA Member');
      });

      test('defaults endDate 14 days after startDate when endDate missing', () {
        final json = {
          'id': 'x',
          'title': 'T',
          'start_date': '2024-06-01T00:00:00.000Z',
        };

        final model = TestPlanModel.fromJson(json);

        final expectedEnd = DateTime(2024, 6, 1).add(const Duration(days: 14));
        expect(model.endDate.year, expectedEnd.year);
        expect(model.endDate.month, expectedEnd.month);
        expect(model.endDate.day, expectedEnd.day);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final model = TestPlanModel(
          id: 'p-1',
          title: 'Test Plan',
          version: 'v1.0',
          targetRelease: 'R1',
          status: 'Active',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 15),
          suiteCount: 2,
          totalCasesCount: 30,
          owner: 'Admin',
        );

        final json = model.toJson();

        expect(json['id'], 'p-1');
        expect(json['name'], 'Test Plan');
        expect(json['version'], 'v1.0');
        expect(json['status'], 'Active');
        expect(json['owner'], 'Admin');
      });

      test('round-trips correctly', () {
        final original = TestPlanModel(
          id: 'rt-p-1',
          title: 'RT Plan',
          version: 'v3',
          targetRelease: 'R3',
          status: 'Draft',
          startDate: DateTime(2024, 9, 1),
          endDate: DateTime(2024, 9, 30),
          suiteCount: 5,
          totalCasesCount: 60,
          owner: 'Lead',
        );

        final json = original.toJson();
        final restored = TestPlanModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.status, original.status);
        expect(restored.suiteCount, original.suiteCount);
      });
    });

    group('copyWith', () {
      final base = TestPlanModel(
        id: 'cp',
        title: 'Base',
        version: 'v1',
        targetRelease: 'R1',
        status: 'Draft',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        suiteCount: 1,
        totalCasesCount: 10,
        owner: 'User',
      );

      test('updates status', () {
        final updated = base.copyWith(status: 'Active');
        expect(updated.status, 'Active');
        expect(updated.id, base.id);
      });

      test('original is immutable', () {
        base.copyWith(status: 'Archived');
        expect(base.status, 'Draft');
      });
    });
  });
}
