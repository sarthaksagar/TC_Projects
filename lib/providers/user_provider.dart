import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;

  UserProvider({UserRepository? repository})
      : _repository = repository ?? UserRepository() {
    loadUsers();
  }

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers();
      AppLogger.success('UserProvider', 'Loaded ${_users.length} users');
    } catch (e) {
      _errorMessage = 'Failed to load users.';
      AppLogger.error('UserProvider', 'Failed to load users', e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUser(UserModel user) async {
    final newUser = await _repository.addUser(user);
    _users.insert(0, newUser);
    notifyListeners();
  }

  Future<void> toggleUserStatus(String id) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      final newStatus = !_users[index].isActive;
      _users[index] = _users[index].copyWith(isActive: newStatus);
      notifyListeners();
      try {
        await _repository.toggleUserStatus(id, newStatus);
      } catch (e) {
        AppLogger.error('UserProvider', 'Failed to toggle user status for $id', e);
        // Revert on failure
        _users[index] = _users[index].copyWith(isActive: !newStatus);
        notifyListeners();
      }
    }
  }
}
