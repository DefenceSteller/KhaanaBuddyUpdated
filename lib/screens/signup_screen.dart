import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import '../themes/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 🔹 Soft green glow
          Positioned(
            top: -100,
            left: -70,
            child: _blob(220, const Color(0x1FFF7A1A)),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _blob(180, const Color(0x14FF5A00)),
          ),
          Positioned(
            top: 60,
            right: -40,
            child: _blob(120, const Color(0x1AF2A93B)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Heading
                  Text("Create account ✨", style: text.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    "Start your AI-powered cooking journey",
                    style: text.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
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

                  // Password Field
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimum 6 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Confirm Password Field
                  TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Signup Button (green gradient)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [AppColors.glow],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
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
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Redirect to Login
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                      child: const Text(
                        "Already have an account? Login",
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
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Future<void> _signup() async {
    if (email.text.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (!email.text.contains('@')) {
      _showError("Please enter a valid email address");
      return;
    }

    if (password.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    if (password.text != confirmPassword.text) {
      _showError("Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Attempting signup for: ${email.text}');
      User? user = await _authService.signUp(email.text, password.text);

      if (!mounted) return;

      if (user != null) {
        print('✅ Signup successful for: ${user.email}');

        // With email confirmation enabled, Supabase returns no session
        // until the user clicks the link in their inbox.
        if (supabase.auth.currentSession != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Signup successful!"),
              backgroundColor: AppColors.brand,
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Almost there! Check your email to confirm your account, then log in.",
              ),
              backgroundColor: AppColors.brand,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showError("Signup failed - please try again");
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      String errorMessage = "Signup failed";
      final message = e.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already been registered') ||
          message.contains('user already exists')) {
        errorMessage = "This email is already registered";
      } else if (message.contains('invalid email')) {
        errorMessage = "Please enter a valid email address";
      } else if (message.contains('password')) {
        errorMessage = "Password is too weak - use at least 6 characters";
      } else if (message.contains('rate limit') ||
          message.contains('too many')) {
        errorMessage = "Too many attempts. Try again later";
      } else {
        errorMessage = "Signup failed: ${e.message}";
      }
      _showError(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showError("An unexpected error occurred: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
