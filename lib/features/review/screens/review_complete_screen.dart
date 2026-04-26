import 'package:flutter/material.dart';

class ReviewCompleteScreen extends StatelessWidget {
  final int totalReviewed;
  final int correctReviewed;
  final bool isPractice;
  final VoidCallback? onPracticeAgain;

  const ReviewCompleteScreen({
    super.key,
    required this.totalReviewed,
    required this.correctReviewed,
    this.isPractice = false,
    this.onPracticeAgain,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalReviewed == 0
        ? 0
        : (correctReviewed * 100 / totalReviewed).round();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isPractice ? '💪' : '🎉',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                isPractice ? '加練完成！' : '今日完成！',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A3358)),
              ),
              const SizedBox(height: 32),
              _StatCard(label: '複習總數', value: '$totalReviewed 張'),
              const SizedBox(height: 12),
              _StatCard(label: '正確率', value: '$accuracy%'),
              // 只有正式複習完成且 callback 不為 null 才顯示「再練一次」
              if (onPracticeAgain != null) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onPracticeAgain,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C6FE0),
                        side: const BorderSide(color: Color(0xFF7C6FE0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('再練一次',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C6FE0).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF8A80B0), fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF3A3358))),
        ],
      ),
    );
  }
}
