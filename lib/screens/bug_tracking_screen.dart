import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/bug_model.dart';
import '../providers/auth_provider.dart';
import '../providers/bug_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/toast_utils.dart';

class BugTrackingScreen extends StatelessWidget {
  const BugTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BugProvider>(context);
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
                    'Defect & Bug Tracking',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log, triage, and track resolution lifecycle of software defects',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showReportBugDialog(context),
                icon: const Icon(Icons.bug_report_rounded, size: 18),
                label: const Text('Report Defect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.failed,
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
                    itemCount: provider.bugs.length,
                    itemBuilder: (context, index) {
                      final bug = provider.bugs[index];
                      return _buildBugCard(context, bug, provider, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBugCard(BuildContext context, BugModel bug, BugProvider provider, bool isDark) {
    Color severityColor;
    switch (bug.severity) {
      case BugSeverity.blocker:
      case BugSeverity.critical:
        severityColor = AppColors.failed;
        break;
      case BugSeverity.major:
        severityColor = Colors.orange;
        break;
      case BugSeverity.minor:
        severityColor = AppColors.secondary;
        break;
    }

    Color statusColor;
    switch (bug.status) {
      case BugStatus.open:
        statusColor = AppColors.failed;
        break;
      case BugStatus.inProgress:
        statusColor = AppColors.secondary;
        break;
      case BugStatus.resolved:
      case BugStatus.closed:
        statusColor = AppColors.passed;
        break;
      case BugStatus.rejected:
        statusColor = AppColors.untested;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bug.ticketId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: severityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      bug.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<BugStatus>(
                    value: bug.status,
                    dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    icon: Icon(Icons.arrow_drop_down, color: statusColor),
                    onChanged: (newStatus) async {
                      if (newStatus != null) {
                        await provider.updateBugStatus(bug.id, newStatus);
                        if (context.mounted) {
                          ToastUtils.showInfo(context, '${bug.ticketId} status updated to ${newStatus.name.toUpperCase()}');
                        }
                      }
                    },
                    items: BugStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              bug.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned to ${bug.assignedTo} • Reported by ${bug.reportedBy}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  DateFormatter.formatDateTime(bug.createdAt),
                  style: TextStyle(
                    fontSize: 11,
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

  void _showReportBugDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final currentUserName = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'QA Member';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report New Defect'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Bug Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description / Steps to Reproduce'),
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
                final newBug = BugModel(
                  id: 'b-${DateTime.now().millisecondsSinceEpoch}',
                  ticketId: 'BUG-${400 + DateTime.now().second}',
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  testCaseCode: 'TC-101',
                  severity: BugSeverity.critical,
                  status: BugStatus.open,
                  assignedTo: currentUserName,
                  reportedBy: currentUserName,
                  createdAt: DateTime.now(),
                );
                await Provider.of<BugProvider>(context, listen: false).addBug(newBug);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ToastUtils.showSuccess(context, 'Defect logged successfully!');
                }
              },
              child: const Text('Submit Defect'),
            ),
          ],
        );
      },
    );
  }
}
