import 'package:flutter/material.dart';
import 'package:khaanabuddy/screens/home_screen.dart';
import 'package:khaanabuddy/screens/profile_screen.dart';
import 'package:khaanabuddy/screens/recipe_detail.dart';
import 'package:khaanabuddy/screens/history_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'themes/theme.dart';
import 'package:khaanabuddy/screens/login_screen.dart';
import 'package:khaanabuddy/screens/signup_screen.dart';
import 'package:khaanabuddy/screens/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'KhaanaBuddy',
      debugShowCheckedModeBanner: false,

      // ✅ White & orange design system from theme.dart
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ✅ Start with Splash Screen
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },

      // ✅ Handle Recipe Detail dynamically
      onGenerateRoute: (settings) {
        if (settings.name == '/recipe') {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (context) => RecipeDetail(
              ingredients: args?['ingredients'] ?? '',
              cuisine: args?['cuisine'] ?? '',
            ),
          );
        }

        // fallback page
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('404: Page Not Found')),
          ),
        );
      },
    );
  }
}
