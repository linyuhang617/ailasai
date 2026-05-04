import 'package:flutter/material.dart';

import '../../../core/models/team.dart';

/// 7 日打卡熱圖 - 橫向 7 格
/// 綠 = 有打卡, 灰 = 無打卡, 今天加邊框
class WeeklyHeatmap extends StatelessWidget {
  final TeamMember member;
  const WeeklyHeatmap({super.key, required this.member});

  static const _weekdayChars = ['日', '一', '二', '三', '四', '五', '六'];

  String _weekdayLabel(DateTime utcDate) {
    // DateTime.weekday: 1=Mon..7=Sun
    return _weekdayChars[utcDate.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final days = TeamDetail.last7DaysUtc();
    final todayKey =
        DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final theme = Theme.of(context);

    return Row(
      children: days.map((day) {
        final dayKey = day.toIso8601String().substring(0, 10);
        final checkedIn = member.weeklyCheckIns.contains(dayKey);
        final isToday = dayKey == todayKey;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: checkedIn
                        ? const Color(0xFF3DBA6E)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _weekdayLabel(day),
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday
                        ? theme.colorScheme.primary
                        : Colors.grey.shade600,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
