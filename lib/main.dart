import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'services/supabase_config.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/test_case_provider.dart';
import 'providers/test_suite_provider.dart';
import 'providers/test_plan_provider.dart';
import 'providers/test_execution_provider.dart';
import 'providers/bug_provider.dart';
import 'providers/report_provider.dart';
import 'providers/user_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/permission_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  runApp(const QATestCenterApp());
}

class QATestCenterApp extends StatefulWidget {
  const QATestCenterApp({super.key});

  @override
  State<QATestCenterApp> createState() => _QATestCenterAppState();
}

class _QATestCenterAppState extends State<QATestCenterApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => TestCaseProvider()),
        ChangeNotifierProvider(create: (_) => TestSuiteProvider()),
        ChangeNotifierProvider(create: (_) => TestPlanProvider()),
        ChangeNotifierProvider(create: (_) => TestExecutionProvider()),
        ChangeNotifierProvider(create: (_) => BugProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'VG_QATC - Test Management Center',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
