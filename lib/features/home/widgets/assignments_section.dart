import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/assignment.dart';
import '../../../core/services/assignment_service.dart';

final assignmentsProvider = FutureProvider.autoDispose<List<Assignment>>((ref) {
  return AssignmentService().fetchMyAssignments();
});

/// 學生首頁「老師作業」區塊
/// 沒有作業時不顯示（回傳 SizedBox.shrink）
class AssignmentsSection extends ConsumerWidget {
  const AssignmentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '老師作業',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...list.map((a) => _AssignmentCard(assignment: a)),
          ],
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final pct = assignment.progress;
    final isOverdue = assignment.isOverdue;
    final isDone = assignment.completedWords >= assignment.totalWords;

    Color statusColor;
    String statusLabel;
    if (isDone) {
      statusColor = const Color(0xFF3DBA6E);
      statusLabel = '完成';
    } else if (isOverdue) {
      statusColor = const Color(0xFFE05252);
      statusLabel = '已截止';
    } else {
      final daysLeft = assignment.dueAt
          .difference(DateTime.now().toUtc())
          .inDays;
      statusColor = daysLeft <= 2
          ? const Color(0xFFF5A623)
          : Theme.of(context).colorScheme.primary;
      statusLabel = '剩 $daysLeft 天';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.wordListName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assignment.classroomName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 進度條
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? const Color(0xFF3DBA6E) : statusColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${assignment.completedWords} / ${assignment.totalWords} 字',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
