import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/algorithm_service.dart';
import 'core/services/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
  await LocalStorageService.init();
  await NotificationService.instance.init();

  // 啟動前讀本地快取，存入 bootTheme，消除閃色
  final prefs = await SharedPreferences.getInstance();
  bootTheme = themeById(prefs.getString(kThemePrefKey) ?? 'purple');
  await preloadAlgorithm();

  runApp(const ProviderScope(child: AilasaiApp()));
}

class AilasaiApp extends ConsumerStatefulWidget {
  const AilasaiApp({super.key});

  @override
  ConsumerState<AilasaiApp> createState() => _AilasaiAppState();
}

class _AilasaiAppState extends ConsumerState<AilasaiApp> {
  late final _router = buildAppRouter();

  @override
  Widget build(BuildContext context) {
    final scheme = ref.watch(themeProvider).valueOrNull ?? kThemePurple;
    return MaterialApp.router(
      title: '愛喇賽',
      debugShowCheckedModeBanner: false,
      theme: scheme.toThemeData(),
      routerConfig: _router,
    );
  }
}
