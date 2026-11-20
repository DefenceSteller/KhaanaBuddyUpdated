// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../providers/theme_provider.dart';
import '../services/recipe_service.dart';
import '../themes/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RecipeService _recipeService = RecipeService();

  final TextEditingController _nameController = TextEditingController();

  String? _photoUrl;
  int _savedCount = 0;
  int _favoriteCount = 0;
  bool _statsLoading = true;
  bool _isUploadingPhoto = false;
  bool _voiceEnabled = true;
  bool _busy = false;

  User? get _user => supabase.auth.currentUser;

  bool get _emailVerified => _user?.emailConfirmedAt != null;

  bool get _isPasswordUser {
    final providers = _user?.appMetadata['providers'];
    if (providers is List) return providers.contains('email');
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadStats();
    _loadVoicePref();
  }

  // ──────────────────────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────────────────────

  Future<void> _loadProfileData() async {
    final user = _user;
    if (user == null) return;

    // Fallbacks from auth metadata
    final metaName =
        user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
    if (metaName is String && metaName.isNotEmpty) {
      _nameController.text = metaName;
    }
    final metaPhoto = user.userMetadata?['photo_url'];
    if (metaPhoto is String) _photoUrl = metaPhoto;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        if (data['name'] != null) _nameController.text = data['name'];
        if (data['photo_url'] != null) _photoUrl = data['photo_url'];
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadStats() async {
    final user = _user;
    if (user == null) return;

    try {
      final saved = await _recipeService.countRecipes(user.id);
      final favs =
          await _recipeService.countRecipes(user.id, isFavorite: true);
      if (mounted) {
        setState(() {
          _savedCount = saved;
          _favoriteCount = favs;
          _statsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadVoicePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _voiceEnabled = prefs.getBool('voiceEnabled') ?? true);
      }
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────
  // Profile photo (image_picker → Supabase Storage → profiles table)
  // ──────────────────────────────────────────────────────────────

  Future<void> _changePhoto() async {
    final user = _user;
    if (user == null || _isUploadingPhoto) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      // Unique path avoids stale CDN-cached public URLs.
      final ext = picked.path.contains('.')
          ? picked.path.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from('avatars').upload(
            path,
            File(picked.path),
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      final url = supabase.storage.from('avatars').getPublicUrl(path);

      await supabase.from('profiles').upsert({
        'id': user.id,
        'photo_url': url,
      });
      try {
        await supabase.auth
            .updateUser(UserAttributes(data: {'photo_url': url}));
      } catch (_) {}

      if (mounted) {
        setState(() => _photoUrl = url);
        _showSnack('Profile photo updated ✅', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnack('Couldn\'t upload photo: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Settings
  // ──────────────────────────────────────────────────────────────

  Future<void> _toggleVoice(bool value) async {
    setState(() => _voiceEnabled = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voiceEnabled', value);
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────
  // Edit name
  // ──────────────────────────────────────────────────────────────

  Future<void> _editNameDialog() async {
    final ctrl = TextEditingController(text: _nameController.text);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Edit name',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(96, 44),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) return;

    final name = ctrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Name cannot be empty', Colors.red);
      return;
    }

    final user = _user;
    if (user == null) return;

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'email': user.email,
      });
      try {
        await supabase.auth
            .updateUser(UserAttributes(data: {'full_name': name}));
      } catch (e) {
        debugPrint('Non-fatal: updateUser metadata failed: $e');
      }

      if (mounted) {
        setState(() => _nameController.text = name);
        _showSnack('Name updated ✅', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnack('Error saving name: $e', Colors.red);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Email verification
  // ──────────────────────────────────────────────────────────────

  Future<void> _handleEmailTap() async {
    final user = _user;
    if (user == null) return;

    if (user.emailConfirmedAt != null) {
      _showSnack('Your email is verified ✓', Colors.green);
      return;
    }

    try {
      await supabase.auth.resend(type: OtpType.email, email: user.email);
      _showSnack('Verification email sent to ${user.email}', Colors.green);
    } catch (e) {
      _showSnack('Couldn\'t send verification email: $e', Colors.red);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Change password
  // ──────────────────────────────────────────────────────────────

  Future<void> _changePasswordDialog() async {
    final user = _user;
    if (user == null) return;

    if (!_isPasswordUser) {
      _showSnack(
        'You sign in with Google — manage your password in your Google Account.',
        Colors.orange,
      );
      return;
    }

    final current = TextEditingController();
    final fresh = TextEditingController();
    final confirm = TextEditingController();

    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'Change password',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: fresh,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      hintText: 'Minimum 6 characters',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: Icon(Icons.lock_person_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(110, 44),
                ),
                child: const Text('Update'),
              ),
            ],
        );
      },
    );

    if (done != true || !mounted) return;

    // Validation
    if (current.text.isEmpty ||
        fresh.text.isEmpty ||
        confirm.text.isEmpty) {
      _showSnack('Please fill all password fields', Colors.red);
      return;
    }
    if (fresh.text.length < 6) {
      _showSnack('New password must be at least 6 characters', Colors.red);
      return;
    }
    if (fresh.text != confirm.text) {
      _showSnack('New passwords do not match', Colors.red);
      return;
    }

    setState(() => _busy = true);
    try {
      // Supabase requires a fresh sign-in (re-auth) before changing
      // the password — verify the current one first.
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: current.text,
      );
      await supabase.auth.updateUser(UserAttributes(password: fresh.text));
      if (mounted) _showSnack('Password changed successfully 🔑', Colors.green);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      String msg;
      if (message.contains('invalid login credentials')) {
        msg = 'Current password is incorrect';
      } else if (message.contains('password')) {
        msg = 'New password is too weak - use at least 6 characters';
      } else if (message.contains('recent') ||
          message.contains('session') ||
          message.contains('same password')) {
        msg = 'Please log out, log back in, then try again';
      } else {
        msg = e.message;
      }
      if (mounted) _showSnack(msg, Colors.red);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────────────────────

  Future<void> _confirmLogout() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        icon: Icons.logout_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Log out?',
        message: 'You\'ll need to sign in again to access your saved recipes.',
        confirmLabel: 'Log out',
        confirmColor: const Color(0xFFEF4444),
      ),
    );
    if (go != true || !mounted) return;

    try {
      await supabase.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ──────────────────────────────────────────────────────────────
  // Delete account
  // ──────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        icon: Icons.delete_forever_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Delete account?',
        message:
            'This permanently deletes your account and all saved recipes. '
            'This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFEF4444),
      ),
    );
    if (go != true || !mounted) return;

    final user = _user;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      // Deletes the auth user; profiles + recipes cascade via FK.
      await supabase.rpc('delete_my_account');

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } on PostgrestException catch (e) {
      String msg = 'Couldn\'t delete account: ${e.message}';
      if (mounted) _showSnack(msg, Colors.red);
    } on AuthException catch (e) {
      String msg = 'Couldn\'t delete account';
      if (e.message.toLowerCase().contains('recent') ||
          e.message.toLowerCase().contains('session')) {
        msg =
            'For security, please log out, log back in, then delete your account.';
      } else {
        msg = e.message;
      }
      if (mounted) _showSnack(msg, Colors.red);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Info dialogs
  // ──────────────────────────────────────────────────────────────

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _infoDialog({
    required String title,
    required Widget content,
    IconData icon = Icons.info_outline_rounded,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(child: content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _helpDialog() {
    _infoDialog(
      icon: Icons.help_outline_rounded,
      title: 'Help & FAQ',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _FaqItem(
            q: 'How do I find a recipe?',
            a: 'Enter your ingredients on the home screen, pick a cuisine '
                'and tap "Find Recipes".',
          ),
          _FaqItem(
            q: 'Can I save recipes?',
            a: 'Yes! Open any recipe and tap the "Save Recipe" button. '
                'Saved recipes appear in your Recipe History.',
          ),
          _FaqItem(
            q: 'How does the AI work?',
            a: 'KhaanaBuddy uses Google Gemini to generate personalized '
                'recipes from your ingredients.',
          ),
          _FaqItem(
            q: 'Is there a video tutorial?',
            a: 'Most recipes include a matching YouTube tutorial right '
                'below the recipe card.',
          ),
        ],
      ),
    );
  }

  void _aboutDialog() {
    _infoDialog(
      icon: Icons.restaurant_menu_rounded,
      title: 'About KhaanaBuddy',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'lib/assets/CookMate_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'KhaanaBuddy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your AI cooking companion! KhaanaBuddy turns the ingredients '
            'you already have into personalized recipes, complete with '
            'video tutorials and voice-guided cooking.',
            style: TextStyle(fontSize: 14.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _privacyDialog() {
    _infoDialog(
      icon: Icons.shield_rounded,
      title: 'Privacy Policy',
      content: const Text(
        'KhaanaBuddy only collects the data needed to run the app:\n\n'
        '• Your name and email for your account\n'
        '• Recipes you choose to save\n'
        '• Your profile photo, if you upload one\n\n'
        'We never sell your data. You can delete your account and all '
        'associated data at any time from this screen.',
        style: TextStyle(fontSize: 14.5, height: 1.6),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────

  String _joinedLabel() {
    // Supabase stores createdAt as an ISO-8601 string.
    final dynamic raw = _user?.createdAt;
    DateTime? t;
    if (raw is String) {
      t = DateTime.tryParse(raw);
    } else if (raw is DateTime) {
      t = raw;
    }
    if (t == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[t.month - 1]} ${t.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final iconBg = isDark ? const Color(0x2EFF7A1A) : AppColors.tint;

    final displayName = _nameController.text.isEmpty
        ? 'Add your name'
        : _nameController.text;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _busy ? null : _confirmLogout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        children: [
          // ══════════ Gradient hero header ══════════
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: const BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [AppColors.glow],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with camera badge
                    Stack(
                      children: [
                        Container(
                          width: 94,
                          height: 94,
                          padding: const EdgeInsets.all(3.5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _photoUrl != null
                                ? Image.network(
                                    _photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(
                                      Icons.person_rounded,
                                      size: 46,
                                      color: AppColors.orange,
                                    ),
                                  )
                                : Container(
                                    color: AppColors.tint,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 46,
                                      color: AppColors.orange,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isUploadingPhoto ? null : _changePhoto,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: _isUploadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(7),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: AppColors.orange,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: AppColors.orange,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Name + email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: Color(0xCCFFFFFF),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _user?.email ?? 'No email',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Verification chip
                          GestureDetector(
                            onTap: _handleEmailTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _emailVerified
                                    ? const Color(0x33FFFFFF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _emailVerified
                                        ? Icons.verified_rounded
                                        : Icons.error_outline_rounded,
                                    size: 13,
                                    color: _emailVerified
                                        ? Colors.white
                                        : AppColors.orangeDeep,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _emailVerified
                                        ? 'Verified'
                                        : 'Verify email',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _emailVerified
                                          ? Colors.white
                                          : AppColors.orangeDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: _statsLoading ? '…' : '$_savedCount',
                        label: 'Saved',
                        loading: _statsLoading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: _statsLoading ? '…' : '$_favoriteCount',
                        label: 'Favorites',
                        loading: _statsLoading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: _joinedLabel(),
                        label: 'Joined',
                        loading: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ══════════ ACCOUNT ══════════
                const _SectionLabel('ACCOUNT'),
                _SettingsCard(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconBg: iconBg,
                      title: 'Personal information',
                      subtitle: displayName,
                      onTap: _editNameDialog,
                    ),
                    Divider(indent: 72, color: borderColor),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      iconBg: iconBg,
                      title: 'Email address',
                      subtitle: _user?.email ?? '',
                      trailing: _emailVerified
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 17,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Verify',
                                style: TextStyle(
                                  color: AppColors.orangeDeep,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                      onTap: _handleEmailTap,
                    ),
                    Divider(indent: 72, color: borderColor),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconBg: iconBg,
                      title: 'Change password',
                      subtitle: _isPasswordUser
                          ? 'Update your login password'
                          : 'Managed by your Google Account',
                      onTap: _changePasswordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ══════════ PREFERENCES ══════════
                const _SectionLabel('PREFERENCES'),
                _SettingsCard(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      iconBg: iconBg,
                      title: 'Dark mode',
                      subtitle: 'Easy on the eyes at night',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                      ),
                    ),
                    Divider(indent: 72, color: borderColor),
                    _SettingsTile(
                      icon: Icons.record_voice_over_outlined,
                      iconBg: iconBg,
                      title: 'Voice assistant',
                      subtitle: 'Read recipes aloud automatically',
                      trailing: Switch(
                        value: _voiceEnabled,
                        onChanged: _toggleVoice,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ══════════ SUPPORT ══════════
                const _SectionLabel('SUPPORT'),
                _SettingsCard(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconBg: iconBg,
                      title: 'Help & FAQ',
                      onTap: _helpDialog,
                    ),
                    Divider(indent: 72, color: borderColor),
                    _SettingsTile(
                      icon: Icons.restaurant_menu_rounded,
                      iconBg: iconBg,
                      title: 'About KhaanaBuddy',
                      onTap: _aboutDialog,
                    ),
                    Divider(indent: 72, color: borderColor),
                    _SettingsTile(
                      icon: Icons.shield_rounded,
                      iconBg: iconBg,
                      title: 'Privacy Policy',
                      onTap: _privacyDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ══════════ ACCOUNT ACTIONS ══════════
                const _SectionLabel('ACCOUNT ACTIONS'),
                _SettingsCard(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconBg: isDark
                          ? const Color(0x26EF4444)
                          : const Color(0x1AEF4444),
                      iconColor: const Color(0xFFEF4444),
                      title: 'Log out',
                      titleColor: const Color(0xFFEF4444),
                      onTap: _confirmLogout,
                    ),
                    Divider(indent: 72, color: borderColor),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconBg: isDark
                          ? const Color(0x26EF4444)
                          : const Color(0x1AEF4444),
                      iconColor: const Color(0xFFEF4444),
                      title: 'Delete account',
                      subtitle: 'Permanently remove your data',
                      titleColor: const Color(0xFFEF4444),
                      onTap: _confirmDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ══════════ Footer ══════════
                Center(
                  child: Text(
                    'KhaanaBuddy • Version 1.0.0',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 18),
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Building blocks
// ════════════════════════════════════════════════════════════════

/// Small uppercase section label.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

/// White rounded card that holds setting tiles.
class _SettingsCard extends StatelessWidget {
  final Color surfaceColor;
  final Color borderColor;
  final List<Widget> children;

  const _SettingsCard({
    required this.surfaceColor,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? const [] : const [AppColors.softShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Icon + title + subtitle + trailing row.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 21,
                color: iconColor ?? AppColors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// Translucent stat tile inside the gradient header.
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool loading;

  const _StatCard({
    required this.value,
    required this.label,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// FAQ entry for the help dialog.
class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable confirmation dialog (logout / delete).
class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14.5, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.muted,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            minimumSize: const Size(110, 46),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 46),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
