/// Slice 12 — 教師/學生角色
///
/// 存在 Supabase Auth raw_user_meta_data.role 欄位。
/// 舊帳號 metadata 沒 role 一律當 student。
///
/// 注意:raw_user_meta_data 可被 client 寫,role 僅影響 UI;
/// 真正權限控制在 DB RLS 用 teacher_id = auth.uid() 擋。
enum UserRole {
  student,
  teacher;
}

extension UserRoleX on UserRole {
  static UserRole fromMeta(Map<String, dynamic>? meta) {
    final raw = meta?['role'] as String?;
    if (raw == 'teacher') return UserRole.teacher;
    return UserRole.student;
  }

  bool get isTeacher => this == UserRole.teacher;
  bool get isStudent => this == UserRole.student;
}
