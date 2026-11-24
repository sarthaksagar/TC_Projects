import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/test_plan_model.dart';
import '../utils/app_logger.dart';

class TestPlanRepository {
  SupabaseClient get _client => Supabase.instance.client;
  List<TestPlanModel> _items = [];

  Future<List<TestPlanModel>> getTestPlans() async {
    try {
      final res = await _client
          .from('test_plans')
          .select()
          .order('start_date', ascending: false);
      final list = (res as List<dynamic>)
          .map((e) => TestPlanModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _items = list;
      return list;
    } catch (e) {
      AppLogger.error('TestPlanRepository', 'Failed to fetch test plans', e);
      return List.unmodifiable(_items);
    }
  }

  Future<TestPlanModel> addTestPlan(TestPlanModel plan) async {
    _items.insert(0, plan);
    try {
      await _client.from('test_plans').upsert(plan.toJson());
      AppLogger.success('TestPlanRepository', 'Test plan ${plan.title} saved to Supabase');
    } catch (e) {
      AppLogger.error('TestPlanRepository', 'Failed to save test plan ${plan.title}', e);
    }
    return plan;
  }

  Future<void> updateTestPlan(TestPlanModel plan) async {
    final index = _items.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _items[index] = plan;
    }
    try {
      await _client.from('test_plans').upsert(plan.toJson());
      AppLogger.success('TestPlanRepository', 'Test plan ${plan.title} updated in Supabase');
    } catch (e) {
      AppLogger.error('TestPlanRepository', 'Failed to update test plan ${plan.title}', e);
    }
  }

  Future<void> deleteTestPlan(String id) async {
    _items.removeWhere((p) => p.id == id);
    try {
      await _client.from('test_plans').delete().eq('id', id);
      AppLogger.success('TestPlanRepository', 'Test plan $id deleted from Supabase');
    } catch (e) {
      AppLogger.error('TestPlanRepository', 'Failed to delete test plan $id', e);
    }
  }
}
