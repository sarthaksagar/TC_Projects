import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class LeftNavigationDrawer extends StatelessWidget {
  final String currentPath;
  final bool isMobileDrawer;

  const LeftNavigationDrawer({
    super.key,
    required this.currentPath,
    this.isMobileDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final navItems = [
      _NavItem(AppConstants.navDashboard, '/dashboard', Icons.dashboard_rounded),
      _NavItem(AppConstants.navTestCases, '/test-cases', Icons.fact_check_rounded),
      _NavItem(AppConstants.navTestSuites, '/test-suites', Icons.folder_special_rounded),
      _NavItem(AppConstants.navTestPlans, '/test-plans', Icons.assignment_rounded),
      _NavItem(AppConstants.navTestExecution, '/test-execution', Icons.play_circle_fill_rounded),
      _NavItem(AppConstants.navBugTracking, '/bug-tracking', Icons.bug_report_rounded),
      _NavItem(AppConstants.navReports, '/reports', Icons.analytics_rounded),
      _NavItem(AppConstants.navUsers, '/users', Icons.people_alt_rounded),
      _NavItem(AppConstants.navSettings, '/settings', Icons.settings_rounded),
    ];

    final isDark = themeProvider.isDarkMode;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Logo & Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Test Management',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation Links List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentPath.startsWith(item.route);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        size: 20,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                      onTap: () {
                        if (isMobileDrawer) {
                          Navigator.of(context).pop();
                        }
                        context.go(item.route);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // User Profile & Theme Toggle Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Theme Toggle Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 18,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: isDark,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => themeProvider.toggleTheme(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // User Info Card & Logout
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          user?.avatarUrl ?? 'https://i.pravatar.cc/150?u=user',
                        ),
                        onBackgroundImageError: (_, __) {},
                        child: Text(
                          (user?.name ?? 'Q').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.name ?? 'QA Lead User',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              user?.role ?? 'Lead Tester',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.failed),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) context.go('/login');
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
}

class _NavItem {
  final String title;
  final String route;
  final IconData icon;

  _NavItem(this.title, this.route, this.icon);
}
