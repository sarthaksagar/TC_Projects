import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/user_model.dart';

void main() {
  group('UserModel', () {
    group('fromJson', () {
      test('parses a fully populated JSON map', () {
        final json = {
          'id': 'user-001',
          'name': 'Alice Smith',
          'email': 'alice@example.com',
          'role': 'QA Lead',
          'avatarUrl': 'https://i.pravatar.cc/150?u=alice',
          'isActive': true,
          'createdAt': '2024-01-01T00:00:00.000Z',
        };

        final model = UserModel.fromJson(json);

        expect(model.id, 'user-001');
        expect(model.name, 'Alice Smith');
        expect(model.email, 'alice@example.com');
        expect(model.role, 'QA Lead');
        expect(model.isActive, true);
      });

      test('parses snake_case JSON aliases', () {
        final json = {
          'id': 'user-002',
          'full_name': 'Bob Jones',
          'email': 'bob@example.com',
          'role': 'QA Analyst',
          'avatar_url': 'https://example.com/avatar.png',
          'is_active': false,
          'created_at': '2024-02-01T00:00:00.000Z',
        };

        final model = UserModel.fromJson(json);

        expect(model.name, 'Bob Jones');
        expect(model.avatarUrl, 'https://example.com/avatar.png');
        expect(model.isActive, false);
      });

      test('provides defaults for missing fields', () {
        final json = {
          'id': 'user-003',
          'email': 'charlie@test.com',
        };

        final model = UserModel.fromJson(json);

        expect(model.name.isNotEmpty, true);
        expect(model.role, 'QA Analyst');
        expect(model.isActive, true);
      });

      test('falls back to current date when createdAt is missing', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final json = {'id': 'x', 'email': 'x@x.com'};
        final model = UserModel.fromJson(json);
        expect(model.createdAt.isAfter(before), true);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final date = DateTime(2024, 5, 20);
        final model = UserModel(
          id: 'u-1',
          name: 'Jane',
          email: 'jane@test.com',
          role: 'SDET Specialist',
          avatarUrl: 'https://avatar.com/1',
          isActive: true,
          createdAt: date,
        );

        final json = model.toJson();

        expect(json['id'], 'u-1');
        expect(json['full_name'], 'Jane');
        expect(json['email'], 'jane@test.com');
        expect(json['role'], 'SDET Specialist');
        expect(json['is_active'], true);
        expect(json['created_at'], date.toIso8601String());
      });

      test('round-trips through toJson → fromJson', () {
        final original = UserModel(
          id: 'rt-u-1',
          name: 'Round Trip User',
          email: 'rt@test.com',
          role: 'QA Lead',
          avatarUrl: 'https://avatar.com/rt',
          isActive: true,
          createdAt: DateTime(2024, 1, 15),
        );

        final json = original.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.email, original.email);
        expect(restored.role, original.role);
        expect(restored.isActive, original.isActive);
      });
    });

    group('copyWith', () {
      final base = UserModel(
        id: 'base',
        name: 'Base User',
        email: 'base@test.com',
        role: 'QA Analyst',
        avatarUrl: 'https://avatar.com',
        isActive: true,
        createdAt: DateTime(2024),
      );

      test('updates isActive only', () {
        final updated = base.copyWith(isActive: false);
        expect(updated.isActive, false);
        expect(updated.id, base.id);
        expect(updated.name, base.name);
      });

      test('updates role only', () {
        final updated = base.copyWith(role: 'QA Lead');
        expect(updated.role, 'QA Lead');
        expect(updated.email, base.email);
      });

      test('original is not mutated', () {
        base.copyWith(isActive: false);
        expect(base.isActive, true);
      });
    });
  });
}
