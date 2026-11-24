import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Derive a clean display name from email when no full_name is stored ──
  static String _nameFromEmail(String email, String role) {
    final prefix = email.split('@').first;
    // Convert email prefix to readable name: e.g. "john.doe" → "John Doe"
    final parts = prefix
        .replaceAll(RegExp(r'[_.\-]+'), ' ')
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .toList();
    final baseName = parts.isNotEmpty ? parts.join(' ') : email;
    return baseName;
  }

  // ── Derive role from email pattern or stored metadata ──────────────────
  static String _deriveRole(String email, String? metaRole) {
    final lower = email.toLowerCase();
    if (lower.contains('lead') ||
        lower.contains('admin') ||
        lower.contains('manager')) {
      return 'QA Lead';
    }
    if (lower.contains('tester') ||
        lower.contains('qa') ||
        lower.contains('member')) {
      return 'QA Team Member';
    }
    return metaRole ?? 'QA Team Member';
  }

  UserModel? get currentUser {
    final u = _client.auth.currentUser;
    if (u == null) return null;

    final email = u.email ?? '';
    final metaRole = u.userMetadata?['role']?.toString();
    final derivedRole = _deriveRole(email, metaRole);

    final metaName = u.userMetadata?['full_name']?.toString();
    final displayName = (metaName != null && metaName.isNotEmpty)
        ? metaName
        : _nameFromEmail(email, derivedRole);

    return UserModel(
      id: u.id,
      name: displayName,
      email: email,
      role: derivedRole,
      avatarUrl: u.userMetadata?['avatar_url'] ??
          'https://i.pravatar.cc/150?u=${u.id}',
      isActive: true,
      createdAt: DateTime.tryParse(u.createdAt) ?? DateTime.now(),
    );
  }

  bool get isAuthenticated => _client.auth.currentUser != null;

  Future<UserModel> login(String email, String password) async {
    final res =
        await _client.auth.signInWithPassword(email: email, password: password);
    final u = res.user;
    if (u != null) {
      return currentUser!;
    }

    throw 'Login failed: Invalid credentials';
  }

  Future<void> signUp(String email, String password,
      {String? fullName, String? role}) async {
    final derivedRole = _deriveRole(email, role);
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : _nameFromEmail(email, derivedRole);

    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': displayName,
        'role': derivedRole,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
