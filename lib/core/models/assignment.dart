// Slice 14 — 作業相關 data class

/// 學生角度：一筆作業 + 我的完成進度
class Assignment {
  final String id;
  final String classroomName;
  final String wordListId;
  final String wordListName;
  final DateTime dueAt;
  final int totalWords;
  final int completedWords;

  const Assignment({
    required this.id,
    required this.classroomName,
    required this.wordListId,
    required this.wordListName,
    required this.dueAt,
    required this.totalWords,
    required this.completedWords,
  });

  bool get isOverdue => DateTime.now().toUtc().isAfter(dueAt);
  double get progress =>
      totalWords == 0 ? 0 : completedWords / totalWords;

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['assignment_id'] as String,
        classroomName: json['classroom_name'] as String,
        wordListId: json['word_list_id'] as String,
        wordListName: json['word_list_name'] as String,
        dueAt: DateTime.parse(json['due_at'] as String),
        totalWords: (json['total_words'] as num?)?.toInt() ?? 0,
        completedWords: (json['completed_words'] as num?)?.toInt() ?? 0,
      );
}

/// 教師角度：班級內一筆作業（不含學生進度）
class ClassroomAssignment {
  final String id;
  final String wordListId;
  final String wordListName;
  final DateTime dueAt;
  final int totalWords;
  final DateTime createdAt;

  const ClassroomAssignment({
    required this.id,
    required this.wordListId,
    required this.wordListName,
    required this.dueAt,
    required this.totalWords,
    required this.createdAt,
  });

  bool get isOverdue => DateTime.now().toUtc().isAfter(dueAt);

  factory ClassroomAssignment.fromJson(Map<String, dynamic> json) =>
      ClassroomAssignment(
        id: json['assignment_id'] as String,
        wordListId: json['word_list_id'] as String,
        wordListName: json['word_list_name'] as String,
        dueAt: DateTime.parse(json['due_at'] as String),
        totalWords: (json['total_words'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
