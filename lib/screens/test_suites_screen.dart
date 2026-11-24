import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import '../models/test_case_model.dart';
import '../models/test_suite_model.dart';
import '../providers/auth_provider.dart';
import '../providers/test_case_provider.dart';
import '../providers/test_suite_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/toast_utils.dart';

class TestSuitesScreen extends StatelessWidget {
  const TestSuitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suiteProvider = Provider.of<TestSuiteProvider>(context);
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
                    'Test Suites',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grouped collections of related test specifications, builds, and test cases',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddSuiteDialog(context),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Create Test Suite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: suiteProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : suiteProvider.testSuites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 16),
                            Text(
                              'No Test Suites Created',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create a test suite to group, version, and manage your test cases.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddSuiteDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create Test Suite'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 480,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 260,
                        ),
                        itemCount: suiteProvider.testSuites.length,
                        itemBuilder: (context, index) {
                          final suite = suiteProvider.testSuites[index];
                          return _buildSuiteCard(context, suite, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuiteCard(BuildContext context, TestSuiteModel suite, bool isDark) {
    final tcProvider = Provider.of<TestCaseProvider>(context);

    // Live test cases belonging to this suite (matching ID or suite name)
    final suiteCases = tcProvider.allRawCases.where((tc) {
      return (tc.suiteId.isNotEmpty && tc.suiteId == suite.id) ||
          (tc.suiteName.isNotEmpty && tc.suiteName.trim().toLowerCase() == suite.name.trim().toLowerCase());
    }).toList();

    final totalCases = suiteCases.length;
    final passedCases = suiteCases.where((tc) => tc.status == TestCaseStatus.passed).length;
    final double passRate = totalCases == 0 ? 0.0 : (passedCases / totalCases);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.go('/test-suites/${suite.id}', extra: suite);
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_special_rounded, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suite.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'Created by ${suite.createdBy}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.failed),
                    tooltip: 'Delete Test Suite',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Delete Suite "${suite.name}"?'),
                          content: const Text('Are you sure you want to delete this test suite?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.failed, foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Provider.of<TestSuiteProvider>(context, listen: false).deleteTestSuite(suite.id);
                                ToastUtils.showSuccess(context, 'Suite "${suite.name}" deleted.');
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Build Name and Version Badges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Build: ${suite.buildName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Version: ${suite.version}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),

              Text(
                suite.description.isNotEmpty
                    ? suite.description
                    : 'Suite test scenario management and execution repository',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalCases Total Test Cases',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(passRate * 100).toStringAsFixed(0)}% Passed',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.passed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: passRate,
                      minHeight: 8,
                      backgroundColor: AppColors.failed.withValues(alpha: 0.2),
                      color: AppColors.passed,
                    ),
                  ),
                ],
              ),

              // Open Suite Details & Test Cases
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    context.go('/test-suites/${suite.id}', extra: suite);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Manage & View Test Cases', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSuiteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final buildController = TextEditingController(text: 'Build v1.0.4 - Release Staging');
    final versionController = TextEditingController(text: 'v1.0.0');
    final descController = TextEditingController();
    // Capture current user BEFORE dialog opens
    final currentUserName = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Lead';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Test Suite'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Suite Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buildController,
                    decoration: const InputDecoration(labelText: 'Build Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: versionController,
                    decoration: const InputDecoration(labelText: 'Version'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final newSuite = TestSuiteModel(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  buildName: buildController.text.trim().isNotEmpty ? buildController.text.trim() : 'Build v1.0.4 - Release Staging',
                  version: versionController.text.trim().isNotEmpty ? versionController.text.trim() : 'v1.0.0',
                  description: descController.text.trim(),
                  totalCases: 0,
                  passedCases: 0,
                  failedCases: 0,
                  blockedCases: 0,
                  createdBy: currentUserName,
                  createdAt: DateTime.now(),
                );
                await Provider.of<TestSuiteProvider>(context, listen: false).addTestSuite(newSuite);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ToastUtils.showSuccess(context, 'Test suite created successfully!');
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
