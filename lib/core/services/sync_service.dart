import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/card_state.dart';
import 'local_storage_service.dart';

/// Slice 16: card_states 雙向 sync
///
/// 設計重點:
/// 1. Mutex 包整個 sync(),避免登入觸發 + pull-to-refresh 觸發互踩
/// 2. 順序: push dirty → 再 pull,避免本機剛 review 完未推就被 server 老資料蓋
/// 3. push 用 dirty flag (lastSyncedAt vs lastReviewedAt) 只推改過的
/// 4. pull 用 server 端 updated_at cursor (incremental),
///    cursor 存在 SharedPreferences 以 user_id 區分(換帳號不會撈錯)
/// 5. 衝突解決: server clock last-write-wins
///    (pull 時不再比 lastReviewedAt,因為 push 已先做完)
class SyncService {
  static final _lock = Mutex();
  final _db = Supabase.instance.client;

  static String _cursorKey(String userId) => 'card_states_pull_cursor_$userId';

  /// 對外統一入口。LoginScreen / HomeScreen pull-to-refresh 都呼叫這個。
  Future<void> sync(String userId) async {
    await _lock.protect(() async {
      try {
        await _pushDirty(userId);
        await _pullSince(userId);
      } catch (e) {
        // ignore: avoid_print
        print('[SyncService] sync failed: $e');
      }
    });
  }

  /// 舊 API 保留(LoginScreen 還在呼叫),導向新 sync()
  /// Slice 18 清掉
  Future<void> syncOnLogin(String userId) => sync(userId);

  /// 複習完一張卡後即時推送到 Supabase
  /// 由 ReviewSession.rate() 在 saveCardState 之後呼叫, caller 不 await
  /// 失敗靜默, 不影響本機寫入流程
  /// 成功後寫 lastSyncedAt = lastReviewedAt(避免下次 sync 重推)
  Future<void> pushSingleCardState(CardState state, String userId) async {
    await _lock.protect(() async {
      try {
        await _db.from('card_states').upsert(
              _rowFor(state, userId),
              onConflict: 'user_id,word_id',
            );
        final storage = LocalStorageService();
        await storage.saveCardState(state, markSynced: true);
      } catch (e) {
        // ignore: avoid_print
        print('[SyncService] pushSingleCardState failed: $e');
      }
    });
  }

  /// 共用 payload。注意 updated_at 不再傳, server trigger 自動戳
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
      };

  Future<void> _pushDirty(String userId) async {
    final storage = LocalStorageService();
    final dirty = await storage.getDirtyStates();
    if (dirty.isEmpty) return;

    final rows = dirty.map((s) => _rowFor(s, userId)).toList();
    await _db.from('card_states').upsert(
          rows,
          onConflict: 'user_id,word_id',
        );

    for (final s in dirty) {
      if (s.userId != userId) s.userId = userId;
      await storage.saveCardState(s, markSynced: true);
    }
  }

  Future<void> _pullSince(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cursorStr = prefs.getString(_cursorKey(userId));
    final cursor = cursorStr != null
        ? DateTime.parse(cursorStr).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(0).toUtc();

    final response = await _db
        .from('card_states')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', cursor.toIso8601String())
        .order('updated_at', ascending: true);

    if (response.isEmpty) return;

    final storage = LocalStorageService();
    DateTime maxUpdated = cursor;

    for (final row in response) {
      final wordId = row['word_id'] as String;
      final serverUpdated = DateTime.parse(row['updated_at']).toUtc();
      if (serverUpdated.isAfter(maxUpdated)) maxUpdated = serverUpdated;

      final existing = await storage.getStateByWordId(wordId);
      final s = existing ?? (CardState()..wordId = wordId);

      s.userId = userId;
      s.easeFactor = (row['ease_factor'] as num).toDouble();
      s.intervalDays = row['interval_days'] as int;
      s.repetitions = row['repetitions'] as int;
      s.stability = (row['stability'] as num?)?.toDouble() ?? 0.0;
      s.difficulty = (row['difficulty'] as num?)?.toDouble() ?? 0.0;
      s.dueAt = DateTime.parse(row['due_at']).toUtc();
      s.lastReviewedAt = DateTime.parse(row['last_reviewed_at']).toUtc();
      s.totalReviews = row['total_reviews'] as int;
      s.correctReviews = row['correct_reviews'] as int;
      await storage.saveCardState(s, markSynced: true);
    }

    await prefs.setString(_cursorKey(userId), maxUpdated.toIso8601String());
  }
}
