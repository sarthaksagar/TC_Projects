import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_builder.dart';
import '../widgets/left_navigation_drawer.dart';

class MainLayoutScreen extends StatelessWidget {
  final Widget child;

  const MainLayoutScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isDesktopOrTablet = !ResponsiveBuilder.isMobile(context);

    if (isDesktopOrTablet) {
      return Scaffold(
        body: Row(
          children: [
            LeftNavigationDrawer(currentPath: currentPath),
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top Header Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, size: 20),
                              tooltip: 'Notifications',
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.search_rounded, size: 20),
                              tooltip: 'Search',
                              onPressed: () {},
                            ),
                            const SizedBox(width: 16),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final user = authProvider.currentUser;
                                final name = user?.name ?? 'User';
                                final role = user?.role ?? 'QA Member';
                                final isLead = role.toLowerCase().contains('lead') || role.toLowerCase().contains('admin');

                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isLead ? AppColors.secondary : Theme.of(context).primaryColor,
                                      child: Icon(
                                        isLead ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        Text(
                                          role,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isLead ? AppColors.secondary : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Main Page Content
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: LeftNavigationDrawer(
          currentPath: currentPath,
          isMobileDrawer: true,
        ),
      ),
      body: SafeArea(child: child),
    );
  }
}
