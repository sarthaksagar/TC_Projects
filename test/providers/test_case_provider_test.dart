import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/test_case_model.dart';
import 'package:vg_qatc/providers/test_case_provider.dart';
import 'package:vg_qatc/repositories/test_case_repository.dart';

class FakeTestCaseRepository extends TestCaseRepository {
  List<TestCaseModel> store = [];

  @override
  List<TestCaseModel> get cachedItems => List.from(store);

  @override
  Future<List<TestCaseModel>> getTestCases() async => List.from(store);

  @override
  Future<TestCaseModel> addTestCase(TestCaseModel testCase) async {
    store.insert(0, testCase);
    return testCase;
  }

  @override
  Future<void> addTestCasesBatch(List<TestCaseModel> testCases) async {
    store.insertAll(0, testCases);
  }

  @override
  Future<TestCaseModel> updateTestCase(TestCaseModel testCase) async {
    final idx = store.indexWhere((tc) => tc.id == testCase.id);
    if (idx != -1) store[idx] = testCase;
    return testCase;
  }

  @override
  Future<void> updateTestCasesBatch(List<TestCaseModel> updatedCases) async {
    for (final updated in updatedCases) {
      final idx = store.indexWhere((tc) => tc.id == updated.id);
      if (idx != -1) store[idx] = updated;
    }
  }

  @override
  Future<void> deleteTestCase(String id) async {
    store.removeWhere((tc) => tc.id == id);
  }

  @override
  Future<void> clearAll() async {
    store.clear();
  }
}

void main() {
  group('TestCaseProvider', () {
    late FakeTestCaseRepository fakeRepo;
    late TestCaseProvider provider;

    final tc1 = TestCaseModel(
      id: '1',
      code: 'TC-101',
      title: 'Valid Login',
      description: 'Checks login',
      module: 'Auth',
      feature: 'Login',
      steps: ['Step 1'],
      expectedResult: 'Passed',
      status: TestCaseStatus.passed,
      priority: TestCasePriority.high,
      assignedTo: 'Alice',
      createdBy: 'Lead',
      updatedAt: DateTime(2024, 1, 1),
    );

    final tc2 = TestCaseModel(
      id: '2',
      code: 'TC-102',
      title: 'Invalid Password',
      description: 'Checks error banner',
      module: 'Auth',
      feature: 'Login',
      steps: ['Step 1'],
      expectedResult: 'Failed',
      status: TestCaseStatus.failed,
      priority: TestCasePriority.medium,
      assignedTo: 'Bob',
      createdBy: 'Lead',
      updatedAt: DateTime(2024, 1, 2),
    );

    final tc3 = TestCaseModel(
      id: '3',
      code: 'TC-201',
      title: 'Payment Checkout',
      description: 'Stripe integration',
      module: 'Payment',
      feature: 'Checkout',
      steps: ['Step 1'],
      expectedResult: 'Passed',
      status: TestCaseStatus.untested,
      priority: TestCasePriority.critical,
      assignedTo: 'Charlie',
      createdBy: 'Lead',
      updatedAt: DateTime(2024, 1, 3),
    );

    setUp(() {
      fakeRepo = FakeTestCaseRepository();
      fakeRepo.store = [tc1, tc2, tc3];
      provider = TestCaseProvider(repository: fakeRepo);
    });

    test('initial load populates testCases from repository', () async {
      await provider.loadTestCases();
      expect(provider.testCases.length, 3);
      expect(provider.allRawCases.length, 3);
    });

    group('searching and filtering', () {
      test('filters by search query matching title', () async {
        await provider.loadTestCases();
        provider.setSearchQuery('Login');

        expect(provider.testCases.length, 2);
        expect(provider.testCases.any((tc) => tc.code == 'TC-201'), false);
      });

      test('filters by search query matching module', () async {
        await provider.loadTestCases();
        provider.setSearchQuery('Payment');

        expect(provider.testCases.length, 1);
        expect(provider.testCases.first.code, 'TC-201');
      });

      test('filters by status filter', () async {
        await provider.loadTestCases();
        provider.setStatusFilter('failed');

        expect(provider.testCases.length, 1);
        expect(provider.testCases.first.code, 'TC-102');
      });

      test('combines search query and status filter', () async {
        await provider.loadTestCases();
        provider.setSearchQuery('Login');
        provider.setStatusFilter('passed');

        expect(provider.testCases.length, 1);
        expect(provider.testCases.first.code, 'TC-101');
      });
    });

    group('CRUD operations', () {
      test('addTestCase inserts at the top and updates state', () async {
        await provider.loadTestCases();

        final newCase = TestCaseModel(
          id: '4',
          code: 'TC-301',
          title: 'Export CSV',
          description: '',
          steps: [],
          expectedResult: 'Pass',
          status: TestCaseStatus.untested,
          priority: TestCasePriority.low,
          assignedTo: 'Alice',
          createdBy: 'Lead',
          updatedAt: DateTime.now(),
        );

        await provider.addTestCase(newCase);

        expect(provider.testCases.length, 4);
        expect(provider.testCases.first.code, 'TC-301');
      });

      test('updateTestCase updates matching item in place', () async {
        await provider.loadTestCases();

        final updated = tc1.copyWith(title: 'Updated Login Title', status: TestCaseStatus.failed);
        await provider.updateTestCase(updated);

        final found = provider.testCases.firstWhere((tc) => tc.id == '1');
        expect(found.title, 'Updated Login Title');
        expect(found.status, TestCaseStatus.failed);
      });

      test('deleteTestCase removes case from list', () async {
        await provider.loadTestCases();

        await provider.deleteTestCase('2');

        expect(provider.testCases.length, 2);
        expect(provider.testCases.any((tc) => tc.id == '2'), false);
      });

      test('clearAllTestCases empties the test cases', () async {
        await provider.loadTestCases();

        await provider.clearAllTestCases();

        expect(provider.testCases.isEmpty, true);
        expect(fakeRepo.store.isEmpty, true);
      });
    });
  });
}

