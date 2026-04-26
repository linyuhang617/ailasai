enum ReviewRating { again, hard, good, easy }

class Sm2Result {
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  const Sm2Result({
    required this.intervalDays,
    required this.easeFactor,
    required this.repetitions,
  });
}

class Sm2Service {
  static const double _minEase = 1.3;

  Sm2Result calculateNext({
    required ReviewRating rating,
    required int intervalDays,
    required double easeFactor,
    required int repetitions,
  }) {
    double newEase = easeFactor;
    int newInterval;
    int newReps;

    switch (rating) {
      case ReviewRating.again:
        newInterval = 1;
        newEase = (easeFactor - 0.20).clamp(_minEase, double.infinity);
        newReps = 0;
      case ReviewRating.hard:
        newInterval = (intervalDays * 1.2).round().clamp(1, 36500);
        newEase = (easeFactor - 0.15).clamp(_minEase, double.infinity);
        newReps = repetitions + 1;
      case ReviewRating.good:
        newInterval = repetitions == 0
            ? 1
            : (intervalDays * easeFactor).round().clamp(1, 36500);
        newReps = repetitions + 1;
      case ReviewRating.easy:
        newInterval = repetitions == 0
            ? 4
            : (intervalDays * easeFactor * 1.3).round().clamp(1, 36500);
        newEase = easeFactor + 0.15;
        newReps = repetitions + 1;
    }

    return Sm2Result(
      intervalDays: newInterval,
      easeFactor: newEase,
      repetitions: newReps,
    );
  }

  Map<ReviewRating, int> previewIntervals({
    required int intervalDays,
    required double easeFactor,
    required int repetitions,
  }) {
    return {
      for (final r in ReviewRating.values)
        r: calculateNext(
          rating: r,
          intervalDays: intervalDays,
          easeFactor: easeFactor,
          repetitions: repetitions,
        ).intervalDays,
    };
  }
}
