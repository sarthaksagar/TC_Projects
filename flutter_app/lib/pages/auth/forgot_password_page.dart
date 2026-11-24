import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await auth.resetPassword(_email.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset email sent')));
                        Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
              child: _loading ? CircularProgressIndicator() : Text('Send Reset Email'),
            ),
          ],
        ),
      ),
    );
  }
}
