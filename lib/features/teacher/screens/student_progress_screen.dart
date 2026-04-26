import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/classroom_service.dart';

final _progressProvider = FutureProvider.autoDispose
    .family<StudentProgress, ({String classroomId, String studentId})>(
  (ref, args) => ClassroomService().fetchStudentProgress(
    classroomId: args.classroomId,
    studentId: args.studentId,
  ),
);

class StudentProgressScreen extends ConsumerWidget {
  final String classroomId;
  final String studentId;
  final String? studentEmail;

  const StudentProgressScreen({
    super.key,
    required this.classroomId,
    required this.studentId,
    this.studentEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (classroomId: classroomId, studentId: studentId);
    final progressAsync = ref.watch(_progressProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text(studentEmail ?? '學生進度'),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('載入失敗', style: TextStyle(color: Colors.red.shade400)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(_progressProvider(args)),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () async => ref.refresh(_progressProvider(args)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatCard(
                icon: Icons.style_outlined,
                label: '已複習單字數',
                value: '${p.wordsStarted} 個',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.repeat,
                label: '總複習次數',
                value: '${p.totalReviews} 次',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.check_circle_outline,
                label: '正確率',
                value: p.totalReviews == 0
                    ? '—'
                    : '${(p.correctRate * 100).round()}%',
                valueColor: p.totalReviews == 0
                    ? null
                    : p.correctRate >= 0.7
                        ? const Color(0xFF3DBA6E)
                        : p.correctRate >= 0.4
                            ? const Color(0xFFF5A623)
                            : const Color(0xFFE05252),
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.timeline_outlined,
                label: '平均記憶穩定性',
                value: p.wordsStarted == 0
                    ? '—'
                    : '${p.avgStability.toStringAsFixed(1)} 天',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.access_time_outlined,
                label: '最後複習時間',
                value: p.lastReviewedAt == null
                    ? '尚未複習'
                    : _formatDate(p.lastReviewedAt!),
              ),
              if (p.wordsStarted == 0) ...[
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    '此學生尚未開始複習',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.year}/${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
