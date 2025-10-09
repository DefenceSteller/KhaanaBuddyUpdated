import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
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
              "Welcome Back 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 30),

            // Email Input
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

            // Password Input
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
            const SizedBox(height: 30),

            // Login Button

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
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
                    : const Text("Login", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 15),

            // Signup Redirect
            Center(
              child: TextButton(

                onPressed: _isLoading ? null : () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text(
                  "Don't have an account? Sign up",
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


 Future<void> _login() async {
  // Basic validation
  if (email.text.isEmpty || password.text.isEmpty) {
    _showError("Please fill all fields");
    return;
  }

  if (!email.text.contains('@')) {
    _showError("Please enter a valid email address");
    return;
  }

  setState(() {
    _isLoading = true;
  });

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
      
      // Use the navigation method that worked
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showError("Login failed - please try again");
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    
    String errorMessage = "Login failed";
    switch (e.code) {
      case 'user-not-found':
        errorMessage = "No user found with this email";
        break;
      case 'wrong-password':
        errorMessage = "Incorrect password";
        break;
      case 'invalid-email':
        errorMessage = "Please enter a valid email address";
        break;
      case 'user-disabled':
        errorMessage = "This account has been disabled";
        break;
      case 'too-many-requests':
        errorMessage = "Too many attempts. Try again later";
        break;
      default:
        errorMessage = "Login failed: ${e.message}";
    }
    
    _showError(errorMessage);
  } catch (e) {
    if (!mounted) return;
    
    // Handle Pigeon error
    if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
      await Future.delayed(const Duration(seconds: 1));
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && currentUser.email == email.text.trim()) {
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
        return;
      } else {
        _showError("Login failed - please try again");
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