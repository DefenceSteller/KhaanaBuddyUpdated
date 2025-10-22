import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Sign Up"),
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFFF7A1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Account ✨",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFFFF7A1A),
              ),
            ),
            const SizedBox(height: 30),

            // Email Field
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                prefixIcon: Icon(Icons.email,
                    color: isDark ? Colors.orange : const Color(0xFFFF7A1A)),
                filled: true,
                fillColor:
                    isDark ? Colors.grey[850] : Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDark ? Colors.orange : const Color(0xFFFF7A1A),
                      width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextField(
              controller: password,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                prefixIcon: Icon(Icons.lock,
                    color: isDark ? Colors.orange : const Color(0xFFFF7A1A)),
                filled: true,
                fillColor:
                    isDark ? Colors.grey[850] : Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDark ? Colors.orange : const Color(0xFFFF7A1A),
                      width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            TextField(
              controller: confirmPassword,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                prefixIcon: Icon(Icons.lock_outline,
                    color: isDark ? Colors.orange : const Color(0xFFFF7A1A)),
                filled: true,
                fillColor:
                    isDark ? Colors.grey[850] : Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDark ? Colors.orange : const Color(0xFFFF7A1A),
                      width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Signup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? Colors.orange : const Color(0xFFFF7A1A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Sign Up", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 15),

            // Redirect to Login
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: isDark ? Colors.orange : const Color(0xFFFF7A1A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError("Signup failed - please try again");
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = "Signup failed";
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered";
          break;
        case 'invalid-email':
          errorMessage = "Please enter a valid email address";
          break;
        case 'operation-not-allowed':
          errorMessage = "Email/password accounts are not enabled";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak";
          break;
        default:
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
