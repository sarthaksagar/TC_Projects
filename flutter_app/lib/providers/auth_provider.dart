import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  User? _user;
  bool get isAuthenticated => _user != null;
  User? get user => _user;
  String get currentRole =>
      _user?.userMetadata?['role']?.toString() ?? 'QA Team Member';

  AuthProvider() {
    _user = _auth.currentUser;
    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((ev) {
      _user = Supabase.instance.client.auth.currentUser;
      notifyListeners();
    });
  }

  Future<AuthResponse?> signIn(String email, String password) async {
    final res = await _auth.signIn(email, password);
    _user = _auth.currentUser;
    notifyListeners();
    return res;
  }

  Future<AuthResponse?> signUp(String email, String password,
      {String role = 'QA Team Member'}) async {
    final res = await _auth.signUp(email, password, role: role);
    _user = _auth.currentUser;
    notifyListeners();
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async => _auth.resetPassword(email);
}
