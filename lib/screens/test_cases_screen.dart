import 'dart:convert';
import 'dart:html' as html;

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
import '../utils/app_logger.dart';
import '../utils/toast_utils.dart';

class TestCasesScreen extends StatefulWidget {
  const TestCasesScreen({super.key});

  @override
  State<TestCasesScreen> createState() => _TestCasesScreenState();
}

class _TestCasesScreenState extends State<TestCasesScreen> {
  String _scopeFilter = 'All'; // 'Unassigned' (Inbox) or 'All'
  final Set<String> _expandedCaseIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestCaseProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filterOptions = ['All', 'Passed', 'Failed', 'Blocked', 'Untested'];

    // Filter by scope
    final allFiltered = provider.testCases;
    // 'Unassigned' = cases not yet moved to any real suite (suiteId is blank)
    final unassignedCases =
        allFiltered.where((tc) => tc.suiteId.isEmpty).toList();
    final displayedCases =
        _scopeFilter == 'Unassigned' ? unassignedCases : allFiltered;

    final unassignedTotalCount =
        provider.allRawCases.where((tc) => tc.suiteId.isEmpty).length;
    final allTotalCount = provider.allRawCases.length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Case Repository',
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
                      'Staging inbox to create, import, inspect, and organize test scenarios into Test Suites',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showImportCSVDialog(context),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Import CSV'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportToCSV(context, displayedCases),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (displayedCases.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showSaveToTestSuiteDialog(context, displayedCases),
                      icon: const Icon(Icons.folder_special_rounded, size: 18),
                      label: const Text('Save to Test Suite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  if (displayedCases.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                                'Clear ${_scopeFilter == 'Unassigned' ? 'Unassigned' : 'All'} Test Cases?'),
                            content: const Text(
                                'This will delete the selected test cases. This action cannot be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.failed,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  if (_scopeFilter == 'Unassigned') {
                                    for (final tc in unassignedCases) {
                                      provider.deleteTestCase(tc.id);
                                    }
                                  } else {
                                    provider.clearAllTestCases();
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 18, color: AppColors.failed),
                      label: const Text('Clear All',
                          style: TextStyle(color: AppColors.failed)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        side: const BorderSide(color: AppColors.failed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditTestCaseDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Test Case'),
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
          const SizedBox(height: 20),

          // Scope Selector + Search and Filter Bar
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [
              // Scope Segmented Buttons
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _scopeFilter = 'Unassigned'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _scopeFilter == 'Unassigned'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 16,
                              color: _scopeFilter == 'Unassigned'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Staging Inbox ($unassignedTotalCount)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _scopeFilter == 'Unassigned'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scopeFilter == 'Unassigned'
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _scopeFilter = 'All'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _scopeFilter == 'All'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_copy_rounded,
                              size: 16,
                              color: _scopeFilter == 'All'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'All Test Cases ($allTotalCount)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _scopeFilter == 'All'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scopeFilter == 'All'
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Box
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 260, maxWidth: 450),
                child: TextField(
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    hintText:
                        'Search by TC ID, Module, Feature, Title, or Tester...',
                    isDense: true,
                  ),
                ),
              ),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: filterOptions.map((status) {
                    final isSelected = provider.selectedStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) provider.setStatusFilter(status);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Expand / Collapse All Toggle
              if (displayedCases.isNotEmpty)
                () {
                  final isAllExpanded = displayedCases
                      .every((tc) => _expandedCaseIds.contains(tc.id));
                  return TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isAllExpanded) {
                          for (final tc in displayedCases) {
                            _expandedCaseIds.remove(tc.id);
                          }
                        } else {
                          for (final tc in displayedCases) {
                            _expandedCaseIds.add(tc.id);
                          }
                        }
                      });
                    },
                    icon: Icon(
                      isAllExpanded
                          ? Icons.unfold_less_rounded
                          : Icons.unfold_more_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isAllExpanded ? 'Collapse All' : 'Expand All',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                }(),
            ],
          ),
          const SizedBox(height: 20),

          // Test Cases List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedCases.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _scopeFilter == 'Unassigned'
                                    ? Icons.task_alt_rounded
                                    : Icons.folder_open_rounded,
                                size: 64,
                                color: _scopeFilter == 'Unassigned'
                                    ? AppColors.passed
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.black26),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _scopeFilter == 'Unassigned'
                                    ? 'Staging Inbox is Clear!'
                                    : 'No Test Cases Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _scopeFilter == 'Unassigned'
                                    ? 'All test cases have been organized and saved into Test Suites.'
                                    : 'Import a CSV file or add a new test case to get started.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_scopeFilter == 'Unassigned')
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.folder_special_rounded,
                                          size: 18),
                                      label: const Text('View Test Suites'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          context.go('/test-suites'),
                                    ),
                                  if (_scopeFilter == 'Unassigned')
                                    const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.file_upload_outlined,
                                        size: 18),
                                    label: const Text('Import CSV'),
                                    onPressed: () =>
                                        _showImportCSVDialog(context),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Test Case'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        _showAddOrEditTestCaseDialog(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedCases.length,
                        itemBuilder: (context, index) {
                          final tc = displayedCases[index];
                          return _buildTestCaseCard(context, tc, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCaseCard(
      BuildContext context, TestCaseModel tc, bool isDark) {
    Color statusColor;
    switch (tc.status) {
      case TestCaseStatus.passed:
        statusColor = AppColors.passed;
        break;
      case TestCaseStatus.failed:
        statusColor = AppColors.failed;
        break;
      case TestCaseStatus.blocked:
        statusColor = AppColors.blocked;
        break;
      default:
        statusColor = AppColors.untested;
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
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);
    final labelColor = isDark ? Colors.white54 : Colors.black45;
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subBg =
        isDark ? Colors.black.withValues(alpha: 0.18) : const Color(0xFFF8FAFC);

    String displayCode = tc.code.trim();
    String displayTitle = tc.title.trim();

    // Auto-repair corrupt code fields that absorbed comma-separated rows or sentence text
    if (displayCode.contains(',') ||
        displayCode.length > 25 ||
        displayCode.trim().contains(' ')) {
      if (displayTitle.isEmpty ||
          displayTitle.startsWith('Imported Test Case')) {
        displayTitle = displayCode.split(',').first.trim();
      }
      final shortId =
          tc.id.length >= 4 ? tc.id.substring(0, 4).toUpperCase() : '100';
      displayCode = 'TC-$shortId';
    }

    if (displayCode.isEmpty) {
      final shortId =
          tc.id.length >= 4 ? tc.id.substring(0, 4).toUpperCase() : '100';
      displayCode = 'TC-$shortId';
    }

    if (displayTitle.isEmpty) {
      if (tc.description.trim().isNotEmpty) {
        displayTitle = tc.description.trim();
      } else if (tc.module.trim().isNotEmpty && tc.feature.trim().isNotEmpty) {
        displayTitle = '${tc.module} - ${tc.feature} Scenario';
      } else {
        displayTitle = 'Test Scenario ($displayCode)';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // Header row
                InkWell(
                  onTap: () => setState(() {
                    isExpanded
                        ? _expandedCaseIds.remove(tc.id)
                        : _expandedCaseIds.add(tc.id);
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // TC_ID (Clean badge, constrained width)
                        Container(
                          constraints:
                              const BoxConstraints(minWidth: 80, maxWidth: 140),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            displayCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.4,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: valueColor),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (tc.module.isNotEmpty)
                                    _chip('Module: ${tc.module}', labelColor,
                                        isDark),
                                  if (tc.feature.isNotEmpty)
                                    _chip('Feature: ${tc.feature}', labelColor,
                                        isDark),
                                  if (tc.assignedTo.isNotEmpty)
                                    _chip('Tester: ${tc.assignedTo}',
                                        labelColor, isDark),
                                  if (tc.suiteName.isNotEmpty)
                                    _chip(tc.suiteName, AppColors.secondary,
                                        isDark,
                                        colored: true,
                                        accent: AppColors.secondary),
                                  _chip(tc.status.name.toUpperCase(),
                                      statusColor, isDark,
                                      colored: true, accent: statusColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _iconBtn(
                            icon: Icons.copy_rounded,
                            color: isDark ? Colors.white54 : Colors.black38,
                            tooltip: 'Duplicate',
                            onTap: () async {
                              final dup = tc.copyWith(
                                  id: const Uuid().v4(),
                                  code: '${tc.code}-COPY',
                                  title: '${tc.title} (Copy)',
                                  updatedAt: DateTime.now());
                              await Provider.of<TestCaseProvider>(context,
                                      listen: false)
                                  .addTestCase(dup);
                              if (context.mounted)
                                ToastUtils.showSuccess(context, 'Duplicated!');
                            }),
                        const SizedBox(width: 4),
                        _iconBtn(
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            tooltip: 'Edit',
                            onTap: () => _showAddOrEditTestCaseDialog(context,
                                existingCase: tc)),
                        const SizedBox(width: 4),
                        _iconBtn(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.failed,
                            tooltip: 'Delete',
                            onTap: () async {
                              await Provider.of<TestCaseProvider>(context,
                                      listen: false)
                                  .deleteTestCase(tc.id);
                              if (context.mounted)
                                ToastUtils.showSuccess(
                                    context, '${tc.code} deleted');
                            }),
                        const SizedBox(width: 6),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded detail panel
                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: subBg,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 24, color: borderColor),
                        // Metadata chips — no icons, plain label + value
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _metaChip(
                                'Priority',
                                tc.priority.name.toUpperCase(),
                                priorityColor,
                                isDark),
                            if (tc.module.isNotEmpty)
                              _metaChip(
                                  'Module', tc.module, labelColor, isDark),
                            if (tc.feature.isNotEmpty)
                              _metaChip(
                                  'Feature', tc.feature, labelColor, isDark),
                            if (tc.assignedTo.isNotEmpty)
                              _metaChip(
                                  'Tester', tc.assignedTo, labelColor, isDark),
                            if (tc.executionDate != null)
                              _metaChip(
                                  'Execution Date',
                                  '${tc.executionDate!.day}-${tc.executionDate!.month}-${tc.executionDate!.year}',
                                  labelColor,
                                  isDark),
                            if (tc.preconditions.isNotEmpty &&
                                tc.preconditions.toLowerCase() != 'none' &&
                                tc.preconditions.toLowerCase() != 'n/a')
                              _metaChip('Preconditions', tc.preconditions,
                                  labelColor, isDark),
                            if (tc.testData.isNotEmpty &&
                                tc.testData.toLowerCase() != 'n/a')
                              _metaChip(
                                  'Test Data', tc.testData, labelColor, isDark),
                            if (tc.remarks.isNotEmpty &&
                                tc.remarks.toLowerCase() != 'n/a')
                              _metaChip(
                                  'Remarks', tc.remarks, labelColor, isDark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Test Steps
                        Text('Test Steps',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.3,
                                color: labelColor)),
                        const SizedBox(height: 6),
                        if (tc.steps.isEmpty)
                          Text('—',
                              style: TextStyle(fontSize: 13, color: labelColor))
                        else
                          ...tc.steps.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${e.key + 1}.',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(e.value,
                                            style: TextStyle(
                                                fontSize: 13,
                                                height: 1.45,
                                                color: valueColor))),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 14),
                        // Expected / Actual panels
                        LayoutBuilder(
                          builder: (ctx, con) {
                            final narrow = con.maxWidth < 560;
                            final expPanel = _resultPanel(
                              label: 'Expected Result',
                              value: tc.expectedResult.isNotEmpty
                                  ? tc.expectedResult
                                  : '—',
                              accent: AppColors.passed,
                              isDark: isDark,
                              valueColor: valueColor,
                            );
                            final actPanel = _resultPanel(
                              label: 'Actual Result',
                              value: (tc.actualResult.isNotEmpty &&
                                      tc.actualResult.toLowerCase() != 'n/a')
                                  ? tc.actualResult
                                  : '—',
                              accent: tc.status == TestCaseStatus.failed
                                  ? AppColors.failed
                                  : AppColors.primary,
                              isDark: isDark,
                              valueColor: valueColor,
                            );
                            return narrow
                                ? Column(children: [
                                    expPanel,
                                    const SizedBox(height: 10),
                                    actPanel
                                  ])
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: expPanel),
                                      const SizedBox(width: 12),
                                      Expanded(child: actPanel),
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
        ],
      ),
    );
  }

  // Plain text chip â€” no icon
  Widget _chip(String label, Color color, bool isDark,
      {bool colored = false, Color? accent}) {
    final bg = colored
        ? (accent ?? color).withValues(alpha: 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04));
    final border = colored
        ? (accent ?? color).withValues(alpha: 0.35)
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.07));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: border)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colored ? (accent ?? color) : color)),
    );
  }

  // Label + bold value chip â€” no icon
  Widget _metaChip(String label, String value, Color labelColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$label  ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: labelColor)),
          TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ]),
      ),
    );
  }

  // Minimal icon-only action button.
  // NOTE: No Tooltip — Tooltip registers MouseRegion which causes
  // !_debugDuringDeviceUpdate assertion on Flutter web when many list items are rendered.
  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required String tooltip,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color)),
    );
  }

  // Clean left-accent result panel.
  // Uses Stack+Positioned for the left bar — avoids IntrinsicHeight which causes
  // mouse_tracker assertion on Flutter web (!_debugDuringDeviceUpdate).
  Widget _resultPanel(
      {required String label,
      required String value,
      required Color accent,
      required bool isDark,
      required Color valueColor}) {
    final bg = isDark ? Colors.black.withValues(alpha: 0.12) : Colors.white;
    final outerBorder = accent.withValues(alpha: 0.15);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Background + content
          Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: outerBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.fromLTRB(15, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: accent)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 13, height: 1.45, color: valueColor)),
              ],
            ),
          ),
          // Left accent bar (no IntrinsicHeight needed)
          Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accent)),
        ],
      ),
    );
  }

  void _showAddOrEditTestCaseDialog(BuildContext context,
      {TestCaseModel? existingCase}) {
    final isEdit = existingCase != null;
    final tcIdController =
        TextEditingController(text: isEdit ? existingCase.code : '');
    final moduleController =
        TextEditingController(text: isEdit ? existingCase.module : '');
    final featureController =
        TextEditingController(text: isEdit ? existingCase.feature : '');
    final scenarioController =
        TextEditingController(text: isEdit ? existingCase.title : '');
    final preconditionsController =
        TextEditingController(text: isEdit ? existingCase.preconditions : '');
    final stepsController = TextEditingController(
        text: isEdit ? existingCase.steps.join('\n') : '');
    final testDataController =
        TextEditingController(text: isEdit ? existingCase.testData : '');
    final expectedController =
        TextEditingController(text: isEdit ? existingCase.expectedResult : '');
    final actualController =
        TextEditingController(text: isEdit ? existingCase.actualResult : '');
    final testerController =
        TextEditingController(text: isEdit ? existingCase.assignedTo : '');
    final remarksController =
        TextEditingController(text: isEdit ? existingCase.remarks : '');

    TestCaseStatus status =
        isEdit ? existingCase.status : TestCaseStatus.untested;
    TestCasePriority priority =
        isEdit ? existingCase.priority : TestCasePriority.medium;
    DateTime? selectedExecutionDate =
        isEdit ? existingCase.executionDate : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Test Case' : 'Add New Test Case'),
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
                              decoration: const InputDecoration(
                                labelText: 'TC_ID',
                                hintText: 'e.g. TC-101',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: moduleController,
                              decoration: const InputDecoration(
                                labelText: 'Module',
                                hintText: 'e.g. Authentication',
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Feature',
                                hintText: 'e.g. Login & SSO',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: testerController,
                              decoration: const InputDecoration(
                                labelText: 'Tester',
                                hintText: 'e.g. QA Tester',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: scenarioController,
                        decoration: const InputDecoration(
                          labelText: 'Test Case Scenario (Title)',
                          hintText:
                              'e.g. Verify user login with valid credentials',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: preconditionsController,
                        decoration: const InputDecoration(
                          labelText: 'Preconditions',
                          hintText: 'e.g. User registered and active',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: stepsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Test Steps',
                          hintText:
                              'Step 1: Open Login page\nStep 2: Enter credentials\nStep 3: Click Submit',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: testDataController,
                        decoration: const InputDecoration(
                          labelText: 'Test Data',
                          hintText: 'e.g. user@example.com / password123',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: expectedController,
                              decoration: const InputDecoration(
                                labelText: 'Expected Result',
                                hintText: 'e.g. Dashboard loaded successfully',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: actualController,
                              decoration: const InputDecoration(
                                labelText: 'Actual Result',
                                hintText: 'e.g. Passed as expected',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TestCaseStatus>(
                              initialValue: status,
                              decoration:
                                  const InputDecoration(labelText: 'Status'),
                              items: TestCaseStatus.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setDialogState(() => status = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<TestCasePriority>(
                              initialValue: priority,
                              decoration:
                                  const InputDecoration(labelText: 'Priority'),
                              items: TestCasePriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(p.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setDialogState(() => priority = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          hintText: 'e.g. Tested on Chrome v120',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Execution Date Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedExecutionDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(
                                () => selectedExecutionDate = picked);
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
                                  color: selectedExecutionDate != null
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18),
                            ],
                          ),
                        ),
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
                    if (scenarioController.text.trim().isEmpty) return;

                    final steps = stepsController.text
                        .split('\n')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final autoCode = 'TC-${100 + DateTime.now().second}';
                    final newOrUpdated = TestCaseModel(
                      id: isEdit ? existingCase.id : const Uuid().v4(),
                      code: tcIdController.text.trim().isEmpty
                          ? autoCode
                          : tcIdController.text.trim(),
                      title: scenarioController.text.trim(),
                      description: scenarioController.text.trim(),
                      module: moduleController.text.trim().isEmpty
                          ? 'General'
                          : moduleController.text.trim(),
                      feature: featureController.text.trim().isEmpty
                          ? 'Core'
                          : featureController.text.trim(),
                      preconditions: preconditionsController.text.trim().isEmpty
                          ? 'N/A'
                          : preconditionsController.text.trim(),
                      steps: steps.isEmpty ? ['Perform execution'] : steps,
                      testData: testDataController.text.trim().isEmpty
                          ? 'N/A'
                          : testDataController.text.trim(),
                      expectedResult: expectedController.text.trim().isEmpty
                          ? 'N/A'
                          : expectedController.text.trim(),
                      actualResult: actualController.text.trim().isEmpty
                          ? 'N/A'
                          : actualController.text.trim(),
                      status: status,
                      priority: priority,
                      type: 'Functional',
                      assignedTo: testerController.text.trim().isEmpty
                          ? 'Unassigned'
                          : testerController.text.trim(),
                      createdBy:
                          Provider.of<AuthProvider>(context, listen: false)
                                  .currentUser
                                  ?.name ??
                              'QA Engineer',
                      updatedAt: DateTime.now(),
                      executionDate: selectedExecutionDate,
                      remarks: remarksController.text.trim().isEmpty
                          ? 'N/A'
                          : remarksController.text.trim(),
                    );

                    final provider =
                        Provider.of<TestCaseProvider>(context, listen: false);
                    if (isEdit) {
                      await provider.updateTestCase(newOrUpdated);
                    } else {
                      await provider.addTestCase(newOrUpdated);
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ToastUtils.showSuccess(
                        context,
                        isEdit
                            ? 'Test case updated!'
                            : 'Test case added successfully!',
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void _downloadCSVFile(String csvContent, String fileName) {
    try {
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }

  static void _pickAndReadFile(
      Function(String text, String fileName) onFileRead) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.csv,.tsv,.txt,.xlsx';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsText(file);
          reader.onLoadEnd.listen((e) {
            final content = reader.result as String;
            onFileRead(content, file.name);
          });
        }
      });
    } catch (_) {}
  }

  void _exportToCSV(BuildContext context, List<TestCaseModel> testCases) {
    if (testCases.isEmpty) {
      AppLogger.warn('TestCasesScreen', 'Export attempted with 0 test cases');
      ToastUtils.showInfo(context, 'No test cases to export.');
      return;
    }
    AppLogger.info(
        'TestCasesScreen', 'Exporting ${testCases.length} test cases to CSV');
    final buffer = StringBuffer();
    buffer.writeln(
        'TC_ID,Module,Feature,Scenario,Preconditions,Steps,TestData,ExpectedResult,ActualResult,Status,Priority,Tester,ExecutionDate,Remarks');
    for (var tc in testCases) {
      final safeTitle = tc.title.replaceAll('"', '""');
      final safePre = tc.preconditions.replaceAll('"', '""');
      final safeSteps = tc.steps.join('; ').replaceAll('"', '""');
      final safeData = tc.testData.replaceAll('"', '""');
      final safeExp = tc.expectedResult.replaceAll('"', '""');
      final safeAct = tc.actualResult.replaceAll('"', '""');
      final safeRem = tc.remarks.replaceAll('"', '""');

      buffer.writeln(
          '${tc.code},${tc.module},${tc.feature},"$safeTitle","$safePre","$safeSteps","$safeData","$safeExp","$safeAct",${tc.status.name},${tc.priority.name},${tc.assignedTo},${tc.updatedAt.toIso8601String()},"$safeRem"');
    }

    final csvText = buffer.toString();
    final fileName =
        'test_cases_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    // Automatically trigger direct browser file download
    _downloadCSVFile(csvText, fileName);
    AppLogger.success('TestCasesScreen', 'CSV file downloaded: $fileName');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.file_download_done_rounded, color: AppColors.passed),
            SizedBox(width: 10),
            Text('CSV Exported & Downloaded'),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'File "$fileName" has been automatically downloaded to your computer.'),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: csvText),
                maxLines: 8,
                readOnly: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_download_rounded, size: 16),
            label: const Text('Download .CSV File Again'),
            onPressed: () {
              _downloadCSVFile(csvText, fileName);
              ToastUtils.showSuccess(context, 'Downloading $fileName...');
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Data'),
            onPressed: () {
              Navigator.of(context).pop();
              ToastUtils.showSuccess(context, 'CSV data copied to clipboard!');
            },
          ),
        ],
      ),
    );
  }

  void _showImportCSVDialog(BuildContext context) {
    final csvController = TextEditingController();
    List<TestCaseModel> parsedCases = [];
    String selectedFileName = '';
    int activeTab = 0; // 0 = File Upload, 1 = Copy/Paste Text

    // Capture the current user BEFORE opening the dialog (safe context use)
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).currentUser;
    final currentUserName = currentUser?.name ?? 'QA Team Member';

    showDialog(
      context: context,
      builder: (context) {
        final isDark =
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateParsedCases(String text) {
              setDialogState(() {
                parsedCases =
                    _parseCSVOrTSVText(text, uploaderName: currentUserName);
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.file_upload_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text('Import Test Cases'),
                ],
              ),
              content: SizedBox(
                width: 780,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Separate Option Tabs (File Upload vs Copy & Paste)
                      Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      setDialogState(() => activeTab = 0),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: activeTab == 0
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.upload_file_rounded,
                                            size: 18,
                                            color: activeTab == 0
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Select & Upload File (.csv, .tsv, .txt)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: activeTab == 0
                                                  ? Colors.white
                                                  : (isDark
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      setDialogState(() => activeTab = 1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: activeTab == 1
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.content_paste_rounded,
                                            size: 18,
                                            color: activeTab == 1
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Copy & Paste Text / Excel Rows',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: activeTab == 1
                                                  ? Colors.white
                                                  : (isDark
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab 0: File Upload Mode
                      if (activeTab == 0)
                        Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _pickAndReadFile((text, filename) {
                                    csvController.text = text;
                                    setDialogState(() {
                                      selectedFileName = filename;
                                      parsedCases = _parseCSVOrTSVText(text,
                                          uploaderName: currentUserName);
                                    });
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                          Icons.drive_folder_upload_rounded,
                                          size: 44,
                                          color: AppColors.primary),
                                      const SizedBox(height: 10),
                                      Text(
                                        selectedFileName.isNotEmpty
                                            ? 'Selected File: $selectedFileName'
                                            : 'Click here to choose file from your computer',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: selectedFileName.isNotEmpty
                                              ? AppColors.passed
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Supports CSV (.csv), TSV (.tsv), and Text (.txt) files',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (selectedFileName
                                    .toLowerCase()
                                    .endsWith('.xlsx') ||
                                selectedFileName
                                    .toLowerCase()
                                    .endsWith('.xls') ||
                                csvController.text.startsWith('PK'))
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  border:
                                      Border.all(color: Colors.amber.shade700),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.amber.shade800),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Notice: Raw .xlsx spreadsheets are compressed binary files.\nTo import your Excel data cleanly:\n• In Excel: File ➔ Save As ➔ CSV (.csv)\n• OR select all cells in Excel (Ctrl+A ➔ Ctrl+C), switch to "Copy & Paste Text" tab above, and paste!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: isDark
                                              ? Colors.amber.shade200
                                              : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      else
                        // Tab 1: Copy & Paste Text Mode
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paste your copied Excel table rows or CSV text in the area below:',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: csvController,
                              maxLines: 6,
                              onChanged: updateParsedCases,
                              decoration: InputDecoration(
                                hintText:
                                    'Paste Excel rows or CSV text here...',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Live Preview Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Parsed Preview (${parsedCases.length} Test Cases Detected):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (parsedCases.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.passed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${parsedCases.length} Ready to Import',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.passed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Preview Table Grid
                      if (parsedCases.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              activeTab == 0
                                  ? 'Click "Select & Upload File" above to pick a file from your computer.'
                                  : 'Paste test case text above to preview parsed rows live.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowHeight: 36,
                                dataRowMinHeight: 32,
                                dataRowMaxHeight: 48,
                                columns: const [
                                  DataColumn(
                                      label: Text('TC_ID',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Module',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Feature',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Scenario / Title',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Expected Result',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Status',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Priority',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Tester',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: parsedCases.map((tc) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(tc.code,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                      DataCell(Text(tc.module)),
                                      DataCell(Text(tc.feature)),
                                      DataCell(SizedBox(
                                          width: 180,
                                          child: Text(tc.title,
                                              overflow:
                                                  TextOverflow.ellipsis))),
                                      DataCell(SizedBox(
                                          width: 150,
                                          child: Text(tc.expectedResult,
                                              overflow:
                                                  TextOverflow.ellipsis))),
                                      DataCell(
                                          Text(tc.status.name.toUpperCase())),
                                      DataCell(
                                          Text(tc.priority.name.toUpperCase())),
                                      DataCell(Text(tc.assignedTo)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_done_rounded, size: 18),
                  label: Text('Import ${parsedCases.length} Test Cases'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: parsedCases.isEmpty
                      ? null
                      : () async {
                          final provider = Provider.of<TestCaseProvider>(
                              context,
                              listen: false);
                          await provider.addTestCasesBatch(parsedCases);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ToastUtils.showSuccess(
                              context,
                              'Successfully stored ${parsedCases.length} test cases dynamically in Database & State!',
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

  static List<TestCaseModel> _parseCSVOrTSVText(String rawText,
      {String uploaderName = 'QA Team Member'}) {
    final List<TestCaseModel> results = [];
    if (rawText.trim().isEmpty) return results;

    // Guard against binary .xlsx zip archives
    if (rawText.startsWith('PK\x03\x04') ||
        rawText.startsWith('PK') ||
        rawText.contains('\uFFFD')) {
      return results;
    }

    final rawLines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (rawLines.isEmpty) return results;

    // Detect delimiter (Tab, Comma, Semicolon, Pipe)
    int tabCount = 0;
    int commaCount = 0;
    int semicolonCount = 0;
    int pipeCount = 0;

    for (var line in rawLines.take(15)) {
      tabCount += '\t'.allMatches(line).length;
      commaCount += ','.allMatches(line).length;
      semicolonCount += ';'.allMatches(line).length;
      pipeCount += '|'.allMatches(line).length;
    }

    String delimiter = '\t';
    if (tabCount >= commaCount &&
        tabCount >= semicolonCount &&
        tabCount >= pipeCount &&
        tabCount > 0) {
      delimiter = '\t';
    } else if (commaCount > 0) {
      delimiter = ',';
    } else if (semicolonCount > 0) {
      delimiter = ';';
    } else if (pipeCount > 0) {
      delimiter = '|';
    } else {
      delimiter = r'\s+';
    }

    final List<List<String>> rows = [];
    for (var line in rawLines) {
      if (delimiter == r'\s+') {
        rows.add(line.split(RegExp(r'\s+')));
      } else {
        rows.add(_splitLineWithQuotes(line, delimiter));
      }
    }

    if (rows.isEmpty) return results;

    // Search across rows to locate the real table header row
    int headerRowIndex = -1;
    final Map<String, int> colMap = {};
    final headerKeywords = [
      'tc_id',
      'tcid',
      'code',
      'module',
      'feature',
      'scenario',
      'title',
      'preconditions',
      'steps',
      'test_data',
      'expected',
      'actual',
      'status',
      'priority',
      'tester',
      'remarks'
    ];

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      int matches = 0;
      for (int c = 0; c < row.length; c++) {
        final cell = row[c].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
        for (var kw in headerKeywords) {
          if (cell.contains(kw)) {
            matches++;
            break;
          }
        }
      }
      if (matches >= 2 ||
          (matches >= 1 &&
              (row.first.toLowerCase() == 'tc_id' ||
                  row.first.toLowerCase() == 'code' ||
                  row.first.toLowerCase() == 'tcid'))) {
        headerRowIndex = r;
        for (int c = 0; c < row.length; c++) {
          final cell =
              row[c].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
          colMap[cell] = c;
        }
        break;
      }
    }

    final bool hasHeader = headerRowIndex != -1;
    int count = 0;

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      // Skip document titles before the first table header
      if (hasHeader && r < headerRowIndex) continue;

      // Check if this row is a new/repeated sub-header row in a multi-section CSV
      int subHeaderMatches = 0;
      for (int c = 0; c < row.length; c++) {
        final cell = row[c].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
        for (var kw in headerKeywords) {
          if (cell.isNotEmpty && (cell == kw || cell.contains(kw))) {
            subHeaderMatches++;
            break;
          }
        }
      }
      if (subHeaderMatches >= 2) {
        colMap.clear();
        for (int c = 0; c < row.length; c++) {
          final cell =
              row[c].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
          colMap[cell] = c;
        }
        continue;
      }

      // Skip non-data section title rows (e.g., "Career Portal", "Selected Outcome")
      if (row.length <= 2 ||
          (row.length > 2 &&
              row.sublist(1).every((cell) => cell.trim().isEmpty))) {
        continue;
      }

      String getValue(List<String> keyNames, int defaultIdx) {
        if (colMap.isNotEmpty) {
          for (var k in keyNames) {
            final normK = k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
            for (var entry in colMap.entries) {
              if (entry.key == normK || entry.key.contains(normK)) {
                final idx = entry.value;
                if (idx < row.length) return row[idx].trim();
              }
            }
          }
        }
        if (defaultIdx < row.length) return row[defaultIdx].trim();
        return '';
      }

      final code = getValue(['tc_id', 'tcid', 'code', 'testcaseid', 'id'], 0);
      final module = getValue(['module'], 1);
      final feature = getValue(['feature', 'testtype', 'type'], 2);
      final title = getValue([
        'scenario',
        'title',
        'testcasetitle',
        'name',
        'test_case_scenario',
        'description'
      ], 3);
      final preconditions = getValue(
          ['preconditions', 'pre_conditions', 'precondition', 'preconditions'],
          4);
      final stepsRaw =
          getValue(['steps', 'test_steps', 'execution_steps', 'teststeps'], 5);
      final testData = getValue(['test_data', 'data', 'testdata'], 6);
      final expected =
          getValue(['expected_result', 'expected', 'expectedresult'], 7);
      final actual = getValue(['actual_result', 'actual', 'actualresult'], 8);
      final statusStr = getValue(['status'], 9);
      final priorityStr = getValue(['priority'], 10);
      String tester =
          getValue(['tester', 'assigned_to', 'assignedto', 'name'], 11);
      String execDateStr =
          getValue(['execution_date', 'executiondate', 'date'], 12);
      final remarks = getValue(['remarks', 'notes', 'comments'], 13);

      // Disambiguate Date vs Tester name if column values shifted
      if (RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$').hasMatch(tester.trim())) {
        if (execDateStr.isEmpty) {
          execDateStr = tester;
        }
        tester = '';
      }

      if (tester.isEmpty ||
          tester.toLowerCase() == 'name' ||
          tester.toLowerCase() == 'tester') {
        // Fall back to the logged-in uploader's name (passed as parameter)
        tester = uploaderName;
      }

      DateTime? parsedExecDate;
      if (execDateStr.isNotEmpty) {
        try {
          parsedExecDate = DateTime.tryParse(execDateStr);
          if (parsedExecDate == null) {
            final parts = execDateStr.split(RegExp(r'[-/]'));
            if (parts.length == 3) {
              final d = int.tryParse(parts[0]) ?? 1;
              final m = int.tryParse(parts[1]) ?? 1;
              final y = int.tryParse(parts[2]) ?? DateTime.now().year;
              parsedExecDate = DateTime(y, m, d);
            }
          }
        } catch (_) {}
      }

      // Skip invalid noise rows
      if (code.isEmpty && title.isEmpty) continue;
      if (code.length < 3 && title.length < 3 && row.length < 3) continue;

      count++;

      TestCaseStatus parseStatus(String s) {
        switch (s.toLowerCase().trim()) {
          case 'pass':
          case 'passed':
            return TestCaseStatus.passed;
          case 'fail':
          case 'failed':
            return TestCaseStatus.failed;
          case 'block':
          case 'blocked':
            return TestCaseStatus.blocked;
          case 'in_progress':
          case 'inprogress':
            return TestCaseStatus.inProgress;
          default:
            return TestCaseStatus.untested;
        }
      }

      TestCasePriority parsePriority(String p) {
        switch (p.toLowerCase().trim()) {
          case 'critical':
            return TestCasePriority.critical;
          case 'high':
            return TestCasePriority.high;
          case 'low':
            return TestCasePriority.low;
          default:
            return TestCasePriority.medium;
        }
      }

      String tcCode = code.isNotEmpty ? code : 'TC-${100 + count}';
      String tcTitle = title.isNotEmpty
          ? title
          : (row.length > 3
              ? row[3]
              : (row.length > 1
                  ? row.sublist(1).join(' ')
                  : 'Imported Test Case #$count'));

      if (tcCode.contains(',') ||
          tcCode.length > 25 ||
          tcCode.trim().contains(' ')) {
        if (title.isEmpty || title.startsWith('Imported Test Case')) {
          tcTitle = tcCode.split(',').first.trim();
        }
        tcCode = 'TC-${100 + count}';
      }

      results.add(TestCaseModel(
        id: const Uuid().v4(),
        code: tcCode,
        title: tcTitle,
        description: tcTitle,
        module: module.isNotEmpty ? module : 'Candidate Applications API',
        feature: feature.isNotEmpty ? feature : 'Core Feature',
        preconditions: preconditions.isNotEmpty ? preconditions : 'N/A',
        steps: stepsRaw.isNotEmpty
            ? stepsRaw
                .split(RegExp(r'[;\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : ['Step 1: Execute test scenario'],
        testData: testData.isNotEmpty ? testData : 'N/A',
        expectedResult: expected.isNotEmpty ? expected : 'Expected test pass',
        actualResult: actual.isNotEmpty ? actual : 'N/A',
        status: parseStatus(statusStr),
        priority: parsePriority(priorityStr),
        type: 'Functional',
        assignedTo: tester,
        createdBy: uploaderName,
        updatedAt: DateTime.now(),
        executionDate: parsedExecDate ?? DateTime.now(),
        remarks: remarks.isNotEmpty ? remarks : 'N/A',
        suiteId: '',
        suiteName: 'Recruitment & Career Portal',
      ));
    }

    return results;
  }

  void _showSaveToTestSuiteDialog(
      BuildContext context, List<TestCaseModel> casesToSave) {
    final suiteProvider =
        Provider.of<TestSuiteProvider>(context, listen: false);
    final tcProvider = Provider.of<TestCaseProvider>(context, listen: false);
    final currentUserName =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
            'QA Lead';

    final existingSuites = suiteProvider.testSuites;
    String? selectedExistingSuiteId;
    bool isCreateNew = existingSuites.isEmpty;

    final nameController = TextEditingController(
      text: existingSuites.isNotEmpty
          ? existingSuites.first.name
          : 'Release Test Suite',
    );
    final buildController = TextEditingController(
      text: existingSuites.isNotEmpty
          ? existingSuites.first.buildName
          : 'Build v1.0.4 - Release Staging',
    );
    final versionController = TextEditingController(
      text: existingSuites.isNotEmpty ? existingSuites.first.version : 'v1.0.0',
    );
    final descController = TextEditingController(
      text: existingSuites.isNotEmpty
          ? existingSuites.first.description
          : 'Generated test suite containing ${casesToSave.length} test scenarios.',
    );

    if (existingSuites.isNotEmpty) {
      selectedExistingSuiteId = existingSuites.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark =
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

        return StatefulBuilder(
          builder: (context, setDlgState) {
            // Find if current typed name matches an existing suite
            final typedName = nameController.text.trim().toLowerCase();
            final matchingSuite = existingSuites
                .where((s) => s.name.toLowerCase() == typedName)
                .toList();
            final isDuplicate = matchingSuite.isNotEmpty;
            final matched = isDuplicate ? matchingSuite.first : null;

            // Check if all cases are already in this matched suite
            final alreadySavedCount = matched != null
                ? casesToSave
                    .where((tc) =>
                        tc.suiteId == matched.id ||
                        tc.suiteName.toLowerCase() ==
                            matched.name.toLowerCase())
                    .length
                : 0;
            final isAlreadyAllSaved =
                matched != null && alreadySavedCount == casesToSave.length;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.folder_special_rounded,
                      color: AppColors.secondary),
                  const SizedBox(width: 10),
                  const Text('Save Cases to Test Suite'),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scope info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${casesToSave.length} test cases will be assigned and saved to this Test Suite.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Existing Suite vs New Suite mode selector
                      if (existingSuites.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                    child: Text('Select Existing Suite')),
                                selected: !isCreateNew,
                                onSelected: (sel) {
                                  if (sel) {
                                    setDlgState(() {
                                      isCreateNew = false;
                                      final suite = existingSuites.firstWhere(
                                        (s) => s.id == selectedExistingSuiteId,
                                        orElse: () => existingSuites.first,
                                      );
                                      nameController.text = suite.name;
                                      buildController.text = suite.buildName;
                                      versionController.text = suite.version;
                                      descController.text = suite.description;
                                    });
                                  }
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: !isCreateNew
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                  fontWeight: !isCreateNew
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                    child: Text('Create New Suite')),
                                selected: isCreateNew,
                                onSelected: (sel) {
                                  if (sel) {
                                    setDlgState(() {
                                      isCreateNew = true;
                                      nameController.text =
                                          'New Test Suite ${existingSuites.length + 1}';
                                      buildController.text =
                                          'Build v1.0.4 - QA Staging';
                                      versionController.text = 'v1.0.0';
                                      descController.text =
                                          'Generated test suite containing ${casesToSave.length} test scenarios.';
                                    });
                                  }
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isCreateNew
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                  fontWeight: isCreateNew
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!isCreateNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      isDark ? Colors.white12 : Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedExistingSuiteId,
                                hint: const Text('Select a Suite'),
                                items: existingSuites.map((s) {
                                  return DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.name} (${s.totalCases} cases • Build: ${s.buildName})',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final suite = existingSuites
                                        .firstWhere((s) => s.id == val);
                                    setDlgState(() {
                                      selectedExistingSuiteId = val;
                                      nameController.text = suite.name;
                                      buildController.text = suite.buildName;
                                      versionController.text = suite.version;
                                      descController.text = suite.description;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                      ],

                      // Duplicate / Existing Banner
                      if (isDuplicate) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAlreadyAllSaved
                                ? AppColors.passed.withValues(alpha: 0.12)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAlreadyAllSaved
                                  ? AppColors.passed
                                  : Colors.amber.shade700,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAlreadyAllSaved
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.warning_amber_rounded,
                                size: 20,
                                color: isAlreadyAllSaved
                                    ? AppColors.passed
                                    : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isAlreadyAllSaved
                                      ? 'Notice: All ${casesToSave.length} test cases are already stored in "$matched.name".'
                                      : 'Suite "$matched.name" already exists with ${matched?.totalCases ?? 0} cases. Saving will update the existing suite.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isAlreadyAllSaved
                                        ? AppColors.passed
                                        : (isDark
                                            ? Colors.amber.shade200
                                            : Colors.amber.shade900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextField(
                        controller: nameController,
                        onChanged: (_) => setDlgState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Suite Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: buildController,
                        decoration: const InputDecoration(
                          labelText: 'Build Name *',
                          hintText: 'e.g. Build v1.0.4 - QA Staging',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: versionController,
                        decoration: const InputDecoration(
                          labelText: 'Version *',
                          hintText: 'e.g. v1.0.0',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: Icon(
                      isDuplicate ? Icons.sync_rounded : Icons.save_rounded,
                      size: 18),
                  label: Text(
                    isAlreadyAllSaved
                        ? 'Re-Sync Suite'
                        : isDuplicate
                            ? 'Update Existing Suite'
                            : 'Create & Save Suite',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDuplicate ? AppColors.primary : AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final suiteName = nameController.text.trim();
                    final buildName = buildController.text.trim().isNotEmpty
                        ? buildController.text.trim()
                        : 'Build v1.0.4';
                    final version = versionController.text.trim().isNotEmpty
                        ? versionController.text.trim()
                        : 'v1.0.0';

                    final suiteId =
                        matched != null ? matched.id : const Uuid().v4();

                    final passed = casesToSave
                        .where((tc) => tc.status == TestCaseStatus.passed)
                        .length;
                    final failed = casesToSave
                        .where((tc) => tc.status == TestCaseStatus.failed)
                        .length;
                    final blocked = casesToSave
                        .where((tc) => tc.status == TestCaseStatus.blocked)
                        .length;

                    final targetSuite = TestSuiteModel(
                      id: suiteId,
                      name: suiteName,
                      buildName: buildName,
                      version: version,
                      description: descController.text.trim(),
                      totalCases: casesToSave.length,
                      passedCases: passed,
                      failedCases: failed,
                      blockedCases: blocked,
                      createdBy:
                          matched != null ? matched.createdBy : currentUserName,
                      createdAt:
                          matched != null ? matched.createdAt : DateTime.now(),
                    );

                    if (matched != null) {
                      await suiteProvider.updateTestSuite(targetSuite);
                    } else {
                      await suiteProvider.addTestSuite(targetSuite);
                    }

                    // Update test cases with suiteId and suiteName in a SINGLE fast batch
                    final updatedList = casesToSave
                        .map((tc) =>
                            tc.copyWith(suiteId: suiteId, suiteName: suiteName))
                        .toList();
                    await tcProvider.updateTestCasesBatch(updatedList);

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ToastUtils.showSuccess(
                        context,
                        'Suite "$suiteName" saved with ${casesToSave.length} test cases!',
                      );

                      // Open the dedicated test suite screen so user immediately sees their suite
                      context.go('/test-suites/$suiteId', extra: targetSuite);
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
}
