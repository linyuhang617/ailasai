/// Slice 12 — 教師班級系統
///
/// [Classroom]: 班級實體,由教師建立
/// [ClassroomMember]: 學生加入班級的關聯紀錄
class Classroom {
  final String id;
  final String name;
  final String teacherId;
  final String inviteCode;
  final DateTime createdAt;
  final int memberCount;

  const Classroom({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.inviteCode,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] as String,
      name: json['name'] as String,
      teacherId: json['teacher_id'] as String,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  Classroom copyWith({
    String? name,
    String? inviteCode,
    int? memberCount,
  }) {
    return Classroom(
      id: id,
      name: name ?? this.name,
      teacherId: teacherId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  String toString() =>
      'Classroom(id=$id, name=$name, code=$inviteCode, members=$memberCount)';
}

class ClassroomMember {
  final String id;
  final String classroomId;
  final String studentId;

  /// 只有透過 RPC get_classroom_members 取得時會有值;
  /// 一般 SELECT classroom_members 不會帶 email。
  final String? studentEmail;
  final DateTime joinedAt;

  const ClassroomMember({
    required this.id,
    required this.classroomId,
    required this.studentId,
    this.studentEmail,
    required this.joinedAt,
  });

  factory ClassroomMember.fromJson(Map<String, dynamic> json) {
    return ClassroomMember(
      id: json['member_id'] as String,
      classroomId: json['classroom_id'] as String,
      studentId: json['student_id'] as String,
      studentEmail: json['student_email'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  @override
  String toString() =>
      'ClassroomMember(email=$studentEmail, joinedAt=$joinedAt)';
}
