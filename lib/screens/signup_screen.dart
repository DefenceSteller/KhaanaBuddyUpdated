import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Account ✨",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 30),

            // Email Field
            TextField(
              controller: email,

              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email, color: Colors.orange),
                filled: true,
                fillColor: Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                filled: true,
                fillColor: Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Confirm Password Field
            TextField(
              controller: confirmPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
                filled: true,
                fillColor: Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
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
                  backgroundColor: Colors.orange,
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
                onPressed: _isLoading ? null : () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Colors.orange,
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
    // Basic validation

    if (email.text.isEmpty || password.text.isEmpty || confirmPassword.text.isEmpty) {
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
        print('➡️ Navigating to home screen...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Use named route for navigation
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('❌ Signup failed: User is null');
        _showError("Signup failed - please try again");
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
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
      print('❌ Unexpected error: $e');
      
      // SPECIAL HANDLING FOR PIGEON ERROR - ADDED THIS BLOCK
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
        print('⚠️ Pigeon error detected, checking if user was created anyway...');
        
        // Check if user was actually created despite the error
        await Future.delayed(const Duration(seconds: 1));
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null && currentUser.email == email.text.trim()) {
          print('✅ User was created successfully despite pigeon error!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Signup successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          print('❌ User creation actually failed');
          _showError("Signup failed - please try again");
        }
      } else {
        _showError("An unexpected error occurred: $e");
      }
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