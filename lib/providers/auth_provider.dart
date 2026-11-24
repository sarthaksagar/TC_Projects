import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/app_logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _authRepository.currentUser;
  bool get isAuthenticated => _authRepository.isAuthenticated;

  Future<bool> login(String email, String password) async {
    AppLogger.info('AuthProvider', 'Attempting login for: $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(email, password);
      _isLoading = false;
      AppLogger.success('AuthProvider', 'Login successful: $email');
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('AuthException: ', '').replaceAll('Exception: ', '');
      if (msg.contains('Invalid login credentials')) {
        _errorMessage = 'Invalid email or password. Please check your credentials or click Create Account.';
      } else if (msg.contains('Email not confirmed')) {
        _errorMessage = 'Email address not confirmed yet. Please check your inbox or disable email confirmation in Supabase.';
      } else {
        _errorMessage = msg;
      }
      AppLogger.error('AuthProvider', 'Login failed: $_errorMessage', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? fullName, String? role}) async {
    AppLogger.info('AuthProvider', 'Attempting signUp for: $email (Name: $fullName)');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signUp(email, password, fullName: fullName, role: role);
      // Attempt login immediately after sign up
      try {
        await _authRepository.login(email, password);
      } catch (_) {}
      _isLoading = false;
      AppLogger.success('AuthProvider', 'SignUp & authentication successful: $email');
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('AuthException: ', '').replaceAll('Exception: ', '');
      if (msg.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
        _errorMessage = 'Supabase email rate limit exceeded. Please disable "Confirm email" in Supabase settings or wait a few minutes.';
      } else {
        _errorMessage = msg;
      }
      AppLogger.error('AuthProvider', 'SignUp failed: $_errorMessage', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    AppLogger.warn('AuthProvider', 'User logging out: ${currentUser?.email ?? "Unknown"}');
    _isLoading = true;
    notifyListeners();
    await _authRepository.logout();
    _isLoading = false;
    AppLogger.info('AuthProvider', 'User logged out successfully');
    notifyListeners();
  }
}
