import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/permission_provider.dart';
import '../utils/toast_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _slackAlerts = true;
  bool _autoRunNightly = false;
  String _selectedEnv = 'Staging-US-East';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings & Preferences',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure workspace parameters, integrations, and notification channels',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                // Section 1: Appearance & Theme
                _buildSectionHeader('APPEARANCE & THEME', isDark),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Dark Theme Mode'),
                        subtitle: const Text('Enable dark mode for high-contrast low-light workspace'),
                        value: isDark,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 2: Automation & Environment
                _buildSectionHeader('AUTOMATION & ENVIRONMENTS', isDark),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Execution Target Environment',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEnv,
                          items: const [
                            DropdownMenuItem(value: 'Staging-US-East', child: Text('Staging-US-East')),
                            DropdownMenuItem(value: 'QA-Sandbox-02', child: Text('QA-Sandbox-02')),
                            DropdownMenuItem(value: 'Isolated-SecLab', child: Text('Isolated-SecLab')),
                            DropdownMenuItem(value: 'Production-Mirror', child: Text('Production-Mirror')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedEnv = val);
                          },
                        ),
                        const Divider(height: 24),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Automated Nightly Regression'),
                          subtitle: const Text('Automatically trigger full test suite execution at 00:00 UTC'),
                          value: _autoRunNightly,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _autoRunNightly = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section 3: QA Lead Permission Matrix
                _buildSectionHeader('QA LEAD: ROLE PERMISSIONS & ACCESS CONTROL', isDark),
                Consumer<PermissionProvider>(
                  builder: (context, permProvider, _) {
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'QA Team Member / Tester Permissions',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                      ),
                                      Text(
                                        'As QA Lead, define which actions QA Team members are allowed to perform',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SwitchListTile.adaptive(
                            title: const Text('Edit Test Cases'),
                            subtitle: const Text('Allow team members to update test scenarios and steps'),
                            value: permProvider.teamCanEditTestCases,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => permProvider.updatePermissions(teamCanEditTestCases: val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: const Text('Delete Test Cases'),
                            subtitle: const Text('Allow team members to permanently delete test cases'),
                            value: permProvider.teamCanDeleteTestCases,
                            activeTrackColor: AppColors.failed,
                            onChanged: (val) => permProvider.updatePermissions(teamCanDeleteTestCases: val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: const Text('Create & Manage Test Suites'),
                            subtitle: const Text('Allow team members to create and edit test suites'),
                            value: permProvider.teamCanManageSuites,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => permProvider.updatePermissions(teamCanManageSuites: val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: const Text('Create & Manage Test Plans'),
                            subtitle: const Text('Allow team members to design and publish test plans'),
                            value: permProvider.teamCanManageTestPlans,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => permProvider.updatePermissions(teamCanManageTestPlans: val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: const Text('Delete Test Plans & Suites'),
                            subtitle: const Text('Allow team members to delete entire test plans or suites'),
                            value: permProvider.teamCanDeletePlansAndSuites,
                            activeTrackColor: AppColors.failed,
                            onChanged: (val) => permProvider.updatePermissions(teamCanDeletePlansAndSuites: val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: const Text('Export CSV Reports'),
                            subtitle: const Text('Allow team members to download test case reports to CSV'),
                            value: permProvider.teamCanExportCSV,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => permProvider.updatePermissions(teamCanExportCSV: val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: const Text('Import CSV Test Cases'),
                            subtitle: const Text('Allow team members to upload test case batches from CSV/Excel'),
                            value: permProvider.teamCanImportCSV,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => permProvider.updatePermissions(teamCanImportCSV: val),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Section 4: Integrations & Notifications
                _buildSectionHeader('INTEGRATIONS & NOTIFICATIONS', isDark),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Email Notifications'),
                        subtitle: const Text('Receive digest reports for failed test execution runs'),
                        value: _emailNotifications,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => setState(() => _emailNotifications = val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Slack Channel Webhook Alerts'),
                        subtitle: const Text('Send real-time defect alerts to #qa-test-center channel'),
                        value: _slackAlerts,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => setState(() => _slackAlerts = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () => ToastUtils.showSuccess(context, 'Settings & Permissions saved successfully!'),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Workspace Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
