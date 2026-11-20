// services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  GoTrueClient get _auth => supabase.auth;

  /// Sign up with email and password.
  /// A profile row is created automatically by the `handle_new_user`
  /// database trigger (see supabase/schema.sql).
  Future<User?> signUp(String email, String password) async {
    print('📝 AuthService: Creating user with email: $email');

    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': ''},
    );

    print('✅ AuthService: User signed up: ${response.user?.email}');
    return response.user;
  }

  /// Sign in with email and password.
  Future<User?> signIn(String email, String password) async {
    print('🔐 AuthService: Signing in user: $email');

    final response = await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    print('✅ AuthService: User signed in: ${response.user?.email}');
    return response.user;
  }

  /// Sign out of Supabase.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user.
  User? getCurrentUser() => _auth.currentUser;

  /// Check if user is logged in.
  bool isUserLoggedIn() => _auth.currentSession != null;
}
