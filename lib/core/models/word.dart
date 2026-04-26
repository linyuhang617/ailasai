class Word {
  final String id;
  final String wordListId;
  final String term;
  final String? phonetic;
  final String definitionZh;
  final String? exampleSentence;
  final String? pos;
  final String? levelTag;

  const Word({
    required this.id,
    required this.wordListId,
    required this.term,
    this.phonetic,
    required this.definitionZh,
    this.exampleSentence,
    this.pos,
    this.levelTag,
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'] as String,
        wordListId: json['word_list_id'] as String,
        term: json['term'] as String,
        phonetic: json['phonetic'] as String?,
        definitionZh: json['definition_zh'] as String,
        exampleSentence: json['example_sentence'] as String?,
        pos: json['pos'] as String?,
        levelTag: json['level_tag'] as String?,
      );
}
