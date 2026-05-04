import 'package:isar/isar.dart';
part 'card_state.g.dart';

@collection
class CardState {
  Id isarId = Isar.autoIncrement;

  String? userId;

  @Index(unique: true)
  late String wordId;

  late double easeFactor;
  late int intervalDays;
  late int repetitions;
  late DateTime dueAt;
  late DateTime lastReviewedAt;
  late int totalReviews;
  late int correctReviews;
  double stability = 0.0;
  double difficulty = 0.0;

  /// Slice 16: 雙向 sync 用
  /// null 或 lastReviewedAt > lastSyncedAt 即為 dirty,須 push 到 server
  /// push 成功後寫 lastSyncedAt = state.lastReviewedAt
  /// 既有 row 升級 schema 後 lastSyncedAt = null,首次 sync 會被全部 push(等同舊行為)
  DateTime? lastSyncedAt;
}
