import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/library/screens/word_list_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/student/screens/join_classroom_screen.dart';
import '../../features/student/screens/qr_scanner_screen.dart';
import '../../features/teacher/screens/classroom_screen.dart';
import '../../features/teacher/screens/student_progress_screen.dart';
import '../../features/teacher/screens/teacher_home_screen.dart';
import '../services/notification_service.dart';
import '../services/role_provider.dart';
import '../services/user_role.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  final auth = Supabase.instance.client.auth;
  final notifier = _AuthNotifier(auth);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/home',
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // 學生加入班級:走 root navigator,沒有底部導航
      GoRoute(
        path: '/join-classroom',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const JoinClassroomScreen(),
        routes: [
          GoRoute(
            path: 'scan',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, _) => const QrScannerScreen(),
          ),
        ],
      ),

      // 班級詳情:走 root navigator(教師看自己班)
      GoRoute(
        path: '/classrooms/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ClassroomScreen(
          classroomId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'student/:studentId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => StudentProgressScreen(
              classroomId: state.pathParameters['id']!,
              studentId: state.pathParameters['studentId']!,
              studentEmail: state.uri.queryParameters['email'],
            ),
          ),
        ],
      ),

      // 主要 ShellRoute:底部導航 = 首頁(依 role 分流) / 字庫 / 設定
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _ScaffoldWithNavBar(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const _RoleAwareHome(),
          ),
          GoRoute(
            path: '/library',
            builder: (_, _) => const LibraryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => WordListDetailScreen(
                  listId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  // Deep link:通知點擊 → 導向 /home(HomeScreen 的按鈕帶出複習)
  NotificationService.instance.onTapCallback = (payload) {
    debugPrint('[Router] 通知點擊 payload=$payload');
    final ctx = _rootNavigatorKey.currentContext;
    if (ctx != null) {
      GoRouter.of(ctx).go('/home');
    }
  };

  return router;
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(GoTrueClient auth) {
    auth.onAuthStateChange.listen((_) => notifyListeners());
  }
}

/// 依 roleProvider 決定 /home 顯示學生首頁還是教師首頁
class _RoleAwareHome extends ConsumerWidget {
  const _RoleAwareHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);
    // Stream 尚未吐值時先用同步值(auth 已登入,metadata 已在 client)
    final role = roleAsync.maybeWhen(
      data: (r) => r,
      orElse: readCurrentRole,
    );
    return role.isTeacher ? const TeacherHomeScreen() : const HomeScreen();
  }
}

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.location, required this.child});

  final String location;
  final Widget child;

  int get _currentIndex {
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/library');
            case 2:
              context.go('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: '字庫',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
