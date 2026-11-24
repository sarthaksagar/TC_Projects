import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';
import '../models/test_case.dart';

class TestCaseRepository {
  final SupabaseClient client = SupabaseManager.client;
  final String table = 'test_cases';

  Future<List<TestCase>> getAll() async {
    final data = await client.from(table).select().order('created_at', ascending: false);
    return (data as List<dynamic>).map((e) => TestCase.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<TestCase> create(TestCase tc) async {
    final payload = tc.toMap();
    final data = await client.from(table).insert(payload).select().single();
    return TestCase.fromMap(Map<String, dynamic>.from(data));
  }

  Future<TestCase> update(TestCase tc) async {
    final payload = tc.toMap();
    final data = await client.from(table).update(payload).eq('id', tc.id).select().single();
    return TestCase.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> delete(String id) async {
    await client.from(table).delete().eq('id', id);
  }
}
