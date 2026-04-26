class WordList {
  final String id;
  final String name;
  final String language;
  final String? examType;
  final int totalWords;
  final bool isJoined;
  final int reviewedCount;

  const WordList({
    required this.id,
    required this.name,
    required this.language,
    this.examType,
    required this.totalWords,
    required this.isJoined,
    required this.reviewedCount,
  });

  factory WordList.fromJson(
    Map<String, dynamic> json, {
    required bool isJoined,
    required int reviewedCount,
  }) =>
      WordList(
        id: json['id'] as String,
        name: json['name'] as String,
        language: json['language'] as String? ?? '',
        examType: json['exam_type'] as String?,
        totalWords: json['total_words'] as int? ?? 0,
        isJoined: isJoined,
        reviewedCount: reviewedCount,
      );

  double get progressPercent =>
      totalWords == 0 ? 0.0 : reviewedCount / totalWords;
}
