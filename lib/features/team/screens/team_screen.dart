import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/team.dart';
import '../../../core/services/team_service.dart';

/// 全域 provider:我加入的所有隊伍清單
/// my_teams_section / team_screen / team_detail 三處共用
final myTeamsProvider = FutureProvider.autoDispose<List<Team>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return TeamService().fetchMyTeams();
});

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final _service = TeamService();

  @override
  void initState() {
    super.initState();
    // 進入時 fire-and-forget 結算 XP，完成後刷新清單
    _settleAndRefresh();
  }

  Future<void> _settleAndRefresh() async {
    await _service.settleXp();
    if (!mounted) return;
    ref.invalidate(myTeamsProvider);
  }

  Future<void> _goCreateJoin() async {
    final result = await context.push<bool>('/team/new');
    if (result == true && mounted) {
      ref.invalidate(myTeamsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(myTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的隊伍'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '建立或加入',
            onPressed: _goCreateJoin,
          ),
        ],
      ),
      body: teamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('載入失敗', style: TextStyle(color: Colors.red.shade400)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(myTeamsProvider),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
        data: (teams) => RefreshIndicator(
          onRefresh: () async {
            await _service.settleXp();
            ref.invalidate(myTeamsProvider);
            await ref.read(myTeamsProvider.future);
          },
          child: teams.isEmpty
              ? _EmptyState(onCreateJoin: _goCreateJoin)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: teams.map((t) => _TeamCard(team: t)).toList(),
                ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/team/${team.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            team.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (team.isCreator) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.shield,
                              size: 16, color: Color(0xFFF5A623)),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: team.todayCheckedIn
                          ? const Color(0xFF3DBA6E).withValues(alpha: 0.12)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          team.todayCheckedIn
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 14,
                          color: team.todayCheckedIn
                              ? const Color(0xFF3DBA6E)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          team.todayCheckedIn ? '今日已打卡' : '尚未打卡',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: team.todayCheckedIn
                                ? const Color(0xFF3DBA6E)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${team.memberCount} / 10',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.bolt,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 2),
                  Text(
                    '${team.myXp} XP',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    team.inviteCode,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateJoin;
  const _EmptyState({required this.onCreateJoin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(Icons.group_outlined,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                '還沒有加入任何隊伍',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '與朋友組隊互相督促，\n每天複習 10 張卡自動打卡!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
                onPressed: onCreateJoin,
                child: const Text('建立或加入'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
