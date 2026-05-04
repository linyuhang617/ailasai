import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';

/// Slice 15 — 隊伍打卡服務層
///
/// 設計準則對齊 Slice 12/14：
/// - cross-table 查詢一律走 SECURITY DEFINER RPC
/// - create / join / leave 拋 [TeamException] 給 UI 顯示中文訊息
/// - checkIn / settleXp 靜默失敗，絕不擋複習或 UI
class TeamService {
  final SupabaseClient _db = Supabase.instance.client;

  /// 取得我加入的所有隊伍（含 myXp、memberCount、todayCheckedIn）
  Future<List<Team>> fetchMyTeams() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _db.rpc('get_my_teams');
    return (rows as List)
        .map((e) => Team.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 取得隊伍詳情:成員列表 + 過去 7 天打卡矩陣
  /// RPC 內部會驗證呼叫者是 member,否則拋例外
  Future<TeamDetail> fetchTeamDetail(String teamId) async {
    final rows = await _db.rpc(
      'get_team_detail',
      params: {'p_team_id': teamId},
    );
    final members = (rows as List)
        .map((e) => TeamMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return TeamDetail(teamId: teamId, members: members);
  }

  /// 建立新隊伍,回傳 team_id
  /// 邀請碼碰撞由 RPC 內部 retry,client 不需處理
  Future<String> createTeam(String name) async {
    try {
      final result = await _db.rpc('create_team', params: {'p_name': name});
      return result as String;
    } on PostgrestException catch (e) {
      throw TeamException(e.message);
    }
  }

  /// 用邀請碼加入,回傳 team_id
  /// 失敗時拋 [TeamException] 含中文訊息(不存在 / 已加入 / 已滿)
  Future<String> joinByInviteCode(String code) async {
    try {
      final result = await _db.rpc(
        'join_team_by_invite_code',
        params: {'p_invite_code': code},
      );
      return result as String;
    } on PostgrestException catch (e) {
      throw TeamException(e.message);
    }
  }

  /// 退出隊伍(creator 退出 = 解散整個隊伍)
  Future<void> leaveTeam(String teamId) async {
    try {
      await _db.rpc('leave_team', params: {'p_team_id': teamId});
    } on PostgrestException catch (e) {
      throw TeamException(e.message);
    }
  }

  /// 對所有自己的隊伍打卡(複習達 10 張時觸發)
  /// 失敗靜默,不拖慢複習流程
  Future<void> checkIn() async {
    try {
      await _db.rpc('team_check_in');
    } catch (_) {
      // 靜默:網路 / RLS / timing 任何錯都不擋複習
    }
  }

  /// 結算未打卡天的 −5 XP(下限 0)
  /// 進入 /team 或登入時呼叫,失敗靜默
  Future<void> settleXp() async {
    try {
      await _db.rpc('settle_xp');
    } catch (_) {
      // 靜默
    }
  }
}

/// Team 相關操作的錯誤訊息(可直接 .message 顯示給使用者)
class TeamException implements Exception {
  final String message;
  TeamException(this.message);

  @override
  String toString() => message;
}
