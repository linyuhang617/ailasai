import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/stats_service.dart';
import '../../review/screens/review_screen.dart';
import '../../review/screens/practice_screen.dart';
import '../widgets/active_lists_section.dart';
import '../widgets/stats_card.dart';
import '../widgets/my_classrooms_section.dart';
import '../widgets/my_teams_section.dart';
import '../widgets/assignments_section.dart';
import '../widgets/streak_banner.dart';

final _homeStatsProvider = FutureProvider.autoDispose<HomeStats>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('未登入');
  return StatsService().loadHomeStats(userId);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notif = NotificationService.instance;
    // 首次啟動請求權限（已授權則靜默返回 true）
    final granted = await notif.requestPermission();
    if (granted) {
      // 今日已複習則把通知推到明天
      await notif.rescheduleIfDoneToday();
      // 若從未排程，排一次
      final enabled = await notif.isEnabled();
      if (enabled) await notif.scheduleDaily();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_homeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('愛喇賽'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: '加入班級',
            onPressed: () => context.push('/join-classroom'),
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: '我的隊伍',
            onPressed: () => context.push('/team'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('載入失敗', style: TextStyle(color: Colors.red.shade400)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(_homeStatsProvider),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            // Slice 16: pull-to-refresh 順手 sync card_states
            // 失敗靜默(SyncService 內部已 try/catch),不擋 UI 刷新
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) await SyncService().sync(userId);
            ref.invalidate(_homeStatsProvider);
          },
          child: stats.hasJoinedLists
              ? _Dashboard(stats: stats)
              : _EmptyStateWithClassrooms(),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final HomeStats stats;
  const _Dashboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        StreakBanner(streak: stats.streak),
        if (stats.streak > 0) const SizedBox(height: 14),
        StatsCard(
          dueCount: stats.dueCount,
          todayCompleted: stats.todayCompleted,
          newToday: stats.newToday,
        ),
        const SizedBox(height: 20),
        ActiveListsSection(lists: stats.joinedLists),
        const AssignmentsSection(),
        const MyClassroomsSection(),
        const MyTeamsSection(),
        const SizedBox(height: 24),
        _MainButton(stats: stats),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  final HomeStats stats;
  const _MainButton({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.allDone) {
      return Material(
        color: const Color(0xFF3DBA6E),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PracticeScreen(words: stats.allWords),
            ));
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '今日複習完成 🎉',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '點此再練一次',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 0),
      ),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReviewScreen(words: stats.dueWords),
        ));
      },
      child: Text(
        '開始複習（${stats.dueCount} 張）',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyStateWithClassrooms extends StatelessWidget {
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
              const Icon(Icons.library_books_outlined,
                  size: 56, color: Color(0xFF7C6FE0)),
              const SizedBox(height: 16),
              const Text(
                '還沒有加入任何字庫',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '前往字庫選擇想學習的單字清單，\n開始你的記憶之旅！',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
                onPressed: () => context.go('/library'),
                child: const Text('瀏覽字庫'),
              ),
            ],
          ),
        ),
        const AssignmentsSection(),
        const MyClassroomsSection(),
        const MyTeamsSection(),
      ],
    );
  }
}
