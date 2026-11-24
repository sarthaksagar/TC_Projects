import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/test_suite_model.dart';

void main() {
  group('TestSuiteModel', () {
    // ─── fromJson ───────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses all fields from snake_case JSON', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'name': 'Auth Suite',
          'description': 'All auth-related tests',
          'build_name': 'Build v2.0.0',
          'version': 'v2.0',
          'total_cases': 20,
          'passed_cases': 15,
          'failed_cases': 3,
          'blocked_cases': 2,
          'created_by': '123e4567-e89b-12d3-a456-426614174001',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final model = TestSuiteModel.fromJson(json);

        expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
        expect(model.name, 'Auth Suite');
        expect(model.description, 'All auth-related tests');
        expect(model.totalCases, 20);
        expect(model.passedCases, 15);
        expect(model.failedCases, 3);
        expect(model.blockedCases, 2);
      });

      test('parses camelCase JSON aliases', () {
        final json = {
          'id': 'x',
          'name': 'Suite',
          'description': '',
          'buildName': 'QA Build',
          'totalCases': 10,
          'passedCases': 8,
          'failedCases': 1,
          'blockedCases': 1,
          'createdBy': 'Alice',
          'createdAt': '2024-03-01T00:00:00.000Z',
        };

        final model = TestSuiteModel.fromJson(json);

        expect(model.buildName, 'QA Build');
        expect(model.totalCases, 10);
        expect(model.createdBy, 'Alice');
      });

      test('provides defaults when fields are missing', () {
        final json = {
          'id': 'x',
          'name': 'Basic Suite',
          'description': '',
        };

        final model = TestSuiteModel.fromJson(json);

        expect(model.buildName.isNotEmpty, true);
        expect(model.version, 'v1.0.0');
        expect(model.totalCases, 0);
        expect(model.passedCases, 0);
        expect(model.failedCases, 0);
        expect(model.blockedCases, 0);
        expect(model.createdBy, 'System');
      });
    });

    // ─── passRate ───────────────────────────────────────────────────────────

    group('passRate', () {
      test('returns 0.0 when totalCases is 0', () {
        final model = TestSuiteModel(
          id: '1',
          name: 'Empty',
          description: '',
          totalCases: 0,
          passedCases: 0,
          failedCases: 0,
          blockedCases: 0,
          createdBy: 'A',
          createdAt: DateTime.now(),
        );
        expect(model.passRate, 0.0);
      });

      test('calculates correct pass rate', () {
        final model = TestSuiteModel(
          id: '1',
          name: 'Suite',
          description: '',
          totalCases: 10,
          passedCases: 7,
          failedCases: 2,
          blockedCases: 1,
          createdBy: 'A',
          createdAt: DateTime.now(),
        );
        expect(model.passRate, 70.0);
      });

      test('returns 100.0 when all tests pass', () {
        final model = TestSuiteModel(
          id: '1',
          name: 'Suite',
          description: '',
          totalCases: 5,
          passedCases: 5,
          failedCases: 0,
          blockedCases: 0,
          createdBy: 'A',
          createdAt: DateTime.now(),
        );
        expect(model.passRate, 100.0);
      });
    });

    // ─── toSupabaseJson ──────────────────────────────────────────────────────

    group('toSupabaseJson', () {
      test('returns empty map for non-UUID id', () {
        final model = TestSuiteModel(
          id: 'ts-1',
          name: 'Suite',
          description: '',
          totalCases: 0,
          passedCases: 0,
          failedCases: 0,
          blockedCases: 0,
          createdBy: 'A',
          createdAt: DateTime.now(),
        );
        expect(model.toSupabaseJson().isEmpty, true);
      });

      test('returns non-empty map for valid UUID id', () {
        final model = TestSuiteModel(
          id: '123e4567-e89b-12d3-a456-426614174000',
          name: 'Auth Suite',
          description: 'Auth tests',
          totalCases: 10,
          passedCases: 8,
          failedCases: 1,
          blockedCases: 1,
          createdBy: 'User',
          createdAt: DateTime(2024, 1, 1),
        );
        final json = model.toSupabaseJson();
        expect(json.isNotEmpty, true);
        expect(json['id'], '123e4567-e89b-12d3-a456-426614174000');
        expect(json['name'], 'Auth Suite');
      });
    });

    // ─── empty factory ───────────────────────────────────────────────────────

    test('TestSuiteModel.empty() creates a valid empty model', () {
      final model = TestSuiteModel.empty();
      expect(model.id, '');
      expect(model.totalCases, 0);
      expect(model.passRate, 0.0);
    });

    // ─── copyWith ───────────────────────────────────────────────────────────

    group('copyWith', () {
      final base = TestSuiteModel(
        id: 'base-id',
        name: 'Base Suite',
        description: 'Base',
        totalCases: 5,
        passedCases: 3,
        failedCases: 1,
        blockedCases: 1,
        createdBy: 'User',
        createdAt: DateTime(2024),
      );

      test('updates name and description only', () {
        final updated = base.copyWith(name: 'New Name', description: 'New Desc');
        expect(updated.name, 'New Name');
        expect(updated.description, 'New Desc');
        expect(updated.totalCases, base.totalCases);
      });

      test('original is not mutated', () {
        base.copyWith(name: 'Changed');
        expect(base.name, 'Base Suite');
      });
    });

    // ─── round-trip ─────────────────────────────────────────────────────────

    test('round-trips through toJson → fromJson', () {
      final original = TestSuiteModel(
        id: 'rt-id',
        name: 'Round Trip Suite',
        description: 'RT',
        buildName: 'Build 3.0',
        version: 'v3.0',
        totalCases: 20,
        passedCases: 18,
        failedCases: 1,
        blockedCases: 1,
        createdBy: 'Tester',
        createdAt: DateTime(2024, 6, 15),
      );

      final json = original.toJson();
      final restored = TestSuiteModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.totalCases, original.totalCases);
      expect(restored.passedCases, original.passedCases);
      expect(restored.passRate, original.passRate);
    });
  });
}
