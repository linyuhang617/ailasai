import 'package:flutter/material.dart';
import '../../../core/models/word_list.dart';

class WordListCard extends StatelessWidget {
  const WordListCard({
    super.key,
    required this.wordList,
    required this.onJoin,
    required this.onLeave,
    required this.isLoading,
    this.onTap,
  });

  final WordList wordList;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C6FE0);
    const successGreen = Color(0xFF3DBA6E);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      wordList.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (wordList.isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '已加入',
                        style: TextStyle(
                          color: successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  _Tag(label: wordList.language, color: purple),
                  if (wordList.examType != null)
                    _Tag(
                        label: wordList.examType!,
                        color: const Color(0xFFF5A623)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${wordList.totalWords} 個單字',
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13),
                  ),
                  if (wordList.isJoined && wordList.totalWords > 0) ...[
                    const Spacer(),
                    Text(
                      '${(wordList.progressPercent * 100).round()}% 已複習',
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ],
              ),
              if (wordList.isJoined && wordList.totalWords > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: wordList.progressPercent,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(successGreen),
                    minHeight: 6,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 36,
                          width: 36,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : wordList.isJoined
                        ? OutlinedButton(
                            onPressed: onLeave,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('移除字庫'),
                          )
                        : ElevatedButton(
                            onPressed: onJoin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('開始學習'),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
