import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment.dart';
import '../models/word_list.dart';

/// Slice 14 — 作業服務層
class AssignmentService {
  final SupabaseClient _db = Supabase.instance.client;

  // ========== 教師端 ==========

  /// 教師建立一筆作業（對整班指派某字庫）
  Future<void> createAssignment({
    required String classroomId,
    required String wordListId,
    required DateTime dueAt,
  }) async {
    await _db.from('assignments').insert({
      'classroom_id': classroomId,
      'word_list_id': wordListId,
      'due_at': dueAt.toUtc().toIso8601String(),
    });
  }

  /// 教師刪除作業
  Future<void> deleteAssignment(String assignmentId) async {
    await _db.from('assignments').delete().eq('id', assignmentId);
  }

  /// 教師取得某班的作業列表（走 RPC，SECURITY DEFINER）
  Future<List<ClassroomAssignment>> fetchClassroomAssignments(
      String classroomId) async {
    final rows = await _db.rpc(
      'get_classroom_assignments',
      params: {'p_classroom_id': classroomId},
    );
    return (rows as List)
        .map((e) =>
            ClassroomAssignment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 教師取得可選的字庫清單（word_lists 裡全部公開字庫）
  Future<List<WordList>> fetchAvailableWordLists() async {
    final rows = await _db
        .from('word_lists')
        .select('id, name, language, exam_type, total_words')
        .order('language')
        .order('name');
    return (rows as List)
        .map((e) => WordList.fromJson(
              Map<String, dynamic>.from(e as Map),
              isJoined: false,
              reviewedCount: 0,
            ))
        .toList();
  }

  // ========== 學生端 ==========

  /// 學生取得自己的所有作業（含進度）
  Future<List<Assignment>> fetchMyAssignments() async {
    final rows = await _db.rpc('get_my_assignments');
    return (rows as List)
        .map((e) =>
            Assignment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 複習完一張卡後記錄作業進度（Server 端決定屬於哪些作業）
  /// 失敗靜默，不拖慢複習流程
  Future<void> recordProgress(String wordId) async {
    try {
      await _db.rpc(
        'record_assignment_progress',
        params: {'p_word_id': wordId},
      );
    } catch (_) {
      // 靜默失敗，不影響複習
    }
  }
}
