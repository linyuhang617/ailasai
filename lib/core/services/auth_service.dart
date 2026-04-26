import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

class AuthService {
  final _auth = Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// 目前登入者的角色;未登入或 metadata 沒寫一律回 [UserRole.student]
  UserRole get currentRole => UserRoleX.fromMeta(currentUser?.userMetadata);

  Future<void> signUp({
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'role': role.name},
    );
    if (res.user == null) throw Exception('註冊失敗,請稍後再試');
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
