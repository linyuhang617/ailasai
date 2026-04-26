import '../../core/models/card_state.dart';
import '../../core/models/word.dart';
import '../../core/services/sm2_service.dart';

class _CardItem {
  final CardState state;
  _CardItem({required this.state});
}

class PracticeSession {
  final List<Word> words;
  final Sm2Service _sm2 = Sm2Service();

  final List<_CardItem> _queue = [];
  final List<_CardItem> _againQueue = [];
  bool _initialized = false;

  int totalReviewed = 0;
  int correctReviewed = 0;

  PracticeSession({required this.words});

  bool get isComplete =>
      _initialized && _queue.isEmpty && _againQueue.isEmpty;

  _CardItem? get _current {
    if (_queue.isNotEmpty) return _queue.first;
    if (_againQueue.isNotEmpty) return _againQueue.first;
    return null;
  }

  Word? get currentWord {
    final item = _current;
    if (item == null) return null;
    try {
      return words.firstWhere((w) => w.id == item.state.wordId);
    } catch (_) {
      return null;
    }
  }

  CardState? get currentState => _current?.state;

  int get remainingCount => _queue.length + _againQueue.length;

  Map<ReviewRating, int> get previewIntervals {
    final s = currentState;
    if (s == null) return {};
    return _sm2.previewIntervals(
      intervalDays: s.intervalDays,
      easeFactor: s.easeFactor,
      repetitions: s.repetitions,
    );
  }

  void init() {
    final shuffled = List<Word>.from(words)..shuffle();
    for (final word in shuffled) {
      // 用預設值建立 in-memory CardState，不讀 Isar
      final state = CardState()
        ..wordId = word.id
        ..intervalDays = 1
        ..easeFactor = 2.5
        ..repetitions = 0
        ..dueAt = DateTime.now().toUtc()
        ..lastReviewedAt = DateTime.now().toUtc()
        ..totalReviews = 0
        ..correctReviews = 0;
      _queue.add(_CardItem(state: state));
    }
    _initialized = true;
  }

  // rate() 只更新 in-memory，不寫 Isar，不影響 SRS 排程
  void rate(ReviewRating rating) {
    final item = _current;
    if (item == null) return;

    if (_queue.isNotEmpty && _queue.first == item) {
      _queue.removeAt(0);
    } else if (_againQueue.isNotEmpty && _againQueue.first == item) {
      _againQueue.removeAt(0);
    }

    totalReviewed++;
    final isCorrect = rating != ReviewRating.again;
    if (isCorrect) correctReviewed++;

    final result = _sm2.calculateNext(
      rating: rating,
      intervalDays: item.state.intervalDays,
      easeFactor: item.state.easeFactor,
      repetitions: item.state.repetitions,
    );

    // 只更新 in-memory，不 save
    item.state
      ..intervalDays = result.intervalDays
      ..easeFactor = result.easeFactor
      ..repetitions = result.repetitions;

    if (rating == ReviewRating.again) {
      _againQueue.add(item);
    }
  }
}
