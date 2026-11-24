import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

class PermissionProvider extends ChangeNotifier {
  // Permission toggles for QA Team Members (configured by QA Lead)
  bool _teamCanEditTestCases = true;
  bool _teamCanDeleteTestCases = false;
  bool _teamCanManageSuites = true;
  bool _teamCanManageTestPlans = false;
  bool _teamCanDeletePlansAndSuites = false;
  bool _teamCanExportCSV = true;
  bool _teamCanImportCSV = true;
  bool _teamCanManageUsers = false;

  PermissionProvider() {
    _loadPermissions();
  }

  bool get teamCanEditTestCases => _teamCanEditTestCases;
  bool get teamCanDeleteTestCases => _teamCanDeleteTestCases;
  bool get teamCanManageSuites => _teamCanManageSuites;
  bool get teamCanManageTestPlans => _teamCanManageTestPlans;
  bool get teamCanDeletePlansAndSuites => _teamCanDeletePlansAndSuites;
  bool get teamCanExportCSV => _teamCanExportCSV;
  bool get teamCanImportCSV => _teamCanImportCSV;
  bool get teamCanManageUsers => _teamCanManageUsers;

  /// Helper to check if a specific user role has permission
  bool hasPermission(String userRole, String action) {
    final role = userRole.trim().toLowerCase();
    // QA Lead and Admin have all permissions unconditionally
    if (role.contains('lead') || role.contains('admin') || role.contains('manager')) {
      return true;
    }

    // Otherwise apply QA Team / Tester permissions
    switch (action) {
      case 'edit_test_case':
        return _teamCanEditTestCases;
      case 'delete_test_case':
        return _teamCanDeleteTestCases;
      case 'manage_suites':
        return _teamCanManageSuites;
      case 'manage_plans':
        return _teamCanManageTestPlans;
      case 'delete_plans_and_suites':
        return _teamCanDeletePlansAndSuites;
      case 'export_csv':
        return _teamCanExportCSV;
      case 'import_csv':
        return _teamCanImportCSV;
      case 'manage_users':
        return _teamCanManageUsers;
      default:
        return true;
    }
  }

  Future<void> _loadPermissions() async {
    try {
      final storage = StorageService();
      final editTC = await storage.read('perm_teamCanEditTestCases');
      if (editTC != null) _teamCanEditTestCases = editTC == true || editTC == 'true';

      final delTC = await storage.read('perm_teamCanDeleteTestCases');
      if (delTC != null) _teamCanDeleteTestCases = delTC == true || delTC == 'true';

      final manSuites = await storage.read('perm_teamCanManageSuites');
      if (manSuites != null) _teamCanManageSuites = manSuites == true || manSuites == 'true';

      final manPlans = await storage.read('perm_teamCanManageTestPlans');
      if (manPlans != null) _teamCanManageTestPlans = manPlans == true || manPlans == 'true';

      final delPlans = await storage.read('perm_teamCanDeletePlansAndSuites');
      if (delPlans != null) _teamCanDeletePlansAndSuites = delPlans == true || delPlans == 'true';

      final expCSV = await storage.read('perm_teamCanExportCSV');
      if (expCSV != null) _teamCanExportCSV = expCSV == true || expCSV == 'true';

      final impCSV = await storage.read('perm_teamCanImportCSV');
      if (impCSV != null) _teamCanImportCSV = impCSV == true || impCSV == 'true';

      final manUsers = await storage.read('perm_teamCanManageUsers');
      if (manUsers != null) _teamCanManageUsers = manUsers == true || manUsers == 'true';

      AppLogger.info('PermissionProvider', 'Permissions loaded from storage');
      notifyListeners();
    } catch (e) {
      AppLogger.warn('PermissionProvider', 'Could not load custom permissions, using defaults: $e');
    }
  }

  Future<void> updatePermissions({
    bool? teamCanEditTestCases,
    bool? teamCanDeleteTestCases,
    bool? teamCanManageSuites,
    bool? teamCanManageTestPlans,
    bool? teamCanDeletePlansAndSuites,
    bool? teamCanExportCSV,
    bool? teamCanImportCSV,
    bool? teamCanManageUsers,
  }) async {
    if (teamCanEditTestCases != null) _teamCanEditTestCases = teamCanEditTestCases;
    if (teamCanDeleteTestCases != null) _teamCanDeleteTestCases = teamCanDeleteTestCases;
    if (teamCanManageSuites != null) _teamCanManageSuites = teamCanManageSuites;
    if (teamCanManageTestPlans != null) _teamCanManageTestPlans = teamCanManageTestPlans;
    if (teamCanDeletePlansAndSuites != null) _teamCanDeletePlansAndSuites = teamCanDeletePlansAndSuites;
    if (teamCanExportCSV != null) _teamCanExportCSV = teamCanExportCSV;
    if (teamCanImportCSV != null) _teamCanImportCSV = teamCanImportCSV;
    if (teamCanManageUsers != null) _teamCanManageUsers = teamCanManageUsers;

    notifyListeners();

    final storage = StorageService();
    await storage.save('perm_teamCanEditTestCases', _teamCanEditTestCases);
    await storage.save('perm_teamCanDeleteTestCases', _teamCanDeleteTestCases);
    await storage.save('perm_teamCanManageSuites', _teamCanManageSuites);
    await storage.save('perm_teamCanManageTestPlans', _teamCanManageTestPlans);
    await storage.save('perm_teamCanDeletePlansAndSuites', _teamCanDeletePlansAndSuites);
    await storage.save('perm_teamCanExportCSV', _teamCanExportCSV);
    await storage.save('perm_teamCanImportCSV', _teamCanImportCSV);
    await storage.save('perm_teamCanManageUsers', _teamCanManageUsers);

    AppLogger.success('PermissionProvider', 'QA Lead updated team permissions successfully');
  }
}
