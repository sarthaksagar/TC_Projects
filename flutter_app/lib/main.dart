import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_client.dart';
import 'providers/auth_provider.dart';
import 'providers/test_case_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TestCaseProvider()),
      ],
      child: MaterialApp.router(
        title: 'TC Project',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        routerConfig: router,
      ),
    );
  }
}
