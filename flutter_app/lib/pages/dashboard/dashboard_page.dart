import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard'), actions: [
        IconButton(onPressed: () { auth.signOut(); context.goNamed('login'); }, icon: Icon(Icons.logout))
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${auth.user?.email ?? 'User'}', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.goNamed('test_cases'), child: Text('Test Cases')),
            SizedBox(height: 8),
            ElevatedButton(onPressed: () => context.goNamed('test_plans'), child: Text('Test Plans')),
            SizedBox(height: 8),
            ElevatedButton(onPressed: () => context.goNamed('bugs'), child: Text('Bugs')),
          ],
        ),
      ),
    );
  }
}
