import 'package:flutter/material.dart';

import '../../../core/models/team.dart';
import 'weekly_heatmap.dart';

/// 成員列：頭像 + email + XP + 今日狀態 + 7 日熱圖
class MemberCheckinRow extends StatelessWidget {
  final TeamMember member;
  const MemberCheckinRow({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final emailDisplay = member.email.contains('@')
        ? member.email.split('@').first
        : member.email;
    final initial = emailDisplay.isNotEmpty
        ? emailDisplay[0].toUpperCase()
        : '?';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: member.isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: member.isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              emailDisplay,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: member.isMe
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isCreator) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.shield,
                                size: 14, color: Color(0xFFF5A623)),
                          ],
                          if (member.isMe) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(我)',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${member.xp} XP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (member.todayCheckedIn)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF3DBA6E), size: 24)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: Colors.grey.shade400, size: 24),
              ],
            ),
            const SizedBox(height: 10),
            WeeklyHeatmap(member: member),
          ],
        ),
      ),
    );
  }
}
