import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../team/screens/team_screen.dart' show myTeamsProvider;

/// 首頁「我的隊伍」section
/// 沒有隊伍時不顯示;有隊伍時 tap 進入 detail
class MyTeamsSection extends ConsumerWidget {
  const MyTeamsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(myTeamsProvider);

    return teamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (teams) {
        if (teams.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.group_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '我的隊伍',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...teams.map(
              (t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => context.push('/team/${t.id}'),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                      if (t.todayCheckedIn) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF3DBA6E),
                        ),
                      ],
                    ],
                  ),
                  subtitle:
                      Text('${t.memberCount}/10 人 · ${t.myXp} XP'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
