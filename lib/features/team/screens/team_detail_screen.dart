import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/team.dart';
import '../../../core/services/team_service.dart';
import '../widgets/member_checkin_row.dart';
import 'team_screen.dart' show myTeamsProvider;

final teamDetailProvider =
    FutureProvider.autoDispose.family<TeamDetail, String>((ref, teamId) {
  return TeamService().fetchTeamDetail(teamId);
});

class TeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  final _service = TeamService();

  Future<void> _confirmLeave(bool isCreator) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCreator ? '解散隊伍?' : '退出隊伍?'),
        content: Text(isCreator
            ? '你是隊長,退出將解散整個隊伍,所有打卡紀錄會清除。'
            : '退出後將無法再看到此隊伍的打卡紀錄。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE05252)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isCreator ? '解散' : '退出'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _service.leaveTeam(widget.teamId);
      if (!mounted) return;
      ref.invalidate(myTeamsProvider);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/team');
      }
    } on TeamException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('邀請碼 $code 已複製')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(teamDetailProvider(widget.teamId));
    // 從 myTeamsProvider 找這個 team 的 invite_code 與 name
    final myTeamsAsync = ref.watch(myTeamsProvider);
    final team = myTeamsAsync.maybeWhen(
      data: (list) {
        for (final t in list) {
          if (t.id == widget.teamId) return t;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(team?.name ?? '隊伍'),
        actions: [
          detailAsync.maybeWhen(
            data: (detail) {
              final me = detail.me;
              if (me == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.exit_to_app),
                tooltip: me.isCreator ? '解散' : '退出',
                onPressed: () => _confirmLeave(me.isCreator),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('載入失敗',
                    style: TextStyle(color: Colors.red.shade400)),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(teamDetailProvider(widget.teamId)),
                  child: const Text('重試'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teamDetailProvider(widget.teamId));
            ref.invalidate(myTeamsProvider);
            await ref.read(teamDetailProvider(widget.teamId).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (team != null)
                _InviteCard(team: team, onCopy: _copyInviteCode),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.leaderboard_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('本週排行',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ...detail.members.map((m) => MemberCheckinRow(member: m)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Team team;
  final void Function(String code) onCopy;
  const _InviteCard({required this.team, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => onCopy(team.inviteCode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.group, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${team.memberCount} / 10 位成員',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          team.inviteCode,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy,
                            size: 16, color: Colors.grey.shade500),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
