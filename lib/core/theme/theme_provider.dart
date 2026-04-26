import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_themes.dart';

const kThemePrefKey = 'theme_color';

AppColorScheme bootTheme = kThemePurple;

class ThemeNotifier extends AsyncNotifier<AppColorScheme> {
  static final _db = Supabase.instance.client;

  @override
  Future<AppColorScheme> build() async {
    _syncFromSupabase();
    return bootTheme;
  }

  Future<void> _syncFromSupabase() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await _db
          .from('user_settings')
          .select('theme_color')
          .eq('user_id', userId)
          .maybeSingle();
      final remoteId = row?['theme_color'] as String? ?? 'purple';
      final remoteScheme = themeById(remoteId);
      if (remoteScheme.id != state.valueOrNull?.id) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kThemePrefKey, remoteId);
        state = AsyncData(remoteScheme);
      }
    } catch (e) {
      debugPrint('[ThemeNotifier] sync failed: $e');
    }
  }

  Future<void> setTheme(AppColorScheme scheme) async {
    state = AsyncData(scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kThemePrefKey, scheme.id);
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _db.from('user_settings').upsert({
        'user_id': userId,
        'theme_color': scheme.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('[ThemeNotifier] upsert failed: $e');
    }
  }
}

final themeProvider =
    AsyncNotifierProvider<ThemeNotifier, AppColorScheme>(ThemeNotifier.new);
