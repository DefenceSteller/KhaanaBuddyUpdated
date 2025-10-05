import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<User?> signUp(String email, String password) async {
    try {
      // 1. Create user with Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // 2. Save user details to Realtime Database
      if (result.user != null) {
        final userRef = _database.ref().child('users').child(result.user!.uid);
        await userRef.set({
          'email': email.trim(),
          'createdAt': ServerValue.timestamp,
          'uid': result.user!.uid,
        });
      }
      
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}