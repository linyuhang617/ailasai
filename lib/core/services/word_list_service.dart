import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';
import '../models/word_list.dart';

class WordListService {
  final _client = Supabase.instance.client;

  Future<List<WordList>> fetchAllLists(String userId) async {
    try {
      final listsData = await _client
          .from('word_lists')
          .select()
          .order('name');

      final joinedData = await _client
          .from('user_word_lists')
          .select('word_list_id')
          .eq('user_id', userId);

      final joinedIds = <String>{
        for (final e in joinedData) e['word_list_id'] as String,
      };

      final countData = await _client
          .from('card_states')
          .select('word_id, words!inner(word_list_id)')
          .eq('user_id', userId);

      final Map<String, int> reviewedCounts = {};
      for (final row in countData) {
        final wordData = row['words'] as Map<String, dynamic>?;
        if (wordData != null) {
          final wlId = wordData['word_list_id'] as String;
          reviewedCounts[wlId] = (reviewedCounts[wlId] ?? 0) + 1;
        }
      }

      return (listsData as List)
          .map((e) => WordList.fromJson(
                e as Map<String, dynamic>,
                isJoined: joinedIds.contains(e['id']),
                reviewedCount: reviewedCounts[e['id']] ?? 0,
              ))
          .toList();
    } catch (e) {
      throw Exception('fetchAllLists failed: $e');
    }
  }


  Future<WordList?> fetchListById(String listId, String userId) async {
    try {
      final listData = await _client
          .from('word_lists')
          .select()
          .eq('id', listId)
          .maybeSingle();
      if (listData == null) return null;

      final joinedRow = await _client
          .from('user_word_lists')
          .select('word_list_id')
          .eq('user_id', userId)
          .eq('word_list_id', listId)
          .maybeSingle();

      final countData = await _client
          .from('card_states')
          .select('word_id, words!inner(word_list_id)')
          .eq('user_id', userId)
          .eq('words.word_list_id', listId);

      return WordList.fromJson(
        listData,
        isJoined: joinedRow != null,
        reviewedCount: (countData as List).length,
      );
    } catch (e) {
      throw Exception('fetchListById failed: $e');
    }
  }

  Future<void> joinList(String wordListId, String userId) async {
    try {
      await _client.from('user_word_lists').upsert(
        {
          'user_id': userId,
          'word_list_id': wordListId,
          'joined_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,word_list_id',
      );
    } catch (e) {
      throw Exception('joinList failed: $e');
    }
  }

  Future<void> leaveList(String wordListId, String userId) async {
    try {
      await _client
          .from('user_word_lists')
          .delete()
          .eq('user_id', userId)
          .eq('word_list_id', wordListId);
    } catch (e) {
      throw Exception('leaveList failed: $e');
    }
  }

  Future<List<Word>> fetchWordsForJoinedLists(String userId) async {
    try {
      final joinedData = await _client
          .from('user_word_lists')
          .select('word_list_id')
          .eq('user_id', userId);

      if (joinedData.isEmpty) return [];

      final wordListIds = (joinedData as List)
          .map((e) => e['word_list_id'] as String)
          .toList();

      final wordsData = await _client
          .from('words')
          .select()
          .inFilter('word_list_id', wordListIds)
          .order('created_at');

      return (wordsData as List)
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('fetchWordsForJoinedLists failed: $e');
    }
  }
}
