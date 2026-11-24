import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import '../models/test_case_model.dart';
import '../models/test_suite_model.dart';
import '../providers/auth_provider.dart';
import '../providers/test_case_provider.dart';
import '../providers/test_suite_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_logger.dart';
import '../utils/toast_utils.dart';

import 'package:go_router/go_router.dart';

class TestSuiteDetailScreen extends StatefulWidget {
  final TestSuiteModel? suite;
  final String? suiteId;

  const TestSuiteDetailScreen({super.key, this.suite, this.suiteId});

  @override
  State<TestSuiteDetailScreen> createState() => _TestSuiteDetailScreenState();
}

class _TestSuiteDetailScreenState extends State<TestSuiteDetailScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedModuleFilter = 'All';
  final Set<String> _expandedCaseIds = {};
  TestSuiteModel _currentSuite = TestSuiteModel.empty();

  @override
  void initState() {
    super.initState();
    if (widget.suite != null) {
      _currentSuite = widget.suite!;
      AppLogger.info(
        'TestSuiteDetailScreen',
        'Opened TestSuiteDetailScreen for "${_currentSuite.name}" (ID: ${_currentSuite.id}, Build: ${_currentSuite.buildName}, Version: ${_currentSuite.version})',
      );
    }
  }

  @override
  void dispose() {
    if (_currentSuite.id.isNotEmpty) {
      AppLogger.info('TestSuiteDetailScreen', 'Exiting TestSuiteDetailScreen for "${_currentSuite.name}"');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tcProvider = Provider.of<TestCaseProvider>(context);
    final suiteProvider = Provider.of<TestSuiteProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filterOptions = ['All', 'Passed', 'Failed', 'Blocked', 'Untested'];

    // Resolve active suite from provider by ID or widget.suite
    final targetId = widget.suite?.id ?? widget.suiteId ?? _currentSuite.id;
    if (targetId.isNotEmpty) {
      final existing = suiteProvider.testSuites.where((s) => s.id == targetId).toList();
      if (existing.isNotEmpty) {
        _currentSuite = existing.first;
      }
    } else if (widget.suite != null) {
      _currentSuite = widget.suite!;
    }

    if (_currentSuite.id.isEmpty && suiteProvider.testSuites.isNotEmpty) {
      // If we only have suiteId and list loaded
      if (widget.suiteId != null && widget.suiteId!.isNotEmpty) {
        final matches = suiteProvider.testSuites.where((s) => s.id == widget.suiteId).toList();
        if (matches.isNotEmpty) {
          _currentSuite = matches.first;
        }
      }
    }

    if (_currentSuite.id.isEmpty && widget.suite == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading Test Suite details...'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go('/test-suites'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Test Suites'),
              ),
            ],
          ),
        ),
      );
    }

    final activeSuite = _currentSuite;

    // Filter test cases belonging to this suite
    final suiteCases = tcProvider.testCases.where((tc) {
      final matchesSuite = (tc.suiteId.isNotEmpty && tc.suiteId == activeSuite.id) ||
          (tc.suiteName.isNotEmpty && tc.suiteName.toLowerCase() == activeSuite.name.toLowerCase());
      return matchesSuite;
    }).toList();

    // Extract available modules for dropdown filter
    final modules = {'All', ...suiteCases.map((tc) => tc.module.trim()).where((m) => m.isNotEmpty)};

    // Apply search and filters
    final filteredCases = suiteCases.where((tc) {
      // Status filter
      if (_selectedStatusFilter != 'All') {
        if (tc.status.name.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      // Module filter
      if (_selectedModuleFilter != 'All') {
        if (tc.module.trim().toLowerCase() != _selectedModuleFilter.toLowerCase()) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesCode = tc.code.toLowerCase().contains(q);
        final matchesTitle = tc.title.toLowerCase().contains(q);
        final matchesModule = tc.module.toLowerCase().contains(q);
        final matchesFeature = tc.feature.toLowerCase().contains(q);
        final matchesTester = tc.assignedTo.toLowerCase().contains(q);
        return matchesCode || matchesTitle || matchesModule || matchesFeature || matchesTester;
      }

      return true;
    }).toList();

    final totalCount = suiteCases.length;
    final passedCount = suiteCases.where((c) => c.status == TestCaseStatus.passed).length;
    final failedCount = suiteCases.where((c) => c.status == TestCaseStatus.failed).length;
    final blockedCount = suiteCases.where((c) => c.status == TestCaseStatus.blocked).length;
    final untestedCount = suiteCases.where((c) => c.status == TestCaseStatus.untested).length;
    final passRate = totalCount == 0 ? 0.0 : (passedCount / totalCount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          AppLogger.info('TestSuiteDetailScreen', 'Navigating back to /test-suites');
                          context.go('/test-suites');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                              const SizedBox(width: 6),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.folder_special_rounded, color: AppColors.secondary, size: 20),
                                ),
                                Text(
                                  activeSuite.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Build: ${activeSuite.buildName}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                                    'Version: ${activeSuite.version}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeSuite.description.isNotEmpty
                                  ? activeSuite.description
                                  : 'Suite test scenario management and execution repository',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Toolbar action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showImportCSVDialog(context),
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('Import CSV', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportToCSV(context, suiteCases),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _syncAndSaveSuiteMetrics(context, suiteCases),
                      icon: const Icon(Icons.folder_special_rounded, size: 16),
                      label: const Text('Save to Test Suite', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (suiteCases.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _showClearSuiteCasesDialog(context, suiteCases),
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.failed),
                        label: const Text('Clear All', style: TextStyle(color: AppColors.failed, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          side: const BorderSide(color: AppColors.failed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditTestCaseDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Test Case', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Summary Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  return Column(
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildStatBadge('Total Cases', '$totalCount', AppColors.primary, isDark),
                          _buildStatBadge('Passed', '$passedCount', AppColors.passed, isDark),
                          _buildStatBadge('Failed', '$failedCount', AppColors.failed, isDark),
                          _buildStatBadge('Blocked', '$blockedCount', AppColors.blocked, isDark),
                          _buildStatBadge('Untested', '$untestedCount', Colors.orange, isDark),
                          if (!isNarrow)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Pass Rate: ', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                                Text(
                                  '${(passRate * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.passed),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: passRate,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                          color: AppColors.passed,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Search & Filter Bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      hintText: 'Search by TC ID, Module, Feature, Title, or Tester...',
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (modules.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedModuleFilter,
                        icon: const Icon(Icons.folder_outlined, size: 18),
                        hint: const Text('Module'),
                        items: modules.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m == 'All' ? 'All Modules' : m, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedModuleFilter = val);
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedStatusFilter = status);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Test Cases List
            Expanded(
              child: filteredCases.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 16),
                            Text(
                              suiteCases.isEmpty
                                  ? 'No test cases in "${_currentSuite.name}" yet'
                                  : 'No test cases match your filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              suiteCases.isEmpty
                                  ? 'Use "Import CSV" or "Add Test Case" to add test cases directly to this suite.'
                                  : 'Try adjusting your search query or status filter.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (suiteCases.isEmpty) ...[
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showImportCSVDialog(context),
                                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                                    label: const Text('Import CSV to Suite'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _showAddOrEditTestCaseDialog(context),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Single Test Case'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCases.length,
                      itemBuilder: (context, index) {
                        final tc = filteredCases[index];
                        return _buildTestCaseCard(context, tc, index, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTestCaseCard(BuildContext context, TestCaseModel tc, int index, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    switch (tc.status) {
      case TestCaseStatus.passed:
        statusColor = AppColors.passed;
        statusIcon = Icons.check_circle_rounded;
        break;
      case TestCaseStatus.failed:
        statusColor = AppColors.failed;
        statusIcon = Icons.cancel_rounded;
        break;
      case TestCaseStatus.blocked:
        statusColor = AppColors.blocked;
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.help_outline_rounded;
    }

    Color priorityColor;
    switch (tc.priority) {
      case TestCasePriority.critical:
        priorityColor = Colors.purpleAccent;
        break;
      case TestCasePriority.high:
        priorityColor = const Color(0xFFEF4444);
        break;
      case TestCasePriority.medium:
        priorityColor = const Color(0xFFF59E0B);
        break;
      case TestCasePriority.low:
        priorityColor = const Color(0xFF10B981);
        break;
    }

    final isExpanded = _expandedCaseIds.contains(tc.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E).withValues(alpha: 0.85) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCaseIds.remove(tc.id);
                } else {
                  _expandedCaseIds.add(tc.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  // TC_ID Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          tc.code.isNotEmpty ? tc.code : "TC-${index + 1}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tc.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (tc.module.isNotEmpty)
                              _buildMiniBadge(Icons.folder_outlined, 'Module: ${tc.module}', isDark),
                            if (tc.feature.isNotEmpty)
                              _buildMiniBadge(Icons.layers_outlined, 'Feature: ${tc.feature}', isDark),
                            if (tc.assignedTo.isNotEmpty)
                              _buildMiniBadge(Icons.person_outline_rounded, 'Tester: ${tc.assignedTo}', isDark),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    tc.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  _buildSuiteCardAction(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copy TC ID',
                    color: isDark ? Colors.white70 : Colors.black54,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: tc.code.isNotEmpty ? tc.code : tc.title));
                      ToastUtils.showInfo(context, 'Copied "${tc.code}" to clipboard');
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildSuiteCardAction(
                    icon: Icons.edit_rounded,
                    tooltip: 'Edit Test Case',
                    color: AppColors.primary,
                    onTap: () => _showAddOrEditTestCaseDialog(context, existingCase: tc),
                  ),
                  const SizedBox(width: 4),
                  _buildSuiteCardAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete Test Case',
                    color: AppColors.failed,
                    onTap: () => _showDeleteConfirmDialog(context, tc),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details Section
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  // Metadata Grid Chips
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildModernMetaChip(Icons.flag_rounded, 'Priority', tc.priority.name.toUpperCase(), priorityColor, isDark),
                      if (tc.module.isNotEmpty)
                        _buildModernMetaChip(Icons.category_rounded, 'Module', tc.module, AppColors.primary, isDark),
                      if (tc.feature.isNotEmpty)
                        _buildModernMetaChip(Icons.auto_awesome_rounded, 'Feature', tc.feature, AppColors.secondary, isDark),
                      if (tc.assignedTo.isNotEmpty)
                        _buildModernMetaChip(Icons.badge_rounded, 'Tester', tc.assignedTo, Colors.tealAccent, isDark),
                      if (tc.type.isNotEmpty)
                        _buildModernMetaChip(Icons.label_outline_rounded, 'Type', tc.type, Colors.cyan, isDark),
                      if (tc.preconditions.isNotEmpty)
                        _buildModernMetaChip(Icons.vpn_key_rounded, 'Preconditions', tc.preconditions, Colors.amber, isDark),
                      if (tc.testData.isNotEmpty)
                        _buildModernMetaChip(Icons.data_object_rounded, 'Test Data', tc.testData, Colors.cyanAccent, isDark),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Steps
                  Row(
                    children: [
                      const Icon(Icons.format_list_numbered_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Test Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.3,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (tc.steps.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Text(
                        'No specific step-by-step instructions provided for this scenario.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    )
                  else
                    ...tc.steps.asMap().entries.map((entry) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),

                  // Expected & Actual Results Comparison Panels
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      final expectedCard = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.passed.withValues(alpha: isDark ? 0.08 : 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.passed.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.passed),
                                const SizedBox(width: 6),
                                const Text(
                                  'Expected Result',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.4,
                                    color: AppColors.passed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tc.expectedResult.isNotEmpty ? tc.expectedResult : 'Scenario should pass successfully according to acceptance criteria.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      );

                      final actualColor = tc.status == TestCaseStatus.failed ? AppColors.failed : AppColors.primary;
                      final actualCard = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: actualColor.withValues(alpha: isDark ? 0.08 : 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: actualColor.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tc.status == TestCaseStatus.failed ? Icons.error_outline_rounded : Icons.task_alt_rounded,
                                  size: 16,
                                  color: actualColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Actual Result',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.4,
                                    color: actualColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tc.actualResult.isNotEmpty
                                  ? tc.actualResult
                                  : (tc.expectedResult.isNotEmpty ? tc.expectedResult : 'Matches expected criteria during test run.'),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            expectedCard,
                            const SizedBox(height: 12),
                            actualCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: expectedCard),
                          const SizedBox(width: 14),
                          Expanded(child: actualCard),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildMiniBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white60 : Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuiteCardAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildModernMetaChip(IconData icon, String label, String value, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }



  // Sync & Save suite metrics
  Future<void> _syncAndSaveSuiteMetrics(BuildContext context, List<TestCaseModel> suiteCases) async {
    AppLogger.info('TestSuiteDetailScreen', 'Syncing suite "${_currentSuite.name}" with ${suiteCases.length} cases...');
    final suiteProvider = Provider.of<TestSuiteProvider>(context, listen: false);
    final total = suiteCases.length;
    final passed = suiteCases.where((tc) => tc.status == TestCaseStatus.passed).length;
    final failed = suiteCases.where((tc) => tc.status == TestCaseStatus.failed).length;
    final blocked = suiteCases.where((tc) => tc.status == TestCaseStatus.blocked).length;

    final updated = _currentSuite.copyWith(
      totalCases: total,
      passedCases: passed,
      failedCases: failed,
      blockedCases: blocked,
    );

    await suiteProvider.updateTestSuite(updated);
    setState(() => _currentSuite = updated);

    AppLogger.success(
      'TestSuiteDetailScreen',
      'Successfully synced "${_currentSuite.name}": total=$total, passed=$passed, failed=$failed, blocked=$blocked',
    );

    if (context.mounted) {
      ToastUtils.showSuccess(context, 'Suite "${_currentSuite.name}" synced! ($total cases, $passed passed)');
    }
  }

  // Clear all cases from suite
  void _showClearSuiteCasesDialog(BuildContext context, List<TestCaseModel> suiteCases) {
    final tcProvider = Provider.of<TestCaseProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Cases from "${_currentSuite.name}"?'),
        content: Text(
          'This will unlink all ${suiteCases.length} test cases from this test suite. You can choose to remove them from this suite or delete them entirely.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              AppLogger.warn('TestSuiteDetailScreen', 'Unlinking ${suiteCases.length} cases from "${_currentSuite.name}"');
              // Unlink from this suite
              final updated = tcProvider.testCases.map((tc) {
                if (tc.suiteId == _currentSuite.id || tc.suiteName == _currentSuite.name) {
                  return tc.copyWith(suiteId: '', suiteName: '');
                }
                return tc;
              }).toList();
              await tcProvider.updateTestCasesBatch(updated);
              if (context.mounted) {
                await _syncAndSaveSuiteMetrics(context, []);
                ToastUtils.showInfo(context, 'Unlinked cases from "${_currentSuite.name}"');
              }
            },
            child: const Text('Unlink from Suite'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.failed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              AppLogger.warn('TestSuiteDetailScreen', 'Permanently deleting ${suiteCases.length} cases from "${_currentSuite.name}"');
              for (final tc in suiteCases) {
                await tcProvider.deleteTestCase(tc.id);
              }
              if (context.mounted) {
                await _syncAndSaveSuiteMetrics(context, []);
                ToastUtils.showSuccess(context, 'Deleted ${suiteCases.length} cases from suite');
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // Delete single test case
  void _showDeleteConfirmDialog(BuildContext context, TestCaseModel tc) {
    final tcProvider = Provider.of<TestCaseProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${tc.code.isNotEmpty ? tc.code : tc.title}"?'),
        content: const Text('Are you sure you want to delete this test case?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.failed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              AppLogger.warn('TestSuiteDetailScreen', 'Deleting test case: ${tc.code} (${tc.id}) from "${_currentSuite.name}"');
              await tcProvider.deleteTestCase(tc.id);
              if (context.mounted) {
                ToastUtils.showSuccess(context, 'Test case deleted.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Add or Edit Test Case (Preset to current suite)
  void _showAddOrEditTestCaseDialog(BuildContext context, {TestCaseModel? existingCase}) {
    final isEdit = existingCase != null;
    final tcIdController = TextEditingController(text: isEdit ? existingCase.code : '');
    final moduleController = TextEditingController(text: isEdit ? existingCase.module : '');
    final featureController = TextEditingController(text: isEdit ? existingCase.feature : '');
    final scenarioController = TextEditingController(text: isEdit ? existingCase.title : '');
    final preconditionsController = TextEditingController(text: isEdit ? existingCase.preconditions : '');
    final stepsController = TextEditingController(text: isEdit ? existingCase.steps.join('\n') : '');
    final testDataController = TextEditingController(text: isEdit ? existingCase.testData : '');
    final expectedController = TextEditingController(text: isEdit ? existingCase.expectedResult : '');
    final actualController = TextEditingController(text: isEdit ? existingCase.actualResult : '');
    final testerController = TextEditingController(text: isEdit ? existingCase.assignedTo : '');
    final remarksController = TextEditingController(text: isEdit ? existingCase.remarks : '');

    TestCaseStatus status = isEdit ? existingCase.status : TestCaseStatus.untested;
    TestCasePriority priority = isEdit ? existingCase.priority : TestCasePriority.medium;
    DateTime? selectedExecutionDate = isEdit ? existingCase.executionDate : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Test Case' : 'Add Test Case to "${_currentSuite.name}"'),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tcIdController,
                              decoration: const InputDecoration(labelText: 'TC_ID', hintText: 'e.g. TC-101'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: moduleController,
                              decoration: const InputDecoration(labelText: 'Module', hintText: 'e.g. Authentication'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: featureController,
                              decoration: const InputDecoration(labelText: 'Feature', hintText: 'e.g. User Login'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: testerController,
                              decoration: const InputDecoration(labelText: 'Tester / Assignee'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: scenarioController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Test Scenario / Title *'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TestCaseStatus>(
                              value: status,
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: TestCaseStatus.values.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => status = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<TestCasePriority>(
                              value: priority,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              items: TestCasePriority.values.map((p) {
                                return DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => priority = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: preconditionsController,
                        decoration: const InputDecoration(labelText: 'Preconditions'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: stepsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Test Steps (one per line)',
                          hintText: '1. Navigate to page\n2. Fill username\n3. Click Submit',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: testDataController,
                        decoration: const InputDecoration(labelText: 'Test Data'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: expectedController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Expected Result'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: actualController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Actual Result'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(labelText: 'Remarks'),
                      ),
                      const SizedBox(height: 12),
                      // Execution Date Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedExecutionDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedExecutionDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Execution Date',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedExecutionDate != null
                                    ? '${selectedExecutionDate!.day.toString().padLeft(2, '0')} / '
                                      '${selectedExecutionDate!.month.toString().padLeft(2, '0')} / '
                                      '${selectedExecutionDate!.year}'
                                    : 'Tap to select a date',
                                style: TextStyle(
                                  color: selectedExecutionDate != null ? null : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (scenarioController.text.trim().isEmpty) {
                      ToastUtils.showError(context, 'Test Scenario / Title is required');
                      return;
                    }

                    final steps = stepsController.text
                        .split('\n')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final tcProvider = Provider.of<TestCaseProvider>(context, listen: false);

                    if (isEdit) {
                      AppLogger.info('TestSuiteDetailScreen', 'Updating test case: ${existingCase.code} in "${_currentSuite.name}"');
                      final updated = existingCase.copyWith(
                        code: tcIdController.text.trim(),
                        module: moduleController.text.trim(),
                        feature: featureController.text.trim(),
                        title: scenarioController.text.trim(),
                        status: status,
                        priority: priority,
                        preconditions: preconditionsController.text.trim(),
                        steps: steps,
                        testData: testDataController.text.trim(),
                        expectedResult: expectedController.text.trim(),
                        actualResult: actualController.text.trim(),
                        assignedTo: testerController.text.trim(),
                        remarks: remarksController.text.trim(),
                        executionDate: selectedExecutionDate,
                        suiteId: _currentSuite.id,
                        suiteName: _currentSuite.name,
                      );
                      await tcProvider.updateTestCase(updated);
                      AppLogger.success('TestSuiteDetailScreen', 'Test case ${updated.code} updated successfully');
                      if (context.mounted) {
                        ToastUtils.showSuccess(context, 'Test case updated');
                        Navigator.pop(context);
                      }
                    } else {
                      final newCase = TestCaseModel(
                        id: const Uuid().v4(),
                        code: tcIdController.text.trim().isNotEmpty
                            ? tcIdController.text.trim()
                            : 'TC-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        title: scenarioController.text.trim(),
                        description: '',
                        module: moduleController.text.trim(),
                        feature: featureController.text.trim(),
                        status: status,
                        priority: priority,
                        type: 'Functional',
                        assignedTo: testerController.text.trim().isNotEmpty ? testerController.text.trim() : (Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Team Member'),
                        createdBy: Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Team Member',
                        updatedAt: DateTime.now(),
                        steps: steps,
                        preconditions: preconditionsController.text.trim(),
                        testData: testDataController.text.trim(),
                        expectedResult: expectedController.text.trim(),
                        actualResult: actualController.text.trim(),
                        remarks: remarksController.text.trim(),
                        executionDate: selectedExecutionDate,
                        suiteId: _currentSuite.id,
                        suiteName: _currentSuite.name,
                      );
                      AppLogger.info('TestSuiteDetailScreen', 'Adding new test case: ${newCase.code} to "${_currentSuite.name}"');
                      await tcProvider.addTestCase(newCase);
                      AppLogger.success('TestSuiteDetailScreen', 'Test case ${newCase.code} added successfully');
                      if (context.mounted) {
                        ToastUtils.showSuccess(context, 'Test case added to "${_currentSuite.name}"');
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Add Test Case'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Import CSV specifically into this suite
  void _showImportCSVDialog(BuildContext context) {
    final currentUserName = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Team Member';
    final csvController = TextEditingController();
    int activeTab = 0;
    String selectedFileName = '';
    List<TestCaseModel> parsedCases = [];

    void updateParsedCases(String text) {
      parsedCases = _parseCSVOrTSVText(text, uploaderName: currentUserName);
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Import CSV to "${_currentSuite.name}"'),
                ],
              ),
              content: SizedBox(
                width: 780,
                height: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab Bar
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => activeTab = 0),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: activeTab == 0 ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.attach_file_rounded,
                                          size: 18,
                                          color: activeTab == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Select & Upload File (.csv / .tsv)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: activeTab == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => activeTab = 1),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: activeTab == 1 ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.content_paste_rounded,
                                          size: 18,
                                          color: activeTab == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Copy & Paste Text / Excel Rows',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: activeTab == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (activeTab == 0)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _pickAndReadFile((text, filename) {
                                csvController.text = text;
                                setDialogState(() {
                                  selectedFileName = filename;
                                  parsedCases = _parseCSVOrTSVText(text, uploaderName: currentUserName);
                                });
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.drive_folder_upload_rounded, size: 44, color: AppColors.primary),
                                  const SizedBox(height: 10),
                                  Text(
                                    selectedFileName.isNotEmpty
                                        ? 'Selected File: $selectedFileName'
                                        : 'Click here to choose file from your computer',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: selectedFileName.isNotEmpty ? AppColors.passed : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Supports CSV (.csv), TSV (.tsv), and Text (.txt) files',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        TextField(
                          controller: csvController,
                          maxLines: 6,
                          onChanged: (text) => setDialogState(() => updateParsedCases(text)),
                          decoration: InputDecoration(
                            hintText: 'Paste Excel rows or CSV text here...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Parsed Preview (${parsedCases.length} Test Cases):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (parsedCases.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.passed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${parsedCases.length} Ready to Import',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.passed),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (parsedCases.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('Upload a CSV file or paste content to preview parsed test cases.'),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: parsedCases.length > 5 ? 5 : parsedCases.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final tc = parsedCases[idx];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tc.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                                title: Text(tc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text('${tc.module} • ${tc.feature}', style: const TextStyle(fontSize: 11)),
                                trailing: Text(tc.status.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_done_rounded, size: 18),
                  label: Text('Import ${parsedCases.length} Cases to "${_currentSuite.name}"'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: parsedCases.isEmpty
                      ? null
                      : () async {
                          AppLogger.info('TestSuiteDetailScreen', 'Importing ${parsedCases.length} parsed test cases to "${_currentSuite.name}"');
                          final tcProvider = Provider.of<TestCaseProvider>(context, listen: false);
                          // Assign all imported cases to this suite
                          final boundCases = parsedCases
                              .map((tc) => tc.copyWith(suiteId: _currentSuite.id, suiteName: _currentSuite.name))
                              .toList();

                          await tcProvider.addTestCasesBatch(boundCases);
                          AppLogger.success('TestSuiteDetailScreen', 'Batch imported ${boundCases.length} test cases to "${_currentSuite.name}"');
                          if (context.mounted) {
                            Navigator.pop(context);
                            ToastUtils.showSuccess(
                              context,
                              'Successfully imported ${boundCases.length} test cases to "${_currentSuite.name}"!',
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _pickAndReadFile(Function(String text, String filename) onLoaded) {
    final uploadInput = html.FileUploadInputElement()..accept = '.csv,.tsv,.txt';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          if (reader.result != null) {
            onLoaded(reader.result as String, file.name);
          }
        });
        reader.readAsText(file);
      }
    });
  }

  List<TestCaseModel> _parseCSVOrTSVText(String text, {String uploaderName = 'QA Team Member'}) {
    if (text.trim().isEmpty) return [];

    final rawLines = const LineSplitter().convert(text);
    final lines = rawLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return [];

    final delimiter = lines.first.contains('\t') ? '\t' : ',';
    final headerRow = _splitLineWithQuotes(lines.first, delimiter);
    final headerMap = <String, int>{};
    for (int i = 0; i < headerRow.length; i++) {
      headerMap[headerRow[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')] = i;
    }

    int? getColIndex(List<String> keys) {
      for (final key in keys) {
        final sanitized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (headerMap.containsKey(sanitized)) return headerMap[sanitized];
      }
      return null;
    }

    final tcIdIdx = getColIndex(['tcid', 'tc_id', 'id', 'testcaseid', 'code', 'key']);
    final moduleIdx = getColIndex(['module', 'modulename', 'component', 'section']);
    final featureIdx = getColIndex(['feature', 'featurename', 'submodule', 'story']);
    final titleIdx = getColIndex(['testscenario', 'scenario', 'title', 'testcasetitle', 'summary', 'name', 'description']);
    final precondIdx = getColIndex(['preconditions', 'precondition', 'prerequisite']);
    final stepsIdx = getColIndex(['teststeps', 'steps', 'stepstoexecute', 'action']);
    final testDataIdx = getColIndex(['testdata', 'data', 'inputdata', 'inputs']);
    final expectedIdx = getColIndex(['expectedresult', 'expectedresults', 'expected', 'acceptancecriteria']);
    final actualIdx = getColIndex(['actualresult', 'actualresults', 'actual']);
    final statusIdx = getColIndex(['status', 'state', 'result', 'teststatus', 'executionstatus']);
    final priorityIdx = getColIndex(['priority', 'severity', 'prio']);
    final testerIdx = getColIndex(['tester', 'assignedto', 'testername', 'assignee', 'author', 'createdby']);
    final remarksIdx = getColIndex(['remarks', 'comments', 'notes', 'remark']);

    final List<TestCaseModel> result = [];
    final startIndex = headerMap.isNotEmpty ? 1 : 0;

    for (int i = startIndex; i < lines.length; i++) {
      final cols = _splitLineWithQuotes(lines[i], delimiter);
      if (cols.isEmpty) continue;

      String getVal(int? idx, {String fallback = ''}) {
        if (idx == null || idx >= cols.length) return fallback;
        return cols[idx].replaceAll('""', '"').trim();
      }

      final title = getVal(titleIdx, fallback: cols.isNotEmpty ? cols[0] : 'Imported Scenario #$i');
      if (title.isEmpty || title.toLowerCase() == 'test scenario' || title.toLowerCase() == 'title') continue;

      final statusStr = getVal(statusIdx, fallback: 'untested').toLowerCase();
      TestCaseStatus status = TestCaseStatus.untested;
      if (statusStr.contains('pass')) {
        status = TestCaseStatus.passed;
      } else if (statusStr.contains('fail')) {
        status = TestCaseStatus.failed;
      } else if (statusStr.contains('block')) {
        status = TestCaseStatus.blocked;
      }

      final prioStr = getVal(priorityIdx, fallback: 'medium').toLowerCase();
      TestCasePriority priority = TestCasePriority.medium;
      if (prioStr.contains('high') || prioStr.contains('critical') || prioStr.contains('p1')) {
        priority = TestCasePriority.high;
      } else if (prioStr.contains('low') || prioStr.contains('p3')) {
        priority = TestCasePriority.low;
      }

      final rawSteps = getVal(stepsIdx);
      final steps = rawSteps.isNotEmpty
          ? rawSteps.split(RegExp(r'\r?\n|;')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];

      String testerVal = getVal(testerIdx, fallback: uploaderName);
      if (testerVal.isEmpty || RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$').hasMatch(testerVal)) {
        testerVal = uploaderName;
      }

      result.add(TestCaseModel(
        id: const Uuid().v4(),
        code: getVal(tcIdIdx, fallback: 'TC-${i + 1}'),
        title: title,
        description: '',
        module: getVal(moduleIdx, fallback: 'General'),
        feature: getVal(featureIdx, fallback: 'Core Feature'),
        status: status,
        priority: priority,
        type: 'Functional',
        assignedTo: testerVal,
        createdBy: uploaderName,
        updatedAt: DateTime.now(),
        steps: steps,
        preconditions: getVal(precondIdx),
        testData: getVal(testDataIdx),
        expectedResult: getVal(expectedIdx),
        actualResult: getVal(actualIdx),
        remarks: getVal(remarksIdx),
        suiteId: _currentSuite.id,
        suiteName: _currentSuite.name,
      ));
    }

    return result;
  }

  static List<String> _splitLineWithQuotes(String line, String delimiter) {
    final List<String> result = [];
    final StringBuffer sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }

  void _exportToCSV(BuildContext context, List<TestCaseModel> cases) {
    if (cases.isEmpty) {
      ToastUtils.showError(context, 'No test cases to export.');
      return;
    }

    final headers = [
      'TC_ID',
      'Module',
      'Feature',
      'Test Scenario',
      'Status',
      'Priority',
      'Preconditions',
      'Test Steps',
      'Test Data',
      'Expected Result',
      'Actual Result',
      'Tester',
      'Remarks',
      'Suite Name',
    ];

    String escapeCsv(String value) {
      if (value.contains(',') || value.contains('"') || value.contains('\n')) {
        return '"${value.replaceAll('"', '""')}"';
      }
      return value;
    }

    final rows = cases.map((tc) {
      return [
        escapeCsv(tc.code),
        escapeCsv(tc.module),
        escapeCsv(tc.feature),
        escapeCsv(tc.title),
        escapeCsv(tc.status.name.toUpperCase()),
        escapeCsv(tc.priority.name.toUpperCase()),
        escapeCsv(tc.preconditions),
        escapeCsv(tc.steps.join('; ')),
        escapeCsv(tc.testData),
        escapeCsv(tc.expectedResult),
        escapeCsv(tc.actualResult),
        escapeCsv(tc.assignedTo),
        escapeCsv(tc.remarks),
        escapeCsv(tc.suiteName),
      ].join(',');
    }).toList();

    final csvContent = '${headers.join(',')}\n${rows.join('\n')}';
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        '${_currentSuite.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_test_cases_${DateTime.now().millisecondsSinceEpoch}.csv',
      )
      ..click();
    html.Url.revokeObjectUrl(url);

    AppLogger.success('TestSuiteDetailScreen', 'Exported ${cases.length} test cases for suite "${_currentSuite.name}" to CSV file');
    ToastUtils.showSuccess(context, 'Exported ${cases.length} test cases for "${_currentSuite.name}" to CSV!');
  }
}
