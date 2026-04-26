import 'package:flutter/material.dart';
import '../../../core/models/word_list.dart';

class ActiveListsSection extends StatelessWidget {
  final List<WordList> lists;

  const ActiveListsSection({super.key, required this.lists});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '進行中字庫',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...lists.map((list) => _WordListRow(list: list)),
      ],
    );
  }
}

class _WordListRow extends StatelessWidget {
  final WordList list;
  const _WordListRow({required this.list});

  @override
  Widget build(BuildContext context) {
    final pct = list.progressPercent;
    final pctDisplay = (pct * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  list.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pctDisplay%',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7C6FE0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7C6FE0)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${list.reviewedCount} / ${list.totalWords} 個單字',
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
