import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bug_model.dart';
import '../utils/app_logger.dart';

class BugRepository {
  SupabaseClient get _client => Supabase.instance.client;
  List<BugModel> _items = [];

  Future<List<BugModel>> getBugs() async {
    try {
      final res = await _client
          .from('bugs')
          .select()
          .order('created_at', ascending: false);
      final list = (res as List<dynamic>)
          .map((e) => BugModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _items = list;
      return list;
    } catch (e) {
      AppLogger.error('BugRepository', 'Failed to fetch bugs', e);
      return List.unmodifiable(_items);
    }
  }

  Future<BugModel> addBug(BugModel bug) async {
    _items.insert(0, bug);
    try {
      await _client.from('bugs').upsert(bug.toJson());
      AppLogger.success('BugRepository', 'Bug ${bug.ticketId} saved to Supabase');
    } catch (e) {
      AppLogger.error('BugRepository', 'Failed to save bug ${bug.ticketId}', e);
    }
    return bug;
  }

  Future<BugModel> updateBugStatus(String bugId, BugStatus status) async {
    final index = _items.indexWhere((b) => b.id == bugId);
    if (index != -1) {
      final updated = _items[index].copyWith(status: status);
      _items[index] = updated;
      try {
        await _client
            .from('bugs')
            .update({'status': status.name}).eq('id', bugId);
        AppLogger.success('BugRepository', 'Bug $bugId status updated to ${status.name}');
      } catch (e) {
        AppLogger.error('BugRepository', 'Failed to update bug status for $bugId', e);
      }
      return updated;
    }
    throw Exception('Bug not found: $bugId');
  }
}
