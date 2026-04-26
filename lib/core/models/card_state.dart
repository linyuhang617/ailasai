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
}
