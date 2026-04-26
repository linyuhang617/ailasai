import 'package:flutter/material.dart';
import '../../../core/models/word.dart';

class WordCardFront extends StatelessWidget {
  final Word word;

  const WordCardFront({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (word.levelTag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9F8),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                word.levelTag!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C6FE0),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            word.term,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3A3358),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          if (word.phonetic != null)
            Text(
              word.phonetic!,
              style: const TextStyle(fontSize: 14, color: Color(0xFFB0A8CC)),
            ),
          const SizedBox(height: 20),
          const Text(
            '點擊翻面',
            style: TextStyle(fontSize: 12, color: Color(0xFFB0A8CC)),
          ),
        ],
      ),
    );
  }
}
