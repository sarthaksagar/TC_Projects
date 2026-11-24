import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/test_suite_model.dart';
import 'package:vg_qatc/providers/test_suite_provider.dart';
import 'package:vg_qatc/repositories/test_suite_repository.dart';

class FakeTestSuiteRepository extends TestSuiteRepository {
  List<TestSuiteModel> store = [];

  @override
  List<TestSuiteModel> get cachedItems => List.from(store);

  @override
  Future<List<TestSuiteModel>> getTestSuites() async => List.from(store);

  @override
  Future<TestSuiteModel> addTestSuite(TestSuiteModel suite) async {
    store.insert(0, suite);
    return suite;
  }

  @override
  Future<void> updateTestSuite(TestSuiteModel suite) async {
    final idx = store.indexWhere((s) => s.id == suite.id);
    if (idx != -1) store[idx] = suite;
  }

  @override
  Future<void> deleteTestSuite(String id) async {
    store.removeWhere((s) => s.id == id);
  }
}

void main() {
  group('TestSuiteProvider', () {
    late FakeTestSuiteRepository fakeRepo;
    late TestSuiteProvider provider;

    final suite1 = TestSuiteModel(
      id: 's-1',
      name: 'Auth Suite',
      description: 'Authentication flows',
      totalCases: 10,
      passedCases: 8,
      failedCases: 2,
      blockedCases: 0,
      createdBy: 'QA Lead',
      createdAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      fakeRepo = FakeTestSuiteRepository();
      fakeRepo.store = [suite1];
      provider = TestSuiteProvider(repository: fakeRepo);
    });

    test('initial state loads suites', () async {
      await provider.loadTestSuites();
      expect(provider.suites.length, 1);
      expect(provider.testSuites.length, 1);
      expect(provider.isLoading, false);
    });

    test('addTestSuite prepends to list', () async {
      await provider.loadTestSuites();

      final newSuite = TestSuiteModel(
        id: 's-2',
        name: 'Payment Suite',
        description: 'Payment gateway tests',
        totalCases: 5,
        passedCases: 5,
        failedCases: 0,
        blockedCases: 0,
        createdBy: 'QA Lead',
        createdAt: DateTime.now(),
      );

      await provider.addTestSuite(newSuite);

      expect(provider.suites.length, 2);
      expect(provider.suites.first.id, 's-2');
    });

    test('updateTestSuite updates existing suite in list', () async {
      await provider.loadTestSuites();

      final updated = suite1.copyWith(name: 'Updated Auth Suite', totalCases: 15);
      await provider.updateTestSuite(updated);

      final found = provider.suites.firstWhere((s) => s.id == 's-1');
      expect(found.name, 'Updated Auth Suite');
      expect(found.totalCases, 15);
    });

    test('deleteTestSuite removes suite from list', () async {
      await provider.loadTestSuites();

      await provider.deleteTestSuite('s-1');

      expect(provider.suites.isEmpty, true);
      expect(fakeRepo.store.isEmpty, true);
    });
  });
}

