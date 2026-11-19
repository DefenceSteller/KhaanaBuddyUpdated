import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _restore();
  }

  bool get isDarkMode => _isDarkMode;

  /// Restore saved preference on app start.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('darkMode');
      if (saved != null && saved != _isDarkMode) {
        _isDarkMode = saved;
        notifyListeners();
      }
    } catch (_) {
      // Ignore storage errors — default to light mode.
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _isDarkMode);
    } catch (_) {
      // Ignore storage errors.
    }
  }
}
