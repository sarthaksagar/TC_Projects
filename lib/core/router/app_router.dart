import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/test_suite_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/bug_tracking_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_layout_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/test_cases_screen.dart';
import '../../screens/test_execution_screen.dart';
import '../../screens/test_plans_screen.dart';
import '../../screens/test_suite_detail_screen.dart';
import '../../screens/test_suites_screen.dart';
import '../../screens/users_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authProvider,
      initialLocation: authProvider.isAuthenticated ? '/dashboard' : '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final goingToAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/forgot';

        if (!isAuthenticated && !goingToAuth) return '/login';
        if (isAuthenticated && goingToAuth) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainLayoutScreen(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              redirect: (_, __) => '/dashboard',
            ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            GoRoute(
              path: '/test-cases',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TestCasesScreen()),
            ),
            GoRoute(
              path: '/test-suites',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TestSuitesScreen()),
            ),
            GoRoute(
              path: '/test-suites/:id',
              pageBuilder: (context, state) {
                final suiteId = state.pathParameters['id'];
                final suite = state.extra as TestSuiteModel?;
                return NoTransitionPage(
                  child: TestSuiteDetailScreen(suite: suite, suiteId: suiteId),
                );
              },
            ),
            GoRoute(
              path: '/test-plans',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TestPlansScreen()),
            ),
            GoRoute(
              path: '/test-execution',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TestExecutionScreen()),
            ),
            GoRoute(
              path: '/bug-tracking',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BugTrackingScreen()),
            ),
            GoRoute(
              path: '/reports',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ReportsScreen()),
            ),
            GoRoute(
              path: '/users',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: UsersScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
