import 'dart:math' as math;
import '../models/card_state.dart';
import '../models/word.dart';
import '../models/word_list.dart';
import 'local_storage_service.dart';
import 'word_list_service.dart';

class HomeStats {
  final int dueCount;
  final int todayCompleted;
  final int newToday;
  final int streak;
  final List<WordList> joinedLists;
  final List<Word> dueWords;
  final List<Word> allWords;

  const HomeStats({
    required this.dueCount,
    required this.todayCompleted,
    required this.newToday,
    required this.streak,
    required this.joinedLists,
    required this.dueWords,
    required this.allWords,
  });

  bool get hasJoinedLists => joinedLists.isNotEmpty;
  bool get allDone => dueCount == 0 && hasJoinedLists;
}

class DailyCorrectness {
  final DateTime date; // local date at 00:00
  final int reviewed;
  final double correctRate; // 0.0 - 1.0
  const DailyCorrectness({
    required this.date,
    required this.reviewed,
    required this.correctRate,
  });
}

class MemoryStats {
  final int totalWords;
  final int reviewedCount;
  final double avgRetrievability; // 0.0 - 1.0; NaN when no data
  final Map<String, int> stabilityBuckets; // "1-3","4-7","8-14","15-30","30+"
  final List<DailyCorrectness> dailyCorrectness; // last 30 days, empty days omitted
  const MemoryStats({
    required this.totalWords,
    required this.reviewedCount,
    required this.avgRetrievability,
    required this.stabilityBuckets,
    required this.dailyCorrectness,
  });

  bool get hasData => reviewedCount > 0;
  bool get hasStabilityData =>
      stabilityBuckets.values.any((v) => v > 0);
}

class StatsService {
  final _wordListService = WordListService();
  final _storage = LocalStorageService();

  Future<HomeStats> loadHomeStats(String userId) async {
    final results = await Future.wait([
      _wordListService.fetchAllLists(userId),
      _storage.getAllStates(),
      _wordListService.fetchWordsForJoinedLists(userId),
    ]);

    final allLists = results[0] as List<WordList>;
    final allStates = results[1] as List<CardState>;
    final allWords = results[2] as List<Word>;

    final joinedLists = allLists.where((l) => l.isJoined).toList();

    final nowUtc = DateTime.now().toUtc();
    final todayLocal = DateTime.now();
    final todayStart = DateTime(
        todayLocal.year, todayLocal.month, todayLocal.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Due: CardState.dueAt <= now
    final existingIds = allStates.map((s) => s.wordId).toSet();
    final dueStateIds = allStates
        .where((s) => !s.dueAt.isAfter(nowUtc))
        .map((s) => s.wordId)
        .toSet();

    // New words（還沒有 CardState），上限 10 張
    final newWordIds = allWords
        .map((w) => w.id)
        .where((id) => !existingIds.contains(id))
        .take(10)
        .toSet();

    final dueWords = allWords
        .where((w) => dueStateIds.contains(w.id) || newWordIds.contains(w.id))
        .toList();

    // 今日複習過的卡
    final todayReviewed = allStates.where((s) {
      final local = s.lastReviewedAt.toLocal();
      return !local.isBefore(todayStart) && local.isBefore(todayEnd);
    }).toList();

    final todayCompleted = todayReviewed.length;
    final newToday =
        todayReviewed.where((s) => s.totalReviews == 1).length;

    return HomeStats(
      dueCount: dueWords.length,
      todayCompleted: todayCompleted,
      newToday: newToday,
      streak: _calculateStreak(allStates),
      joinedLists: joinedLists,
      dueWords: dueWords,
      allWords: allWords,
    );
  }

  int _calculateStreak(List<CardState> states) {
    if (states.isEmpty) return 0;

    final dates = states
        .map((s) {
          final l = s.lastReviewedAt.toLocal();
          return DateTime(l.year, l.month, l.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // 今天還沒複習不歸零，從昨天起算
    var cursor = dates.first == todayDate
        ? todayDate
        : dates.first == yesterday
            ? yesterday
            : null;

    if (cursor == null) return 0;

    var streak = 0;
    for (final date in dates) {
      if (date == cursor) {
        streak++;
        cursor = cursor!.subtract(const Duration(days: 1));
      } else if (date.isBefore(cursor!)) {
        break;
      }
    }
    return streak;
  }

  Future<MemoryStats> getMemoryStats({
    required String userId,
    required String wordListId,
  }) async {
    // 拿這個字庫的所有單字 id
    final allWords = await _wordListService.fetchWordsForJoinedLists(userId);
    final listWords =
        allWords.where((w) => w.wordListId == wordListId).toList();
    final listWordIds = listWords.map((w) => w.id).toSet();

    // 拿本機所有 CardState，過濾到這個字庫
    final allStates = await _storage.getAllStates();
    final states =
        allStates.where((s) => listWordIds.contains(s.wordId)).toList();

    // 穩定性分布（只看 stability > 0 的卡）
    final buckets = <String, int>{
      '1-3': 0,
      '4-7': 0,
      '8-14': 0,
      '15-30': 0,
      '30+': 0,
    };
    for (final s in states) {
      if (s.stability <= 0) continue;
      final d = s.stability;
      if (d <= 3) {
        buckets['1-3'] = buckets['1-3']! + 1;
      } else if (d <= 7) {
        buckets['4-7'] = buckets['4-7']! + 1;
      } else if (d <= 14) {
        buckets['8-14'] = buckets['8-14']! + 1;
      } else if (d <= 30) {
        buckets['15-30'] = buckets['15-30']! + 1;
      } else {
        buckets['30+'] = buckets['30+']! + 1;
      }
    }

    // 平均 retrievability（即時算，R = e^(-t/S)）
    // 只納入 stability > 0 的卡
    final nowUtc = DateTime.now().toUtc();
    final rValues = <double>[];
    for (final s in states) {
      if (s.stability <= 0) continue;
      final elapsedDays =
          nowUtc.difference(s.lastReviewedAt.toUtc()).inHours / 24.0;
      final r = _retrievability(elapsedDays, s.stability);
      rValues.add(r);
    }
    final avgR = rValues.isEmpty
        ? double.nan
        : rValues.reduce((a, b) => a + b) / rValues.length;

    // 近 30 天每日正確率（方案 A 近似：用 lastReviewedAt 落在該日 + 累計比例）
    final todayLocal = DateTime.now();
    final todayDate =
        DateTime(todayLocal.year, todayLocal.month, todayLocal.day);
    final startDate = todayDate.subtract(const Duration(days: 29));

    final Map<DateTime, List<CardState>> byDay = {};
    for (final s in states) {
      if (s.totalReviews == 0) continue;
      final local = s.lastReviewedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(startDate)) continue;
      if (day.isAfter(todayDate)) continue;
      byDay.putIfAbsent(day, () => []).add(s);
    }

    final daily = byDay.entries.map((entry) {
      final dayStates = entry.value;
      final totalReviews =
          dayStates.fold<int>(0, (acc, s) => acc + s.totalReviews);
      final correctReviews =
          dayStates.fold<int>(0, (acc, s) => acc + s.correctReviews);
      final rate =
          totalReviews == 0 ? 0.0 : correctReviews / totalReviews;
      return DailyCorrectness(
        date: entry.key,
        reviewed: dayStates.length,
        correctRate: rate,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return MemoryStats(
      totalWords: listWords.length,
      reviewedCount: states.where((s) => s.totalReviews > 0).length,
      avgRetrievability: avgR,
      stabilityBuckets: buckets,
      dailyCorrectness: daily,
    );
  }

  // R = e^(-t/S)
  double _retrievability(double elapsedDays, double stability) {
    if (stability <= 0) return 0.0;
    final r = math.exp(-elapsedDays / stability);
    if (r.isNaN) return 0.0;
    return r.clamp(0.0, 1.0);
  }

}
