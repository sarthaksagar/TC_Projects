import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 8),
            TextField(controller: _pass, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await auth.signIn(_email.text.trim(), _pass.text);
                        if (auth.isAuthenticated) {
                          context.goNamed('dashboard');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check your credentials')));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
              child: _loading ? CircularProgressIndicator() : Text('Login'),
            ),
            TextButton(onPressed: () => context.goNamed('register'), child: Text('Register')),
            TextButton(onPressed: () => context.goNamed('forgot_password'), child: Text('Forgot Password')),
          ],
        ),
      ),
    );
  }
}
