import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';

class WordService {
  final _client = Supabase.instance.client;

  Future<List<Word>> fetchWords(String wordListId) async {
    try {
      final data = await _client
          .from('words')
          .select()
          .eq('word_list_id', wordListId)
          .order('created_at');
      return (data as List).map((e) => Word.fromJson(e)).toList();
    } catch (e) {
      throw Exception('fetchWords failed: $e');
    }
  }
}
