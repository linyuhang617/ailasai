import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_state.dart';
import 'local_storage_service.dart';

class SyncService {
  final _db = Supabase.instance.client;

  Future<void> syncOnLogin(String userId) async {
    try {
      await _pushLocalStates(userId);
      await _pullServerStates(userId);
    } catch (e) {
      // 同步失敗不阻擋登入流程, 靜默記錄
      // ignore: avoid_print
      print('[SyncService] sync failed: $e');
    }
  }

  /// 複習完一張卡後即時推送到 Supabase
  /// 由 ReviewSession.rate() 在 saveCardState 之後呼叫, caller 不 await
  /// 失敗靜默(try/catch 包住), 不影響本機寫入流程
  Future<void> pushSingleCardState(CardState state, String userId) async {
    try {
      await _db.from('card_states').upsert(
            _rowFor(state, userId),
            onConflict: 'user_id,word_id',
          );
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService] pushSingleCardState failed: $e');
    }
  }

  /// 共用 payload。single push / bulk push 都走這裡, 避免漏欄位
  Map<String, dynamic> _rowFor(CardState s, String userId) => {
        'user_id': userId,
        'word_id': s.wordId,
        'ease_factor': s.easeFactor,
        'interval_days': s.intervalDays,
        'repetitions': s.repetitions,
        'stability': s.stability,
        'difficulty': s.difficulty,
        'due_at': s.dueAt.toUtc().toIso8601String(),
        'last_reviewed_at': s.lastReviewedAt.toUtc().toIso8601String(),
        'total_reviews': s.totalReviews,
        'correct_reviews': s.correctReviews,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Future<void> _pushLocalStates(String userId) async {
    final storage = LocalStorageService();
    final localStates = await storage.getAllStates();
    if (localStates.isEmpty) return;

    final rows = localStates.map((s) => _rowFor(s, userId)).toList();

    await _db.from('card_states').upsert(
          rows,
          onConflict: 'user_id,word_id',
        );

    for (final s in localStates) {
      if (s.userId != userId) {
        s.userId = userId;
        await storage.saveCardState(s);
      }
    }
  }

  Future<void> _pullServerStates(String userId) async {
    final storage = LocalStorageService();
    final response =
        await _db.from('card_states').select().eq('user_id', userId);

    for (final row in response) {
      final wordId = row['word_id'] as String;
      final serverReviewed = DateTime.parse(row['last_reviewed_at']).toUtc();

      final existing = await storage.getStateByWordId(wordId);

      if (existing == null ||
          existing.lastReviewedAt.isBefore(serverReviewed)) {
        final s = existing ?? (CardState()..wordId = wordId);
        s.userId = userId;
        s.easeFactor = (row['ease_factor'] as num).toDouble();
        s.intervalDays = row['interval_days'] as int;
        s.repetitions = row['repetitions'] as int;
        s.stability = (row['stability'] as num?)?.toDouble() ?? 0.0;
        s.difficulty = (row['difficulty'] as num?)?.toDouble() ?? 0.0;
        s.dueAt = DateTime.parse(row['due_at']).toUtc();
        s.lastReviewedAt = serverReviewed;
        s.totalReviews = row['total_reviews'] as int;
        s.correctReviews = row['correct_reviews'] as int;
        await storage.saveCardState(s);
      }
    }
  }
}
