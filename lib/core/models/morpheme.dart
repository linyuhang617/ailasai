class Morpheme {
  final String id;
  final String form;
  final String type; // 'prefix' | 'root' | 'suffix'
  final String meaningZh;
  final String language;

  const Morpheme({
    required this.id,
    required this.form,
    required this.type,
    required this.meaningZh,
    required this.language,
  });

  factory Morpheme.fromJson(Map<String, dynamic> json) => Morpheme(
        id: json['id'] as String,
        form: json['form'] as String,
        type: json['type'] as String,
        meaningZh: json['meaning_zh'] as String,
        language: json['language'] as String? ?? 'en',
      );
}

class WordMorpheme {
  final String id;
  final String wordId;
  final int position;
  final Morpheme morpheme;

  const WordMorpheme({
    required this.id,
    required this.wordId,
    required this.position,
    required this.morpheme,
  });

  factory WordMorpheme.fromJson(Map<String, dynamic> json) => WordMorpheme(
        id: json['id'] as String,
        wordId: json['word_id'] as String,
        position: json['position'] as int,
        morpheme: Morpheme.fromJson(json['morpheme'] as Map<String, dynamic>),
      );
}

class WordFamilyMember {
  final String wordId;
  final String term;
  final String definitionZh;

  const WordFamilyMember({
    required this.wordId,
    required this.term,
    required this.definitionZh,
  });

  factory WordFamilyMember.fromJson(Map<String, dynamic> json) {
    final word = json['word'] as Map<String, dynamic>;
    return WordFamilyMember(
      wordId: word['id'] as String,
      term: word['term'] as String,
      definitionZh: word['definition_zh'] as String,
    );
  }
}
