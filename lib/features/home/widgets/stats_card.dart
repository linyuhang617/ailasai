import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int dueCount;
  final int todayCompleted;
  final int newToday;

  const StatsCard({
    super.key,
    required this.dueCount,
    required this.todayCompleted,
    required this.newToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              label: '待複習',
              value: '$dueCount',
              color: const Color(0xFF7C6FE0),
              icon: Icons.layers_outlined,
            ),
            const VerticalDivider(width: 1, thickness: 1, indent: 16, endIndent: 16),
            _StatCell(
              label: '今日完成',
              value: '$todayCompleted',
              color: const Color(0xFF3DBA6E),
              icon: Icons.check_circle_outline,
            ),
            const VerticalDivider(width: 1, thickness: 1, indent: 16, endIndent: 16),
            _StatCell(
              label: '新單字',
              value: '$newToday',
              color: const Color(0xFFF5A623),
              icon: Icons.star_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
