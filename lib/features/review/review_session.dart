import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/card_state.dart';
import '../../core/models/word.dart';
import '../../core/services/algorithm_service.dart';
import '../../core/services/fsrs_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/sm2_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/assignment_service.dart';
import '../../core/services/team_service.dart';

class _CardItem {
  final CardState state;
  _CardItem({required this.state});
}

class ReviewSession {
  final List<Word> words;
  final LocalStorageService _storage;
  final Sm2Service _sm2 = Sm2Service();
  final FsrsService _fsrs = FsrsService();
  final SyncService _sync = SyncService();
  final AssignmentService _assignSvc = AssignmentService();
  final TeamService _teamSvc = TeamService();
  final SrsAlgorithm algorithm;

  final List<_CardItem> _dueQueue = [];
  final List<_CardItem> _againQueue = [];
  bool _initialized = false;

  int totalReviewed = 0;
  int correctReviewed = 0;

  ReviewSession({
    required this.words,
    this.algorithm = SrsAlgorithm.sm2,
    LocalStorageService? storage,
  }) : _storage = storage ?? LocalStorageService();

  bool get isComplete =>
      _initialized && _dueQueue.isEmpty && _againQueue.isEmpty;

  _CardItem? get _current {
    if (_dueQueue.isNotEmpty) return _dueQueue.first;
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

  int get remainingCount => _dueQueue.length + _againQueue.length;

  Map<ReviewRating, int> get previewIntervals {
    final s = currentState;
    if (s == null) return {};
    if (algorithm == SrsAlgorithm.fsrs) {
      return _fsrs.previewIntervals(state: s);
    }
    return _sm2.previewIntervals(
      intervalDays: s.intervalDays,
      easeFactor: s.easeFactor,
      repetitions: s.repetitions,
    );
  }

  Future<void> init() async {
    final wordIds = words.map((w) => w.id).toList();
    final dueStates = await _storage.getDueStates(wordIds);
    final existingIds = await _storage.getExistingWordIds(wordIds);
    const maxNewCards = 10;
    final allNewWordIds =
        wordIds.where((id) => !existingIds.contains(id)).toList();
    final newWordIds = allNewWordIds.take(maxNewCards).toList();
    final newStates = newWordIds.map(_storage.createNew).toList();
    _dueQueue.addAll(
        [...dueStates, ...newStates].map((s) => _CardItem(state: s)));
    _initialized = true;
  }

  Future<void> rate(ReviewRating rating) async {
    final item = _current;
    if (item == null) return;

    if (_dueQueue.isNotEmpty && _dueQueue.first == item) {
      _dueQueue.removeAt(0);
    } else if (_againQueue.isNotEmpty && _againQueue.first == item) {
      _againQueue.removeAt(0);
    }

    totalReviewed++;
    final isCorrect = rating != ReviewRating.again;
    if (isCorrect) correctReviewed++;

    final now = DateTime.now().toUtc();

    if (algorithm == SrsAlgorithm.fsrs) {
      final result = _fsrs.calculateNext(rating: rating, state: item.state);
      item.state
        ..intervalDays = result.intervalDays
        ..stability = result.stability
        ..difficulty = result.difficulty
        ..lastReviewedAt = now
        ..dueAt = now.add(Duration(days: result.intervalDays))
        ..totalReviews = item.state.totalReviews + 1
        ..correctReviews = item.state.correctReviews + (isCorrect ? 1 : 0);
    } else {
      final result = _sm2.calculateNext(
        rating: rating,
        intervalDays: item.state.intervalDays,
        easeFactor: item.state.easeFactor,
        repetitions: item.state.repetitions,
      );
      item.state
        ..intervalDays = result.intervalDays
        ..easeFactor = result.easeFactor
        ..repetitions = result.repetitions
        ..lastReviewedAt = now
        ..dueAt = now.add(Duration(days: result.intervalDays))
        ..totalReviews = item.state.totalReviews + 1
        ..correctReviews = item.state.correctReviews + (isCorrect ? 1 : 0);
    }

    await _storage.saveCardState(item.state);

    // TECH-DEBT-1: 本機寫完後即時推到 Supabase
    // 不 await, 網路慢不拖 UI; 失敗靜默(pushSingleCardState 內含 try/catch)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      unawaited(_sync.pushSingleCardState(item.state, userId));
    }

    // Slice 14: 記錄作業進度（Server 端決定此單字屬於哪些作業）
    // 不 await，靜默失敗，不拖慢複習流程
    unawaited(_assignSvc.recordProgress(item.state.wordId));

    // Slice 15: 完成第 10 張卡時觸發隊伍打卡
    // 同 session 後續評分不重複呼叫 (DB UNIQUE 也會擋,但少打網路)
    if (totalReviewed == 10) {
      unawaited(_teamSvc.checkIn());
    }

    if (rating == ReviewRating.again) {
      _againQueue.add(item);
    }
  }
}
