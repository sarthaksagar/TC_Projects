import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/test_execution_model.dart';
import '../utils/app_logger.dart';

class TestExecutionRepository {
  SupabaseClient get _client => Supabase.instance.client;
  List<TestExecutionModel> _items = [];

  Future<List<TestExecutionModel>> getExecutions() async {
    try {
      final res = await _client
          .from('test_executions')
          .select()
          .order('started_at', ascending: false);
      final list = (res as List<dynamic>)
          .map((e) => TestExecutionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _items = list;
      return list;
    } catch (e) {
      AppLogger.error('TestExecutionRepository', 'Failed to fetch executions', e);
      return List.unmodifiable(_items);
    }
  }

  Future<TestExecutionModel> addExecution(TestExecutionModel execution) async {
    _items.insert(0, execution);
    try {
      await _client.from('test_executions').upsert(execution.toJson());
      AppLogger.success('TestExecutionRepository', 'Execution ${execution.executionName} saved to Supabase');
    } catch (e) {
      AppLogger.error('TestExecutionRepository', 'Failed to save execution ${execution.executionName}', e);
    }
    return execution;
  }
}
