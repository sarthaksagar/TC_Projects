import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/report_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/toast_utils.dart';
import '../widgets/custom_chart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final summary = provider.summary;

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
                    'Quality Analytics & Reports',
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
                    'Comprehensive QA performance breakdown and exportable metrics',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ToastUtils.showInfo(
                        context, 'Exporting CSV dataset...'),
                    icon: const Icon(Icons.table_chart_rounded, size: 18),
                    label: const Text('Export CSV'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => ToastUtils.showSuccess(
                        context, 'PDF Executive Report generated and saved.'),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview Summary Cards
          Row(
            children: [
              Expanded(
                  child: _buildMetricCard(
                      'OVERALL PASS RATE',
                      '${summary?.overallPassPercentage}%',
                      AppColors.passed,
                      isDark)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildMetricCard(
                      'TEST CASES PASSED',
                      '${summary?.passedTestCases} / ${summary?.totalTestCases}',
                      AppColors.primary,
                      isDark)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildMetricCard(
                      'TOTAL DEFECTS LOGGED',
                      '${summary?.totalBugs} (${summary?.openBugs} open)',
                      AppColors.failed,
                      isDark)),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Section
          Expanded(
            child: CustomChart(
              title: 'Weekly Test Execution & Defect Trend Analysis',
              trends: provider.dailyTrends,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, Color color, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
