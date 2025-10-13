
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart'; // Import app.dart instead of login_screen.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 APP STARTING...');

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase error: $e');
  }


  runApp(const MyApp()); // This MyApp comes from app.dart
}
