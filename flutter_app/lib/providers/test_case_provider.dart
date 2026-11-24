import 'package:flutter/material.dart';
import '../models/test_case.dart';
import '../repositories/test_case_repository.dart';

class TestCaseProvider extends ChangeNotifier {
  final TestCaseRepository _repo = TestCaseRepository();
  List<TestCase> _cases = [];
  bool loading = false;
  List<TestCase> get cases => _cases;

  Future<void> fetchAll() async {
    loading = true;
    notifyListeners();
    try {
      _cases = await _repo.getAll();
    } catch (e) {
      // ignore for now
    }
    loading = false;
    notifyListeners();
  }

  Future<void> create(TestCase tc) async {
    loading = true;
    notifyListeners();
    try {
      final created = await _repo.create(tc);
      _cases.insert(0, created);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> update(TestCase tc) async {
    loading = true;
    notifyListeners();
    try {
      final updated = await _repo.update(tc);
      final idx = _cases.indexWhere((e) => e.id == updated.id);
      if (idx != -1) _cases[idx] = updated;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    loading = true;
    notifyListeners();
    try {
      await _repo.delete(id);
      _cases.removeWhere((e) => e.id == id);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
