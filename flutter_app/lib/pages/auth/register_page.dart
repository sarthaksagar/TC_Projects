import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String _selectedRole = 'QA Team Member';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Create a new QA Account',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('QA Lead'),
                    selected: _selectedRole == 'QA Lead',
                    selectedColor: Colors.blue,
                    onSelected: (_) =>
                        setState(() => _selectedRole = 'QA Lead'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Text('QA Team Member'),
                    selected: _selectedRole == 'QA Team Member',
                    selectedColor: Colors.blue,
                    onSelected: (_) =>
                        setState(() => _selectedRole = 'QA Team Member'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
                controller: _email,
                decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 8),
            TextField(
                controller: _pass,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await auth.signUp(
                          _email.text.trim(),
                          _pass.text,
                          role: _selectedRole,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Registered — check your email')));
                        context.goNamed('login');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
              child: _loading ? CircularProgressIndicator() : Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
