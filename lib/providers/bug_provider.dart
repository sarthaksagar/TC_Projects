import 'package:flutter/material.dart';
import '../models/bug_model.dart';
import '../repositories/bug_repository.dart';

class BugProvider extends ChangeNotifier {
  final BugRepository _repository;

  BugProvider({BugRepository? repository})
      : _repository = repository ?? BugRepository() {
    loadBugs();
  }

  List<BugModel> _bugs = [];
  bool _isLoading = false;

  List<BugModel> get bugs => _bugs;
  bool get isLoading => _isLoading;

  Future<void> loadBugs() async {
    _isLoading = true;
    notifyListeners();

    _bugs = await _repository.getBugs();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBug(BugModel bug) async {
    final newBug = await _repository.addBug(bug);
    _bugs.insert(0, newBug);
    notifyListeners();
  }

  Future<void> updateBugStatus(String id, BugStatus status) async {
    final index = _bugs.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bugs[index] = _bugs[index].copyWith(status: status);
      notifyListeners();
      try {
        await _repository.updateBugStatus(id, status);
      } catch (_) {}
    }
  }
}
