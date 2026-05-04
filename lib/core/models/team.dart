// Slice 15 — 隊伍打卡 data classes

class Team {
  final String id;
  final String name;
  final String inviteCode;
  final String creatorId;
  final bool isCreator;
  final int memberCount;
  final int myXp;
  final bool todayCheckedIn;

  const Team({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.creatorId,
    required this.isCreator,
    required this.memberCount,
    required this.myXp,
    required this.todayCheckedIn,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['invite_code'] as String,
        creatorId: json['creator_id'] as String,
        isCreator: json['is_creator'] as bool,
        memberCount: (json['member_count'] as num).toInt(),
        myXp: (json['my_xp'] as num).toInt(),
        todayCheckedIn: json['today_checked_in'] as bool,
      );

  bool get isFull => memberCount >= 10;
}

class TeamMember {
  final String userId;
  final String email;
  final int xp;
  final bool isMe;
  final bool isCreator;
  final bool todayCheckedIn;

  /// 過去 7 天有打卡的日期（YYYY-MM-DD 字串，UTC）
  final Set<String> weeklyCheckIns;

  const TeamMember({
    required this.userId,
    required this.email,
    required this.xp,
    required this.isMe,
    required this.isCreator,
    required this.todayCheckedIn,
    required this.weeklyCheckIns,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final raw = (json['weekly_check_ins'] as List?) ?? const [];
    return TeamMember(
      userId: json['user_id'] as String,
      email: (json['email'] as String?) ?? '',
      xp: (json['xp'] as num).toInt(),
      isMe: json['is_me'] as bool,
      isCreator: json['is_creator'] as bool,
      todayCheckedIn: json['today_checked_in'] as bool,
      // PostgreSQL DATE[] → Dart List<String> ("YYYY-MM-DD")
      weeklyCheckIns: raw.map((e) => e.toString()).toSet(),
    );
  }

  /// 檢查特定 UTC 日期是否已打卡
  bool checkedInOn(DateTime utcDate) {
    final key = utcDate.toIso8601String().substring(0, 10);
    return weeklyCheckIns.contains(key);
  }
}

class TeamDetail {
  final String teamId;
  final List<TeamMember> members;

  const TeamDetail({
    required this.teamId,
    required this.members,
  });

  /// 找自己的 member 紀錄
  TeamMember? get me {
    for (final m in members) {
      if (m.isMe) return m;
    }
    return null;
  }

  /// 過去 7 天的 UTC 日期（從早到晚，含今天）
  /// 給熱圖顯示用
  static List<DateTime> last7DaysUtc() {
    final now = DateTime.now().toUtc();
    final todayDate = DateTime.utc(now.year, now.month, now.day);
    return List.generate(7, (i) => todayDate.subtract(Duration(days: 6 - i)));
  }
}
