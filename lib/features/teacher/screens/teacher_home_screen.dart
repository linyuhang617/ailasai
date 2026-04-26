import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/classroom.dart';
import '../../../core/services/classroom_service.dart';

final _classroomsProvider =
    FutureProvider.autoDispose<List<Classroom>>((ref) async {
  return ClassroomService().fetchMyClassrooms();
});

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_classroomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的班級'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.refresh(_classroomsProvider.future),
          child: list.isEmpty
              ? _EmptyState(onCreate: () => _showCreateDialog(context, ref))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _ClassroomCard(classroom: list[i]),
                ),
        ),
      ),
      floatingActionButton: async.maybeWhen(
        data: (list) => list.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('建立班級'),
              ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('建立班級'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '班級名稱',
            hintText: '例:七年級英文班',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('建立'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await ClassroomService().createClassroom(ctrl.text.trim());
      ref.invalidate(_classroomsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('班級已建立')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('建立失敗:$e')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 72,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '還沒有班級',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '建立第一個班級,開始追蹤學生學習進度',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('建立第一個班級'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final Classroom classroom;
  const _ClassroomCard({required this.classroom});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/classrooms/${classroom.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.black.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text('${classroom.memberCount} 位學生'),
                        const SizedBox(width: 16),
                        Icon(Icons.qr_code,
                            size: 16, color: Colors.black.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          classroom.inviteCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
