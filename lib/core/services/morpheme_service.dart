import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/morpheme.dart';

class MorphemeService {
  final _db = Supabase.instance.client;

  /// 取得單字的所有字根，依 position 排序
  Future<List<WordMorpheme>> fetchMorphemes(String wordId) async {
    try {
      final response = await _db
          .from('word_morphemes')
          .select('*, morpheme:morphemes(*)')
          .eq('word_id', wordId)
          .order('position');
      return (response as List)
          .map((e) => WordMorpheme.fromJson(e as Map<String, dynamic>))
          .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    } catch (_) {
      return [];
    }
  }

  /// 取得同字根的其他單字（排除當前單字本身，上限 5 筆）
  Future<List<WordFamilyMember>> fetchWordFamily(
    String morphemeId, {
    required String excludeWordId,
  }) async {
    try {
      final response = await _db
          .from('word_morphemes')
          .select('*, word:words(id, term, definition_zh)')
          .eq('morpheme_id', morphemeId)
          .neq('word_id', excludeWordId)
          .limit(5);
      return (response as List)
          .map((e) => WordFamilyMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
