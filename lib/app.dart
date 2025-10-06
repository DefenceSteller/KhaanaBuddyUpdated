import 'package:flutter/material.dart';
import 'package:khaanabuddy/screens/home_screen.dart';
import 'package:khaanabuddy/screens/recipe_detail.dart';
import 'package:khaanabuddy/screens/history_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'themes/theme.dart';

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

      // 🟠 Theme setup
      theme: lightTheme.copyWith(
        primaryColor: Colors.orange,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // 🏁 Starting page
      initialRoute: '/home',

      // 🧭 All routes
      routes: {
        '/home': (context) => HomeScreen(),
        '/recipe': (context) => const RecipeDetail(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
