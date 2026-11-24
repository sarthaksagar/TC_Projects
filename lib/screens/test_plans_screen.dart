import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/test_plan_model.dart';
import '../providers/auth_provider.dart';
import '../providers/test_plan_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/toast_utils.dart';

class TestPlansScreen extends StatelessWidget {
  const TestPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestPlanProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Plans & Release Milestones',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High-level testing strategy, timelines, and release milestone scope',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPlanDialog(context),
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                label: const Text('Create Test Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.testPlans.length,
                    itemBuilder: (context, index) {
                      final plan = provider.testPlans[index];
                      return _buildPlanCard(context, plan, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, TestPlanModel plan, bool isDark) {
    Color statusColor;
    switch (plan.status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.passed;
        break;
      case 'completed':
        statusColor = AppColors.primary;
        break;
      default:
        statusColor = AppColors.untested;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target: ${plan.targetRelease} (${plan.version})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('SUITES', '${plan.suiteCount}', isDark),
                _buildInfoCol('TEST CASES', '${plan.totalCasesCount}', isDark),
                _buildInfoCol('OWNER', plan.owner, isDark),
                _buildInfoCol(
                    'DURATION',
                    '${_formatDate(plan.startDate)} - ${_formatDate(plan.endDate)}',
                    isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple local date formatting (e.g. 2026-08-05)
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoCol(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  void _showAddPlanDialog(BuildContext context) {
    final titleController = TextEditingController();
    final releaseController = TextEditingController();
    final versionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Test Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Plan Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: releaseController,
                decoration: const InputDecoration(
                    labelText: 'Target Release (e.g. 2026-Q4)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: versionController,
                decoration: const InputDecoration(
                    labelText: 'Version Tag (e.g. v2.5.0)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final currentUserName = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Lead';
                final newPlan = TestPlanModel(
                  id: 'tp-${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  version: versionController.text.trim().isEmpty
                      ? 'v1.0.0'
                      : versionController.text.trim(),
                  targetRelease: releaseController.text.trim().isEmpty
                      ? 'Upcoming'
                      : releaseController.text.trim(),
                  status: 'Active',
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 14)),
                  suiteCount: 1,
                  totalCasesCount: 20,
                  owner: currentUserName,
                );
                await Provider.of<TestPlanProvider>(context, listen: false)
                    .addTestPlan(newPlan);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ToastUtils.showSuccess(
                      context, 'Test plan created successfully!');
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
