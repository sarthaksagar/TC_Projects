import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/test_case_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/test_case_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_chart.dart';
import '../widgets/stat_card.dart';

class QATeamMemberStats {
  final String name;
  final List<TestCaseModel> assignedCases;
  final int total;
  final int passed;
  final int failed;
  final int blocked;
  final int untested;
  final double completionRate;
  final double passRate;

  const QATeamMemberStats({
    required this.name,
    required this.assignedCases,
    required this.total,
    required this.passed,
    required this.failed,
    required this.blocked,
    required this.untested,
    required this.completionRate,
    required this.passRate,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedTab = 'team_report'; // 'overview', 'team_report', 'hotspots'
  String _selectedTesterFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final testCaseProvider = Provider.of<TestCaseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final user = authProvider.currentUser;
    final userRole = user?.role ?? 'QA Team Member';
    final isQALead = userRole.toLowerCase().contains('lead') || userRole.toLowerCase().contains('admin');

    if (dashboardProvider.isLoading && testCaseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allRawCases = testCaseProvider.allRawCases;

    // QA Lead sees all cases; QA Team Member only sees their own assigned cases
    final userName = user?.name ?? '';
    final allCases = isQALead
        ? allRawCases
        : allRawCases.where((tc) {
            final assigned = tc.assignedTo.trim().toLowerCase();
            final created = tc.createdBy.trim().toLowerCase();
            final myName = userName.trim().toLowerCase();
            return assigned == myName || created == myName || assigned.isEmpty;
          }).toList();

    // Compute live metrics strictly from testCaseProvider so Dashboard matches repository state exactly
    final totalCasesCount = allCases.length;
    final passedCasesCount = allCases.where((tc) => tc.status == TestCaseStatus.passed).length;
    final failedCasesCount = allCases.where((tc) => tc.status == TestCaseStatus.failed).length;
    final blockedCasesCount = allCases.where((tc) => tc.status == TestCaseStatus.blocked).length;
    final untestedCasesCount = allCases.where((tc) => tc.status == TestCaseStatus.untested || tc.status == TestCaseStatus.inProgress).length;

    final passPercentage = totalCasesCount == 0 ? 0.0 : (passedCasesCount / totalCasesCount) * 100;
    final failPercentage = totalCasesCount == 0 ? 0.0 : (failedCasesCount / totalCasesCount) * 100;
    final blockedPercentage = totalCasesCount == 0 ? 0.0 : (blockedCasesCount / totalCasesCount) * 100;

    // Group test cases by QA team member (tester) — QA Lead sees all; tester sees self only
    final Map<String, List<TestCaseModel>> casesByTester = {};
    for (final tc in allCases) {
      final testerName = tc.assignedTo.trim().isEmpty ? 'Unassigned' : tc.assignedTo.trim();
      casesByTester.putIfAbsent(testerName, () => []).add(tc);
    }

    // Generate team member stats list
    final List<QATeamMemberStats> teamStats = casesByTester.entries.map((entry) {
      final name = entry.key;
      final cases = entry.value;
      final total = cases.length;
      final passed = cases.where((c) => c.status == TestCaseStatus.passed).length;
      final failed = cases.where((c) => c.status == TestCaseStatus.failed).length;
      final blocked = cases.where((c) => c.status == TestCaseStatus.blocked).length;
      final untested = cases.where((c) => c.status == TestCaseStatus.untested || c.status == TestCaseStatus.inProgress).length;
      final executed = passed + failed + blocked;
      final completion = total == 0 ? 0.0 : (executed / total) * 100;
      final pRate = executed == 0 ? 0.0 : (passed / executed) * 100;

      return QATeamMemberStats(
        name: name,
        assignedCases: cases,
        total: total,
        passed: passed,
        failed: failed,
        blocked: blocked,
        untested: untested,
        completionRate: completion,
        passRate: pRate,
      );
    }).toList();

    // Sort team stats: largest workload first
    teamStats.sort((a, b) => b.total.compareTo(a.total));

    // Get list of unique testers for filter
    final List<String> testerNames = ['All', ...casesByTester.keys];

    // Filtered team stats based on tester filter
    final filteredTeamStats = _selectedTesterFilter == 'All'
        ? teamStats
        : teamStats.where((s) => s.name == _selectedTesterFilter).toList();

    // Failed & Blocked test cases (hotspots requiring QA Lead resolution)
    final problemCases = allCases.where((tc) =>
        tc.status == TestCaseStatus.failed || tc.status == TestCaseStatus.blocked).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isQALead ? 'QA Lead Dashboard' : 'QA Analytics & Team Dashboard',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isQALead ? 'QA LEAD VIEW' : userRole.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time QA team workload, test case execution progress, solved status, and defect reports.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      testCaseProvider.loadTestCases();
                      dashboardProvider.loadDashboardData();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Live Data'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/test-cases'),
                    icon: const Icon(Icons.checklist_rounded, size: 16),
                    label: const Text('View All Test Cases'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Executive QA Lead Summary Banner
          _buildQALeadSummaryBanner(
            context: context,
            isDark: isDark,
            isQALead: isQALead,
            userName: user?.name ?? 'Team Member',
            userRole: userRole,
            teamCount: teamStats.length,
            totalCases: totalCasesCount,
            passedCases: passedCasesCount,
            failedCases: failedCasesCount,
            blockedCases: blockedCasesCount,
            untestedCases: untestedCasesCount,
            passRate: passPercentage,
          ),
          const SizedBox(height: 24),

          // Key Stat Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1100
                  ? 4
                  : (constraints.maxWidth > 700 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'TOTAL TEST CASES',
                    value: '$totalCasesCount',
                    subtitle: 'Across ${teamStats.length} QA Testers',
                    icon: Icons.assignment_outlined,
                    accentColor: AppColors.primary,
                  ),
                  StatCard(
                    title: 'SOLVED / PASSED',
                    value: '$passedCasesCount',
                    subtitle: '${passPercentage.toStringAsFixed(1)}% Team Pass Rate',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: AppColors.passed,
                    progress: passPercentage / 100,
                  ),
                  StatCard(
                    title: 'FAILED / DEFECTS',
                    value: '$failedCasesCount',
                    subtitle: '${failPercentage.toStringAsFixed(1)}% Failure Rate',
                    icon: Icons.highlight_off_rounded,
                    accentColor: AppColors.failed,
                    progress: failPercentage / 100,
                  ),
                  StatCard(
                    title: 'BLOCKED ISSUES',
                    value: '$blockedCasesCount',
                    subtitle: '$untestedCasesCount Untested / In Progress',
                    icon: Icons.warning_amber_rounded,
                    accentColor: AppColors.blocked,
                    progress: blockedPercentage / 100,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Section Navigation Tabs & Filter Bar
          _buildSectionNavigation(
            isDark: isDark,
            testerNames: testerNames,
            totalTeamCases: totalCasesCount,
            problemCount: problemCases.length,
          ),
          const SizedBox(height: 20),

          // Tab Content Rendering
          if (_selectedTab == 'team_report') ...[
            _buildQATeamReportSection(
              context: context,
              isDark: isDark,
              teamStats: filteredTeamStats,
              totalCases: totalCasesCount,
            ),
          ] else if (_selectedTab == 'hotspots') ...[
            _buildProblemHotspotsSection(
              context: context,
              isDark: isDark,
              problemCases: problemCases,
            ),
          ] else ...[
            _buildExecutiveOverviewSection(
              context: context,
              isDark: isDark,
              dashboardProvider: dashboardProvider,
              allCases: allCases,
            ),
          ],
        ],
      ),
    );
  }

  // QA Lead Executive Hub Banner
  Widget _buildQALeadSummaryBanner({
    required BuildContext context,
    required bool isDark,
    required bool isQALead,
    required String userName,
    required String userRole,
    required int teamCount,
    required int totalCases,
    required int passedCases,
    required int failedCases,
    required int blockedCases,
    required int untestedCases,
    required double passRate,
  }) {
    final bg = isDark ? const Color(0xFF131C2E) : const Color(0xFFEFF6FF);
    final border = isDark ? const Color(0xFF223555) : const Color(0xFFBFDBFE);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QA Team Operations Command • $userName ($userRole)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live visibility into which team member is executing which test cases, how many have been solved/passed, and current blockers.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Key metrics row
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildMiniMetric(label: 'ACTIVE TESTERS', value: '$teamCount Members', color: AppColors.primary, isDark: isDark),
              _buildMiniMetric(label: 'ASSIGNED TEST CASES', value: '$totalCases Scenarios', color: isDark ? Colors.white : Colors.black87, isDark: isDark),
              _buildMiniMetric(label: 'SOLVED & PASSED', value: '$passedCases (${passRate.toStringAsFixed(1)}%)', color: AppColors.passed, isDark: isDark),
              _buildMiniMetric(label: 'DEFECTS & FAILED', value: '$failedCases Needs Fix', color: AppColors.failed, isDark: isDark),
              _buildMiniMetric(label: 'BLOCKED SCENARIOS', value: '$blockedCases Blocked', color: AppColors.blocked, isDark: isDark),
              _buildMiniMetric(label: 'IN PROGRESS / QUEUE', value: '$untestedCases Pending', color: AppColors.untested, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // Section Navigation Tabs and Tester Filter
  Widget _buildSectionNavigation({
    required bool isDark,
    required List<String> testerNames,
    required int totalTeamCases,
    required int problemCount,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        // Tab buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTabButton(
              id: 'team_report',
              label: 'QA Team Test Cases Report',
              count: '$totalTeamCases cases',
              isDark: isDark,
            ),
            _buildTabButton(
              id: 'hotspots',
              label: 'Failed & Blocked Hotspots',
              count: '$problemCount issues',
              isDark: isDark,
              highlightColor: problemCount > 0 ? AppColors.failed : null,
            ),
            _buildTabButton(
              id: 'overview',
              label: 'Execution Trends & Modules',
              count: null,
              isDark: isDark,
            ),
          ],
        ),

        // Tester Filter Dropdown
        if (_selectedTab == 'team_report')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTesterFilter,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: testerNames.map((t) {
                  return DropdownMenuItem<String>(
                    value: t,
                    child: Text(t == 'All' ? 'Filter: All QA Testers' : 'Tester: $t'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTesterFilter = val;
                    });
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required String? count,
    required bool isDark,
    Color? highlightColor,
  }) {
    final isSelected = _selectedTab == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = id;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (highlightColor ?? AppColors.primary)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (highlightColor ?? AppColors.primary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // QA Team Test Cases Report Section
  Widget _buildQATeamReportSection({
    required BuildContext context,
    required bool isDark,
    required List<QATeamMemberStats> teamStats,
    required int totalCases,
  }) {
    if (teamStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: const Text('No test cases assigned to QA team members yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QA Team Member Performance & Workload Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              'Showing ${teamStats.length} Team Members',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Tester Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: teamStats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final member = teamStats[index];
            return _buildTesterCard(context: context, isDark: isDark, stats: member, totalCases: totalCases);
          },
        ),
      ],
    );
  }

  // Individual QA Tester Card with Workload Breakdown & Inspection
  Widget _buildTesterCard({
    required BuildContext context,
    required bool isDark,
    required QATeamMemberStats stats,
    required int totalCases,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final workloadShare = totalCases == 0 ? 0.0 : (stats.total / totalCases);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tester Header Row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  stats.name.isNotEmpty ? stats.name.substring(0, 1).toUpperCase() : 'T',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              // Tester Name & Role Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stats.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${stats.total} Assigned Cases (${(workloadShare * 100).toStringAsFixed(0)}% of total)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Quality Pass Rate: ${stats.passRate.toStringAsFixed(1)}% • Execution Completion: ${stats.completionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Action button to inspect this tester's cases
              OutlinedButton.icon(
                onPressed: () => _showTesterCasesDialog(context, stats, isDark),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('Inspect Test Cases'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-segment progress bar for status distribution
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (stats.passed > 0)
                    Expanded(
                      flex: stats.passed,
                      child: Container(color: AppColors.passed),
                    ),
                  if (stats.failed > 0)
                    Expanded(
                      flex: stats.failed,
                      child: Container(color: AppColors.failed),
                    ),
                  if (stats.blocked > 0)
                    Expanded(
                      flex: stats.blocked,
                      child: Container(color: AppColors.blocked),
                    ),
                  if (stats.untested > 0)
                    Expanded(
                      flex: stats.untested,
                      child: Container(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status breakdown pills
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildStatusPill(
                label: 'SOLVED / PASSED',
                count: stats.passed,
                color: AppColors.passed,
                isDark: isDark,
              ),
              _buildStatusPill(
                label: 'FAILED',
                count: stats.failed,
                color: AppColors.failed,
                isDark: isDark,
              ),
              _buildStatusPill(
                label: 'BLOCKED',
                count: stats.blocked,
                color: AppColors.blocked,
                isDark: isDark,
              ),
              _buildStatusPill(
                label: 'UNTESTED / QUEUED',
                count: stats.untested,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Failed and Blocked Hotspots Table for QA Lead
  Widget _buildProblemHotspotsSection({
    required BuildContext context,
    required bool isDark,
    required List<TestCaseModel> problemCases,
  }) {
    if (problemCases.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.passed, size: 24),
            const SizedBox(width: 10),
            Text(
              'Zero active failures or blockers in test execution!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
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
                    'Defect Hotspots & Blocked Test Cases (${problemCases.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scenarios requiring immediate tester re-validation or developer bug resolution.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/test-cases'),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Open in Test Cases'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Spreadsheet-style problem list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: problemCases.length > 25 ? 25 : problemCases.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tc = problemCases[index];
              final isFailed = tc.status == TestCaseStatus.failed;
              final statusColor = isFailed ? AppColors.failed : AppColors.blocked;
              final statusLabel = isFailed ? 'FAILED' : 'BLOCKED';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    // Status Badge
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Code
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tc.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      flex: 4,
                      child: Text(
                        tc.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Module
                    Expanded(
                      flex: 2,
                      child: Text(
                        tc.module,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Assigned Tester
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          tc.assignedTo.isEmpty ? 'Unassigned' : tc.assignedTo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Executive Overview (Charts & Module Coverage)
  Widget _buildExecutiveOverviewSection({
    required BuildContext context,
    required bool isDark,
    required DashboardProvider dashboardProvider,
    required List<TestCaseModel> allCases,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: CustomChart(
                      title: 'Weekly Test Execution Trend',
                      trends: dashboardProvider.dailyTrends,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: CustomDonutChart(
                      passed: allCases.isNotEmpty
                          ? allCases.where((tc) => tc.status == TestCaseStatus.passed).length
                          : dashboardProvider.passedCases,
                      failed: allCases.isNotEmpty
                          ? allCases.where((tc) => tc.status == TestCaseStatus.failed).length
                          : dashboardProvider.failedCases,
                      blocked: allCases.isNotEmpty
                          ? allCases.where((tc) => tc.status == TestCaseStatus.blocked).length
                          : dashboardProvider.blockedCases,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                CustomChart(
                  title: 'Weekly Test Execution Trend',
                  trends: dashboardProvider.dailyTrends,
                ),
                const SizedBox(height: 20),
                CustomDonutChart(
                  passed: allCases.isNotEmpty
                      ? allCases.where((tc) => tc.status == TestCaseStatus.passed).length
                      : dashboardProvider.passedCases,
                  failed: allCases.isNotEmpty
                      ? allCases.where((tc) => tc.status == TestCaseStatus.failed).length
                      : dashboardProvider.failedCases,
                  blocked: allCases.isNotEmpty
                      ? allCases.where((tc) => tc.status == TestCaseStatus.blocked).length
                      : dashboardProvider.blockedCases,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Live Module Quality Matrix
        _buildLiveModuleQualityMatrix(context: context, isDark: isDark, allCases: allCases),
      ],
    );
  }

  // Live Module Quality Matrix
  Widget _buildLiveModuleQualityMatrix({
    required BuildContext context,
    required bool isDark,
    required List<TestCaseModel> allCases,
  }) {
    final Map<String, List<TestCaseModel>> casesByModule = {};
    for (final tc in allCases) {
      final moduleName = tc.module.trim().isEmpty ? 'General Module' : tc.module.trim();
      casesByModule.putIfAbsent(moduleName, () => []).add(tc);
    }

    final moduleList = casesByModule.entries.toList();
    moduleList.sort((a, b) => b.value.length.compareTo(a.value.length));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Module Quality & Execution Matrix',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${moduleList.length} Active Modules',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (moduleList.isEmpty)
            const Text('No module data available.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: moduleList.length > 8 ? 8 : moduleList.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final entry = moduleList[index];
                final modName = entry.key;
                final cases = entry.value;
                final total = cases.length;
                final passed = cases.where((c) => c.status == TestCaseStatus.passed).length;
                final failed = cases.where((c) => c.status == TestCaseStatus.failed).length;
                final blocked = cases.where((c) => c.status == TestCaseStatus.blocked).length;
                final passPct = total == 0 ? 0.0 : (passed / total);

                return Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Text(
                        modName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: passPct,
                          minHeight: 10,
                          backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                          color: AppColors.passed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${(passPct * 100).toInt()}% Pass ($passed/$total)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (failed > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.failed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$failed fail',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.failed),
                        ),
                      ),
                    ],
                    if (blocked > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blocked.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$blocked blocked',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blocked),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Interactive Dialog: Inspect all test cases for a specific QA Tester
  void _showTesterCasesDialog(BuildContext context, QATeamMemberStats stats, bool isDark) {
    String dialogFilter = 'All';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cases = stats.assignedCases.where((tc) {
              if (dialogFilter == 'All') return true;
              if (dialogFilter == 'Passed') return tc.status == TestCaseStatus.passed;
              if (dialogFilter == 'Failed') return tc.status == TestCaseStatus.failed;
              if (dialogFilter == 'Blocked') return tc.status == TestCaseStatus.blocked;
              if (dialogFilter == 'Untested') return tc.status == TestCaseStatus.untested || tc.status == TestCaseStatus.inProgress;
              return true;
            }).toList();

            return Dialog(
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 900,
                height: 650,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              child: Text(
                                stats.name.isNotEmpty ? stats.name.substring(0, 1).toUpperCase() : 'T',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Test Cases Assigned to ${stats.name}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  'Total: ${stats.total} | Solved: ${stats.passed} | Failed: ${stats.failed} | Blocked: ${stats.blocked}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter Pills inside Dialog
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildDialogFilterChip(
                          label: 'All (${stats.total})',
                          isSelected: dialogFilter == 'All',
                          onTap: () => setDialogState(() => dialogFilter = 'All'),
                          isDark: isDark,
                        ),
                        _buildDialogFilterChip(
                          label: 'Passed (${stats.passed})',
                          isSelected: dialogFilter == 'Passed',
                          color: AppColors.passed,
                          onTap: () => setDialogState(() => dialogFilter = 'Passed'),
                          isDark: isDark,
                        ),
                        _buildDialogFilterChip(
                          label: 'Failed (${stats.failed})',
                          isSelected: dialogFilter == 'Failed',
                          color: AppColors.failed,
                          onTap: () => setDialogState(() => dialogFilter = 'Failed'),
                          isDark: isDark,
                        ),
                        _buildDialogFilterChip(
                          label: 'Blocked (${stats.blocked})',
                          isSelected: dialogFilter == 'Blocked',
                          color: AppColors.blocked,
                          onTap: () => setDialogState(() => dialogFilter = 'Blocked'),
                          isDark: isDark,
                        ),
                        _buildDialogFilterChip(
                          label: 'Untested (${stats.untested})',
                          isSelected: dialogFilter == 'Untested',
                          color: isDark ? Colors.white70 : Colors.black87,
                          onTap: () => setDialogState(() => dialogFilter = 'Untested'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // Table of Test Cases
                    Expanded(
                      child: cases.isEmpty
                          ? Center(
                              child: Text(
                                'No test cases match filter "$dialogFilter".',
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: cases.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final tc = cases[index];
                                Color statusColor = AppColors.untested;
                                if (tc.status == TestCaseStatus.passed) statusColor = AppColors.passed;
                                if (tc.status == TestCaseStatus.failed) statusColor = AppColors.failed;
                                if (tc.status == TestCaseStatus.blocked) statusColor = AppColors.blocked;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // TC Code
                                      Container(
                                        width: 120,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tc.code,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Title & Module
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tc.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                Text(
                                                  'Module: ${tc.module}',
                                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                                ),
                                                Text(
                                                  '• Feature: ${tc.feature}',
                                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                                ),
                                                if (tc.executionDate != null)
                                                  Text(
                                                    '• Executed: ${tc.executionDate!.year}-${tc.executionDate!.month.toString().padLeft(2, '0')}-${tc.executionDate!.day.toString().padLeft(2, '0')}',
                                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Priority
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tc.priority.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Status Badge
                                      Container(
                                        width: 90,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          tc.status.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? activeColor : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}



