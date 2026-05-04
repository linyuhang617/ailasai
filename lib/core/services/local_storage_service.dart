import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card_state.dart';

class LocalStorageService {
  static Isar? _isar;

  static Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [CardStateSchema],
      directory: dir.path,
    );
  }

  static Isar get _db {
    assert(_isar != null && _isar!.isOpen,
        'LocalStorageService.init() must be called before runApp()');
    return _isar!;
  }

  Future<List<CardState>> getDueStates(List<String> wordIds) async {
    final now = DateTime.now().toUtc();
    final wordIdSet = wordIds.toSet();
    final all = await _db.cardStates
        .filter()
        .dueAtLessThan(now, include: true)
        .findAll();
    return all.where((s) => wordIdSet.contains(s.wordId)).toList();
  }

  Future<Set<String>> getExistingWordIds(List<String> wordIds) async {
    final all = await _db.cardStates
        .filter()
        .anyOf(wordIds, (q, id) => q.wordIdEqualTo(id))
        .findAll();
    return all.map((s) => s.wordId).toSet();
  }

  Future<List<CardState>> getAllStates() async {
    return _db.cardStates.where().findAll();
  }

  Future<CardState?> getStateByWordId(String wordId) async {
    return _db.cardStates
        .filter()
        .wordIdEqualTo(wordId)
        .findFirst();
  }

  /// Slice 16: 取得需要 push 到 server 的「髒」狀態
  /// dirty 定義: lastSyncedAt == null 或 lastReviewedAt > lastSyncedAt
  /// 一次 fetch 全部再過濾, Isar 沒有「null 或 X > Y」的 query DSL,
  /// CardState 數量不大(<10k 等級), in-memory filter 可接受
  Future<List<CardState>> getDirtyStates() async {
    final all = await _db.cardStates.where().findAll();
    return all.where((s) {
      final synced = s.lastSyncedAt;
      if (synced == null) return true;
      return s.lastReviewedAt.isAfter(synced);
    }).toList();
  }

  /// Slice 16: 寫入 CardState
  /// markSynced=true 時順手把 lastSyncedAt 設為 lastReviewedAt
  /// (給 sync 流程用,本機 review 寫入時走預設 false)
  Future<void> saveCardState(CardState state, {bool markSynced = false}) async {
    if (markSynced) {
      state.lastSyncedAt = state.lastReviewedAt;
    }
    await _db.writeTxn(() async {
      await _db.cardStates.put(state);
    });
  }

  Future<void> clearAllStates() async {
    await _db.writeTxn(() async {
      await _db.cardStates.clear();
    });
  }

  CardState createNew(String wordId) {
    final now = DateTime.now().toUtc();
    return CardState()
      ..wordId = wordId
      ..easeFactor = 2.5
      ..intervalDays = 1
      ..repetitions = 0
      ..dueAt = now
      ..lastReviewedAt = now
      ..totalReviews = 0
      ..correctReviews = 0;
  }
}
