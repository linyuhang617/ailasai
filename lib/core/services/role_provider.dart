import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

/// Slice 12 — 當前登入者的角色(從 Supabase auth 讀)
///
/// 登入/登出/註冊時自動重算,UI watch 這個 provider 即可。
final roleProvider = StreamProvider<UserRole>((ref) {
  final auth = Supabase.instance.client.auth;

  // 先吐出當前值,之後隨 auth state change 推新值
  UserRole current() => UserRoleX.fromMeta(auth.currentUser?.userMetadata);

  return auth.onAuthStateChange
      .map((_) => current())
      .asBroadcastStream()
      .distinct();
}, name: 'roleProvider');

/// 同步讀當前 role(給 initState 類場景用,不觸發 rebuild)
UserRole readCurrentRole() {
  return UserRoleX.fromMeta(
    Supabase.instance.client.auth.currentUser?.userMetadata,
  );
}
