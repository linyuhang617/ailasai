import 'package:fsrs/fsrs.dart' as fsrs;
import '../models/card_state.dart';
import 'sm2_service.dart'; // 共用 ReviewRating enum

class FsrsService {
  final _scheduler = fsrs.Scheduler(enableFuzzing: false);

  // CardState → fsrs.Card 轉換
  fsrs.Card _toFsrsCard(CardState state) {
    final isNew = state.stability == 0.0;
    return fsrs.Card(
      cardId: state.isarId,
      state: isNew ? fsrs.State.learning : fsrs.State.review,
      stability: isNew ? null : state.stability,
      difficulty: isNew ? null : state.difficulty,
      lastReview: isNew ? null : state.lastReviewedAt.toUtc(),
    );
  }

  // ReviewRating → fsrs.Rating
  fsrs.Rating _toFsrsRating(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        return fsrs.Rating.again;
      case ReviewRating.hard:
        return fsrs.Rating.hard;
      case ReviewRating.good:
        return fsrs.Rating.good;
      case ReviewRating.easy:
        return fsrs.Rating.easy;
    }
  }

  // 計算下次複習結果，回傳 intervalDays / stability / difficulty
  ({int intervalDays, double stability, double difficulty}) calculateNext({
    required ReviewRating rating,
    required CardState state,
  }) {
    final fsrsCard = _toFsrsCard(state);
    final now = DateTime.now().toUtc();
    final (:card, reviewLog: _) = _scheduler.reviewCard(
      fsrsCard,
      _toFsrsRating(rating),
      reviewDateTime: now,
    );
    final days = card.due.difference(now).inDays.clamp(1, 36500);
    return (
      intervalDays: days,
      stability: card.stability ?? 1.0,
      difficulty: card.difficulty ?? 5.0,
    );
  }

  // 預覽四個評分各自的天數
  Map<ReviewRating, int> previewIntervals({required CardState state}) {
    final fsrsCard = _toFsrsCard(state);
    final now = DateTime.now().toUtc();
    return {
      for (final r in ReviewRating.values)
        r: () {
          final (:card, reviewLog: _) = _scheduler.reviewCard(
            fsrsCard.copyWith(),
            _toFsrsRating(r),
            reviewDateTime: now,
          );
          return card.due.difference(now).inDays.clamp(1, 36500);
        }(),
    };
  }
}
