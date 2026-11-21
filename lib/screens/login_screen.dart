// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../config/supabase_config.dart';
import '../themes/theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void initState() {
    super.initState();

    // ✅ If Google OAuth redirected back and a session already exists
    // (even after an app relaunch), skip the login screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (supabase.auth.currentSession != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // 🔒 disables device back button
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // 🔹 Soft green glow top-right
            Positioned(
              top: -110,
              right: -80,
              child: _blob(240, const Color(0x1F1E8A5A)),
            ),
            Positioned(
              bottom: -90,
              left: -70,
              child: _blob(200, const Color(0x140F5F3E)),
            ),
            Positioned(
              bottom: 40,
              right: -50,
              child: _blob(140, const Color(0x1AF2A93B)),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: Image.asset(
                        'lib/assets/CookMate_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Heading
                    Text("Welcome back 👋", style: text.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue cooking magic",
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Input
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password Input
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login Button (green gradient)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [AppColors.glow],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // OR Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Image.asset(
                          'lib/assets/google_logo.png',
                          height: 22,
                        ),
                        label: const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          foregroundColor: isDark
                              ? AppColors.darkInk
                              : AppColors.ink,
                          minimumSize: const Size.fromHeight(54),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE7E2DC),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Signup Redirect
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/signup');
                              },
                        child: const Text(
                          "Don't have an account? Sign up",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // Email/Password Login
  Future<void> _login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (!email.text.contains('@')) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signIn(email.text, password.text);
      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showError("Login failed - please try again");
      }
    } on AuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showError("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Google Sign-In (via Supabase OAuth)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await _googleAuthService.signInWithGoogle();
      if (!mounted) return;

      if (success && supabase.auth.currentSession != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signed in with Google!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showError("Google Sign-In was cancelled or timed out");
      }
    } catch (e) {
      _showError("Error signing in with Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(AuthException e) {
    String errorMessage = "Login failed";
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      errorMessage = "Incorrect email or password";
    } else if (message.contains('email not confirmed')) {
      errorMessage = "Please confirm your email first";
    } else if (message.contains('user not found')) {
      errorMessage = "No account found with this email";
    } else if (message.contains('rate limit') ||
        message.contains('too many')) {
      errorMessage = "Too many attempts. Try again later";
    } else if (message.contains('network')) {
      errorMessage = "Network error - check your connection";
    } else {
      errorMessage = "Login failed: ${e.message}";
    }
    _showError(errorMessage);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
