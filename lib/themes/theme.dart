import 'package:flutter/material.dart';

/// 🎨 KhaanaBuddy Design System — White & Orange
/// Central colors, gradients, shadows and Material themes.
class AppColors {
  AppColors._();

  // Brand
  static const Color orange = Color(0xFFFF7A1A);
  static const Color orangeDeep = Color(0xFFFF5A00);
  static const Color orangeSoft = Color(0xFFFFA64D);
  static const Color tint = Color(0xFFFFF1E6); // soft orange wash

  // Light palette
  static const Color bg = Color(0xFFFFFAF7); // warm white
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF231C15); // headings
  static const Color body = Color(0xFF4B423A); // body text
  static const Color muted = Color(0xFF94897C); // secondary text
  static const Color border = Color(0xFFFFE3CE); // hairline borders

  // Dark palette
  static const Color darkBg = Color(0xFF131110);
  static const Color darkSurface = Color(0xFF1F1B18);
  static const Color darkTint = Color(0xFF2A241F);
  static const Color darkBorder = Color(0xFF3A322B);
  static const Color darkInk = Colors.white;
  static const Color darkBody = Color(0xFFD8D2CB);
  static const Color darkMuted = Color(0xFF9C948B);

  /// Signature diagonal orange gradient.
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6A00), Color(0xFFFFA13B)],
  );

  /// Soft orange glow for hero elements.
  static const BoxShadow glow = BoxShadow(
    color: Color(0x4DFF7A1A),
    blurRadius: 22,
    offset: Offset(0, 10),
  );

  /// Subtle card shadow.
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x14FF7A1A),
    blurRadius: 24,
    offset: Offset(0, 10),
  );

  /// Faint shadow for small inputs / tiles.
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0DFF7A1A),
    blurRadius: 16,
    offset: Offset(0, 6),
  );
}

TextTheme _buildTextTheme({
  required Color heading,
  required Color body,
  required Color muted,
}) {
  return TextTheme(
    displaySmall: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: heading,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: heading,
      letterSpacing: -0.3,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: heading,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: heading,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: heading,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: body),
    bodyMedium: TextStyle(fontSize: 14.5, height: 1.5, color: body),
    bodySmall: TextStyle(fontSize: 13, height: 1.4, color: muted),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: body,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: muted,
    ),
  );
}

/// ☀️ Light theme — clean white surfaces with warm orange accents.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: AppColors.orange,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.orange,
    brightness: Brightness.light,
    primary: AppColors.orange,
    secondary: AppColors.orangeSoft,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.bg,
  textTheme: _buildTextTheme(
    heading: AppColors.ink,
    body: AppColors.body,
    muted: AppColors.muted,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.ink,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
    labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
    prefixIconColor: AppColors.orange,
    suffixIconColor: AppColors.orange,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.orange,
      backgroundColor: AppColors.surface,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.orange,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Color(0xFF2A241F),
    contentTextStyle: TextStyle(color: Colors.white, fontSize: 14.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.orange,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.orange,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? Colors.white
            : Colors.grey.shade400),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.orange
            : Colors.grey.shade300),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
  ),
  iconTheme: const IconThemeData(color: AppColors.ink),
);

/// 🌙 Dark theme — cozy charcoal with the same orange energy.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.orange,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.orange,
    brightness: Brightness.dark,
    primary: AppColors.orange,
    secondary: AppColors.orangeSoft,
    surface: AppColors.darkSurface,
  ),
  scaffoldBackgroundColor: AppColors.darkBg,
  textTheme: _buildTextTheme(
    heading: AppColors.darkInk,
    body: AppColors.darkBody,
    muted: AppColors.darkMuted,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkInk,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.darkInk,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkTint,
    hintStyle: const TextStyle(color: AppColors.darkMuted, fontSize: 15),
    labelStyle: const TextStyle(color: AppColors.darkMuted, fontSize: 15),
    prefixIconColor: AppColors.orange,
    suffixIconColor: AppColors.orange,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.orange,
      backgroundColor: AppColors.darkSurface,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.orange,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.darkTint,
    contentTextStyle: TextStyle(color: Colors.white, fontSize: 14.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.orange,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.orange,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? Colors.white
            : Colors.grey.shade500),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.orange
            : Colors.grey.shade700),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
  ),
  iconTheme: const IconThemeData(color: AppColors.darkInk),
);
