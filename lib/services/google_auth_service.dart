import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class GoogleAuthService {
  /// ✅ Sign in with Google via Supabase OAuth.
  ///
  /// Opens Google's consent screen, then waits (up to 2 minutes) for
  /// the redirect to bring a session back into the app.
  ///
  /// Returns `true` when a session was established, `false` if the
  /// user cancelled or the flow timed out.
  Future<bool> signInWithGoogle() async {
    try {
      // ✅ Platform-aware redirect:
      //  - Web: send the OAuth code back to the CURRENT page URL so the
      //    browser can receive it (?code=...) after Google consent.
      //  - Native: custom deep-link scheme handled by the app.
      final String redirectTo = kIsWeb
          ? Uri.base.toString()
          : SupabaseConfig.googleRedirectUri;

      final launched = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!launched) return false;

      // Wait for the redirect back into the app to establish a session.
      final completer = Completer<bool>();
      final subscription =
          supabase.auth.onAuthStateChange.listen((state) {
        if (state.session != null && !completer.isCompleted) {
          completer.complete(true);
        }
      });

      final result = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => false,
      );

      await subscription.cancel();
      return result;
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      return false;
    }
  }

  /// ✅ Sign out of Supabase.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('❌ Sign-out error: $e');
    }
  }
}
