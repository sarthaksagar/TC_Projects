import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/providers/permission_provider.dart';

void main() {
  group('PermissionProvider', () {
    late PermissionProvider provider;

    setUp(() {
      provider = PermissionProvider();
    });

    test('default permissions are correctly set', () {
      expect(provider.teamCanEditTestCases, true);
      expect(provider.teamCanDeleteTestCases, false);
      expect(provider.teamCanManageSuites, true);
      expect(provider.teamCanManageTestPlans, false);
      expect(provider.teamCanDeletePlansAndSuites, false);
      expect(provider.teamCanExportCSV, true);
      expect(provider.teamCanImportCSV, true);
      expect(provider.teamCanManageUsers, false);
    });

    group('hasPermission for QA Lead / Admin', () {
      test('grants all permissions unconditionally to QA Lead', () {
        expect(provider.hasPermission('QA Lead', 'edit_test_case'), true);
        expect(provider.hasPermission('QA Lead', 'delete_test_case'), true);
        expect(provider.hasPermission('QA Lead', 'manage_suites'), true);
        expect(provider.hasPermission('QA Lead', 'manage_plans'), true);
        expect(provider.hasPermission('QA Lead', 'delete_plans_and_suites'), true);
        expect(provider.hasPermission('QA Lead', 'export_csv'), true);
        expect(provider.hasPermission('QA Lead', 'import_csv'), true);
        expect(provider.hasPermission('QA Lead', 'manage_users'), true);
      });

      test('grants all permissions unconditionally to Admin', () {
        expect(provider.hasPermission('Admin', 'delete_test_case'), true);
        expect(provider.hasPermission('System Administrator', 'manage_users'), true);
      });

      test('grants all permissions unconditionally to QA Manager', () {
        expect(provider.hasPermission('QA Manager', 'delete_plans_and_suites'), true);
      });
    });

    group('hasPermission for QA Team Member / Tester', () {
      test('respects default team constraints', () {
        expect(provider.hasPermission('QA Team Member', 'edit_test_case'), true);
        expect(provider.hasPermission('QA Team Member', 'delete_test_case'), false);
        expect(provider.hasPermission('QA Team Member', 'manage_plans'), false);
        expect(provider.hasPermission('QA Team Member', 'manage_users'), false);
        expect(provider.hasPermission('QA Team Member', 'export_csv'), true);
      });

      test('updates and reflects modified permissions', () async {
        await provider.updatePermissions(
          teamCanDeleteTestCases: true,
          teamCanManageUsers: true,
        );

        expect(provider.teamCanDeleteTestCases, true);
        expect(provider.teamCanManageUsers, true);
        expect(provider.hasPermission('QA Team Member', 'delete_test_case'), true);
        expect(provider.hasPermission('QA Team Member', 'manage_users'), true);
      });
    });
  });
}

