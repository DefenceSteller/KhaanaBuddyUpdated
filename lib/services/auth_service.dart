
// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      print('📝 AuthService: Creating user with email: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Add delay to ensure user is fully created
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('✅ AuthService: User created successfully: ${result.user?.email}');
      return result.user;
    } catch (e) {
      print('❌ AuthService: Signup error: $e');
      
      // If it's the specific pigeon error, still return success since user was created
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
        print('⚠️ Pigeon error detected, but user was likely created successfully');
        // Try to get the current user
        await Future.delayed(const Duration(seconds: 1));
        return _auth.currentUser;
      }
      
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      print('🔐 AuthService: Signing in user: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Add delay to ensure auth state is updated
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('✅ AuthService: User signed in successfully: ${result.user?.email}');
      return result.user;
    } catch (e) {
      print('❌ AuthService: Login error: $e');
      
      // If it's the specific pigeon error, still return success since login worked
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
        print('⚠️ Pigeon error detected, but login was likely successful');
        // Try to get the current user
        await Future.delayed(const Duration(seconds: 1));
        return _auth.currentUser;
      }
      
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }


  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}