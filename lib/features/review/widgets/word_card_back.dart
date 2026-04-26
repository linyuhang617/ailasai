import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/card_state.dart';
import '../../../core/models/word.dart';
import '../../../core/services/local_storage_service.dart';
import 'morpheme_breakdown.dart';

class WordCardBack extends StatelessWidget {
  final Word word;

  const WordCardBack({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 字根上色單字（無資料時自動隱藏）
          MorphemeBreakdown(wordId: word.id, wordTerm: word.term),
          if (word.pos != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2FC),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                word.pos!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB0A8CC),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            word.definitionZh,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3A3358),
              letterSpacing: -0.3,
            ),
          ),
          if (word.exampleSentence != null) ...[
            const SizedBox(height: 16),
            Container(width: 36, height: 1, color: const Color(0xFFEDEAF7)),
            const SizedBox(height: 16),
            Text(
              word.exampleSentence!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB0A8CC),
                fontStyle: FontStyle.italic,
                height: 1.65,
              ),
            ),
          ],
          _FsrsStatsRow(wordId: word.id),
        ],
      ),
    );
  }
}

class _FsrsStatsRow extends StatefulWidget {
  const _FsrsStatsRow({required this.wordId});
  final String wordId;

  @override
  State<_FsrsStatsRow> createState() => _FsrsStatsRowState();
}

class _FsrsStatsRowState extends State<_FsrsStatsRow> {
  late final Future<CardState?> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalStorageService().getStateByWordId(widget.wordId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CardState?>(
      future: _future,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || state.totalReviews == 0) {
          return const SizedBox.shrink();
        }
        // SM-2 用戶 stability 永遠是 0，只顯示複習次數
        final hasFsrsData = state.stability > 0;

        final nowUtc = DateTime.now().toUtc();
        final elapsedDays =
            nowUtc.difference(state.lastReviewedAt.toUtc()).inHours / 24.0;
        final r = hasFsrsData
            ? math.exp(-elapsedDays / state.stability).clamp(0.0, 1.0)
            : 0.0;

        final parts = <String>[];
        if (hasFsrsData) {
          parts.add('穩定性 ${state.stability.toStringAsFixed(1)} 天');
          parts.add('可提取性 ${(r * 100).round()}%');
        }
        parts.add('複習 ${state.totalReviews} 次');

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            parts.join(' · '),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFB0A8CC),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
