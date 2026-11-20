import 'package:supabase_flutter/supabase_flutter.dart';

/// ✅ Supabase credentials for KhaanaBuddy.
///
/// Get these from: Supabase Dashboard → Project Settings → API
///   - Project URL   (e.g. https://abcdefgh.supabase.co)
///   - anon public key (long eyJ... string)
class SupabaseConfig {
  SupabaseConfig._();

  // ⬇️⬇️⬇️ YOUR PROJECT CREDENTIALS ⬇️⬇️⬇️
  static const String url = 'https://njlerjtzpqaycyerefiu.supabase.co';
  static const String anonKey =
      'sb_publishable_akskYsJvTyOvHPkPVkoUxg_PMGfHPQD';
  // ⬆️⬆️⬆️ YOUR PROJECT CREDENTIALS ⬆️⬆️⬆️

  /// OAuth redirect used by Google Sign-In (must match the
  /// intent-filter scheme in AndroidManifest.xml).
  static const String googleRedirectUri =
      'io.supabase.khaanabuddy://login-callback/';
}

/// Shorthand for the shared Supabase client.
/// Import this file anywhere you need `supabase.from(...)`,
/// `supabase.auth...` or `supabase.storage...`.
SupabaseClient get supabase => Supabase.instance.client;
