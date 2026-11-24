import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class AuthService {
  final SupabaseClient client = SupabaseManager.client;

  Future<AuthResponse> signUp(String email, String password,
      {String role = 'QA Team Member'}) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final res =
        await client.auth.signInWithPassword(email: email, password: password);
    return res;
  }

  Future<void> signOut() => client.auth.signOut();

  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);

  User? get currentUser => client.auth.currentUser;
}
