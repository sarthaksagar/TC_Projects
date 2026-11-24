import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

class UserRepository {
  SupabaseClient get _client => Supabase.instance.client;
  List<UserModel> _cachedUsers = [];

  Future<List<UserModel>> getUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      final list = (res as List<dynamic>)
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _cachedUsers = list;
      return list;
    } catch (e) {
      AppLogger.error('UserRepository', 'Failed to fetch users', e);
      return List.unmodifiable(_cachedUsers);
    }
  }

  Future<UserModel> addUser(UserModel user) async {
    try {
      final payload = user.toJson();
      await _client.from('profiles').upsert(payload);
      AppLogger.success('UserRepository', 'User ${user.email} saved to Supabase');
    } catch (e) {
      AppLogger.error('UserRepository', 'Failed to save user ${user.email}', e);
    }
    _cachedUsers.insert(0, user);
    return user;
  }

  Future<UserModel> toggleUserStatus(String userId, bool isActive) async {
    final index = _cachedUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final updated = _cachedUsers[index].copyWith(isActive: isActive);
      _cachedUsers[index] = updated;
      try {
        await _client
            .from('profiles')
            .update({'is_active': isActive}).eq('id', userId);
        AppLogger.success('UserRepository', 'User $userId status updated to $isActive');
      } catch (e) {
        AppLogger.error('UserRepository', 'Failed to update user status for $userId', e);
      }
      return updated;
    }
    throw Exception('User not found: $userId');
  }
}
