import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/test_execution_model.dart';
import '../models/test_case_model.dart';
import '../providers/auth_provider.dart';
import '../providers/test_execution_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/toast_utils.dart';

class TestExecutionScreen extends StatelessWidget {
  const TestExecutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestExecutionProvider>(context);
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
                    'Test Execution Cycles',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor active runs, automated CI/CD execution status, and environment health',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _triggerNewExecution(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Start New Test Run'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.passed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.executions.length,
                    itemBuilder: (context, index) {
                      final exec = provider.executions[index];
                      return _buildExecutionCard(context, exec, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionCard(BuildContext context, TestExecutionModel exec, bool isDark) {
    Color statusColor;
    switch (exec.status) {
      case TestCaseStatus.passed:
        statusColor = AppColors.passed;
        break;
      case TestCaseStatus.failed:
        statusColor = AppColors.failed;
        break;
      case TestCaseStatus.inProgress:
        statusColor = AppColors.secondary;
        break;
      default:
        statusColor = AppColors.blocked;
    }

    double passRatio = exec.totalCount == 0 ? 0 : (exec.passedCount / exec.totalCount);

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
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.play_circle_fill_rounded, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exec.executionName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan: ${exec.testPlanName} • Env: ${exec.environment}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exec.status.name.toUpperCase(),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: passRatio,
                minHeight: 8,
                backgroundColor: AppColors.failed.withValues(alpha: 0.2),
                color: AppColors.passed,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${exec.passedCount} Passed  |  ${exec.failedCount} Failed  |  ${exec.blockedCount} Blocked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  'Executed by ${exec.executedBy} • ${DateFormatter.formatDateTime(exec.executedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _triggerNewExecution(BuildContext context) async {
    final currentUserName = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Member';
    final newExec = TestExecutionModel(
      id: 'te-${DateTime.now().millisecondsSinceEpoch}',
      executionName: 'Manual Ad-Hoc Suite Run #${DateTime.now().minute}',
      testPlanName: 'v2.4.0 Major Release Regression Plan',
      environment: 'Staging-US-East',
      status: TestCaseStatus.inProgress,
      executedAt: DateTime.now(),
      executedBy: currentUserName,
      totalCount: 50,
      passedCount: 45,
      failedCount: 3,
      blockedCount: 2,
      duration: const Duration(minutes: 12),
    );

    await Provider.of<TestExecutionProvider>(context, listen: false).addExecution(newExec);
    if (context.mounted) {
      ToastUtils.showSuccess(context, 'New test execution initiated on Staging-US-East');
    }
  }
}
