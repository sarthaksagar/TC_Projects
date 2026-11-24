import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/test_plan_model.dart';
import 'package:vg_qatc/providers/test_plan_provider.dart';
import 'package:vg_qatc/repositories/test_plan_repository.dart';

class FakeTestPlanRepository extends TestPlanRepository {
  List<TestPlanModel> store = [];

  @override
  Future<List<TestPlanModel>> getTestPlans() async => List.from(store);

  @override
  Future<TestPlanModel> addTestPlan(TestPlanModel plan) async {
    store.insert(0, plan);
    return plan;
  }

  @override
  Future<void> updateTestPlan(TestPlanModel plan) async {
    final idx = store.indexWhere((p) => p.id == plan.id);
    if (idx != -1) store[idx] = plan;
  }

  @override
  Future<void> deleteTestPlan(String id) async {
    store.removeWhere((p) => p.id == id);
  }
}

void main() {
  group('TestPlanProvider', () {
    late FakeTestPlanRepository fakeRepo;
    late TestPlanProvider provider;

    final plan1 = TestPlanModel(
      id: 'p-1',
      title: 'Regression Plan Q1',
      version: 'v1.0',
      targetRelease: 'Rel 1.0',
      status: 'Active',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 15),
      suiteCount: 3,
      totalCasesCount: 50,
      owner: 'QA Lead',
    );

    setUp(() {
      fakeRepo = FakeTestPlanRepository();
      fakeRepo.store = [plan1];
      provider = TestPlanProvider(repository: fakeRepo);
    });

    test('loads test plans', () async {
      await provider.loadTestPlans();
      expect(provider.plans.length, 1);
      expect(provider.plans.first.title, 'Regression Plan Q1');
      expect(provider.isLoading, false);
      expect(provider.errorMessage, null);
    });

    test('addTestPlan inserts new plan', () async {
      await provider.loadTestPlans();

      final newPlan = TestPlanModel(
        id: 'p-2',
        title: 'Smoke Test Plan',
        version: 'v1.1',
        targetRelease: 'Rel 1.1',
        status: 'Draft',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        suiteCount: 1,
        totalCasesCount: 10,
        owner: 'QA Tester',
      );

      await provider.addTestPlan(newPlan);

      expect(provider.plans.length, 2);
      expect(provider.plans.first.id, 'p-2');
    });

    test('updateTestPlan updates plan in list', () async {
      await provider.loadTestPlans();

      final updated = plan1.copyWith(status: 'Completed');
      await provider.updateTestPlan(updated);

      final found = provider.plans.firstWhere((p) => p.id == 'p-1');
      expect(found.status, 'Completed');
    });

    test('deleteTestPlan removes plan from list', () async {
      await provider.loadTestPlans();

      await provider.deleteTestPlan('p-1');

      expect(provider.plans.isEmpty, true);
    });
  });
}

