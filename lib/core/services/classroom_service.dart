import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/classroom.dart';

/// Slice 12 — 教師班級系統服務層
///
/// 教師:建立/列表/重生邀請碼/刪除/看成員/移除成員
/// 學生:加入/退出/看自己加入的班級
class ClassroomService {
  final SupabaseClient _db = Supabase.instance.client;

  // ========== 教師端 ==========

  /// 取得目前登入教師建立的所有班級(含 member_count)
  Future<List<Classroom>> fetchMyClassrooms() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _db
        .from('classrooms')
        .select('*, classroom_members(count)')
        .eq('teacher_id', userId)
        .order('created_at', ascending: false);

    return (rows as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      // classroom_members 回傳 [{count: N}],展平成 member_count
      final countList = json['classroom_members'] as List?;
      final count = (countList != null && countList.isNotEmpty)
          ? (countList.first as Map)['count'] as int? ?? 0
          : 0;
      json['member_count'] = count;
      json.remove('classroom_members');
      return Classroom.fromJson(json);
    }).toList();
  }

  /// 建立新班級(邀請碼自動生成,碰撞時重試一次)
  Future<Classroom> createClassroom(String name) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw StateError('未登入');

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final row = await _db
            .from('classrooms')
            .insert({
              'name': name,
              'teacher_id': userId,
              'invite_code': _generateInviteCode(),
            })
            .select()
            .single();
        final json = Map<String, dynamic>.from(row);
        json['member_count'] = 0;
        return Classroom.fromJson(json);
      } on PostgrestException catch (e) {
        if (e.code == '23505' && attempt == 0) continue;
        rethrow;
      }
    }
    throw StateError('邀請碼生成失敗,請重試');
  }

  /// 重新產生邀請碼(舊碼自動失效)
  Future<Classroom> regenerateInviteCode(String classroomId) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final row = await _db
            .from('classrooms')
            .update({'invite_code': _generateInviteCode()})
            .eq('id', classroomId)
            .select()
            .single();
        final json = Map<String, dynamic>.from(row);
        json['member_count'] = 0;
        return Classroom.fromJson(json);
      } on PostgrestException catch (e) {
        if (e.code == '23505' && attempt == 0) continue;
        rethrow;
      }
    }
    throw StateError('邀請碼生成失敗,請重試');
  }

  /// 刪除整個班級(會 cascade 刪除 classroom_members)
  Future<void> deleteClassroom(String classroomId) async {
    await _db.from('classrooms').delete().eq('id', classroomId);
  }

  /// 取得班級成員列表(透過 RPC,含 email)
  Future<List<ClassroomMember>> fetchMembers(String classroomId) async {
    final rows = await _db.rpc(
      'get_classroom_members',
      params: {'p_classroom_id': classroomId},
    );
    return (rows as List)
        .map((e) => ClassroomMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 移除某位學生(用 classroom_members.id)
  Future<void> removeMember(String memberId) async {
    await _db.from('classroom_members').delete().eq('id', memberId);
  }

  // ========== 學生端 ==========

  /// 取得目前登入學生已加入的所有班級(走 RPC 避免 RLS 遞迴)
  Future<List<Classroom>> fetchJoinedClassrooms() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _db.rpc('get_my_student_classrooms');
    return (rows as List)
        .map((raw) => Classroom.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  /// 學生用邀請碼加入班級,回傳 classroom_id
  /// 失敗時拋 [ClassroomJoinException] 含中文訊息
  Future<String> joinByInviteCode(String code) async {
    try {
      final result = await _db.rpc(
        'join_classroom_by_invite_code',
        params: {'p_invite_code': code},
      );
      return result as String;
    } on PostgrestException catch (e) {
      throw ClassroomJoinException(e.message);
    }
  }

  /// 學生退出班級
  Future<void> leaveClassroom(String classroomId) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    await _db
        .from('classroom_members')
        .delete()
        .eq('classroom_id', classroomId)
        .eq('student_id', userId);
  }

  // ========== 內部工具 ==========

  static const _codeAlphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 去掉易混淆的 0,1,I,O
  final _rng = Random.secure();

  String _generateInviteCode() {
    return List.generate(
      8,
      (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)],
    ).join();
  }

  // ========== 教師：學生進度 ==========

  /// 教師查詢班級內特定學生的整體複習統計
  /// 走 RPC get_classroom_student_progress（SECURITY DEFINER）
  Future<StudentProgress> fetchStudentProgress({
    required String classroomId,
    required String studentId,
  }) async {
    final rows = await _db.rpc(
      'get_classroom_student_progress',
      params: {
        'p_classroom_id': classroomId,
        'p_student_id': studentId,
      },
    );
    final list = rows as List;
    if (list.isEmpty) {
      return StudentProgress(
        studentId: studentId,
        wordsStarted: 0,
        totalReviews: 0,
        correctReviews: 0,
        avgStability: 0,
        lastReviewedAt: null,
      );
    }
    final row = Map<String, dynamic>.from(list.first as Map);
    return StudentProgress(
      studentId: studentId,
      wordsStarted: (row['words_started'] as num?)?.toInt() ?? 0,
      totalReviews: (row['total_reviews'] as num?)?.toInt() ?? 0,
      correctReviews: (row['correct_reviews'] as num?)?.toInt() ?? 0,
      avgStability: (row['avg_stability'] as num?)?.toDouble() ?? 0.0,
      lastReviewedAt: row['last_reviewed_at'] != null
          ? DateTime.parse(row['last_reviewed_at'] as String)
          : null,
    );
  }
}

/// 學生加入班級時的錯誤訊息(可直接 .message 顯示給使用者)
class ClassroomJoinException implements Exception {
  final String message;
  ClassroomJoinException(this.message);

  @override
  String toString() => message;
}

/// 教師查看特定學生複習統計
class StudentProgress {
  final String studentId;
  final int wordsStarted;
  final int totalReviews;
  final int correctReviews;
  final double avgStability;
  final DateTime? lastReviewedAt;

  const StudentProgress({
    required this.studentId,
    required this.wordsStarted,
    required this.totalReviews,
    required this.correctReviews,
    required this.avgStability,
    required this.lastReviewedAt,
  });

  double get correctRate =>
      totalReviews == 0 ? 0 : correctReviews / totalReviews;
}
