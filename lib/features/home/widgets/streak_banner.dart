import 'package:flutter/material.dart';

class StreakBanner extends StatelessWidget {
  final int streak;
  const StreakBanner({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5A623), width: 1),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(
            '連續複習 $streak 天',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A5400),
            ),
          ),
          const Spacer(),
          Text(
            streak >= 7 ? '🏆 太強了！' : '繼續保持！',
            style: const TextStyle(fontSize: 13, color: Color(0xFFF5A623)),
          ),
        ],
      ),
    );
  }
}
