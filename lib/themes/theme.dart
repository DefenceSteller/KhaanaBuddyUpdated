import 'package:flutter/material.dart';

/// 🌿 KhaanaBuddy Design System — "Botanical Kitchen"
/// Deep basil green + warm cream + saffron gold accent.
/// Headings: Fraunces (editorial serif) · Body: Inter.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF1E8A5A); // basil green
  static const Color brandDeep = Color(0xFF0F5F3E); // forest green
  static const Color brandSoft = Color(0xFF56C79A); // mint
  static const Color tint = Color(0xFFE8F4EC); // soft green wash

  // Accent (secondary highlights: AI sparkle, badges)
  static const Color accent = Color(0xFFF2A93B); // saffron gold
  static const Color accentDeep = Color(0xFFD98C1F);

  // Light palette
  static const Color bg = Color(0xFFFAF7F0); // warm cream
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF16231D); // headings
  static const Color body = Color(0xFF45534C); // body text
  static const Color muted = Color(0xFF8A968F); // secondary text
  static const Color border = Color(0xFFE2E7E1); // hairline borders

  // Dark palette
  static const Color darkBg = Color(0xFF0D1411);
  static const Color darkSurface = Color(0xFF151E1A);
  static const Color darkTint = Color(0xFF1D2B24);
  static const Color darkBorder = Color(0xFF2A3A32);
  static const Color darkInk = Color(0xFFF4F8F5);
  static const Color darkBody = Color(0xFFC3D0C9);
  static const Color darkMuted = Color(0xFF8B998F);

  /// Signature diagonal basil-green gradient.
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E6E45), Color(0xFF2BA872)],
  );

  /// Soft green glow for hero elements.
  static const BoxShadow glow = BoxShadow(
    color: Color(0x4D1E8A5A),
    blurRadius: 22,
    offset: Offset(0, 10),
  );

  /// Subtle card shadow.
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A0F5F3E),
    blurRadius: 24,
    offset: Offset(0, 10),
  );

  /// Faint shadow for small inputs / tiles.
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0D0F5F3E),
    blurRadius: 16,
    offset: Offset(0, 6),
  );
}

const String _display = 'Fraunces';
const String _ui = 'Inter';

// Variable-font weight mapping is set explicitly so headings keep their
// intended heft on every platform.
TextStyle _displayStyle({
  required double fontSize,
  required FontWeight weight,
  double opticalSize = 72,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: _display,
    fontSize: fontSize,
    fontWeight: weight,
    fontVariations: <FontVariation>[
      FontVariation('wght', weight.value.toDouble()),
      FontVariation('opsz', opticalSize),
    ],
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextStyle _uiStyle({
  required double fontSize,
  FontWeight weight = FontWeight.w400,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: _ui,
    fontSize: fontSize,
    fontWeight: weight,
    fontVariations: <FontVariation>[
      FontVariation('wght', weight.value.toDouble()),
    ],
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextTheme _buildTextTheme({
  required Color heading,
  required Color body,
  required Color muted,
}) {
  return TextTheme(
    displaySmall: _displayStyle(
      fontSize: 30,
      weight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
    ).copyWith(color: heading),
    headlineSmall: _displayStyle(
      fontSize: 24,
      weight: FontWeight.w800,
      letterSpacing: -0.3,
      height: 1.25,
    ).copyWith(color: heading),
    titleLarge: _displayStyle(
      fontSize: 20,
      weight: FontWeight.w700,
      opticalSize: 36,
    ).copyWith(color: heading),
    titleMedium: _uiStyle(
      fontSize: 17,
      weight: FontWeight.w700,
    ).copyWith(color: heading),
    titleSmall: _uiStyle(
      fontSize: 15,
      weight: FontWeight.w600,
    ).copyWith(color: heading),
    bodyLarge: _uiStyle(fontSize: 16, height: 1.55).copyWith(color: body),
    bodyMedium: _uiStyle(fontSize: 14.5, height: 1.5).copyWith(color: body),
    bodySmall: _uiStyle(fontSize: 13, height: 1.4).copyWith(color: muted),
    labelLarge: _uiStyle(fontSize: 16, weight: FontWeight.w700)
        .copyWith(color: body),
    labelMedium:
        _uiStyle(fontSize: 13, weight: FontWeight.w600).copyWith(color: muted),
  );
}

/// ☀️ Light theme — warm cream surfaces with basil-green accents.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: _ui,
  primaryColor: AppColors.brand,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
    primary: AppColors.brand,
    secondary: AppColors.accent,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.bg,
  textTheme: _buildTextTheme(
    heading: AppColors.ink,
    body: AppColors.body,
    muted: AppColors.muted,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.ink,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: _displayStyle(
      fontSize: 21,
      weight: FontWeight.w800,
      opticalSize: 36,
    ).copyWith(color: AppColors.ink),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
    labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
    prefixIconColor: AppColors.brand,
    suffixIconColor: AppColors.brand,
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
      borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      elevation: 0,
      textStyle: _uiStyle(fontSize: 16, weight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.brand,
      backgroundColor: AppColors.surface,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      textStyle: _uiStyle(fontSize: 16, weight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.brand,
      textStyle: _uiStyle(fontSize: 15, weight: FontWeight.w700),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF17241E),
    contentTextStyle: _uiStyle(fontSize: 14.5).copyWith(color: Colors.white),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.brand,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.brand,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? Colors.white
            : Colors.grey.shade400),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.brand
            : Colors.grey.shade300),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
  ),
  iconTheme: const IconThemeData(color: AppColors.ink),
);

/// 🌙 Dark theme — deep forest charcoal with the same basil energy.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: _ui,
  primaryColor: AppColors.brand,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.dark,
    primary: AppColors.brand,
    secondary: AppColors.accent,
    surface: AppColors.darkSurface,
  ),
  scaffoldBackgroundColor: AppColors.darkBg,
  textTheme: _buildTextTheme(
    heading: AppColors.darkInk,
    body: AppColors.darkBody,
    muted: AppColors.darkMuted,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkInk,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: _displayStyle(
      fontSize: 21,
      weight: FontWeight.w800,
      opticalSize: 36,
    ).copyWith(color: AppColors.darkInk),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkTint,
    hintStyle: const TextStyle(color: AppColors.darkMuted, fontSize: 15),
    labelStyle: const TextStyle(color: AppColors.darkMuted, fontSize: 15),
    prefixIconColor: AppColors.brandSoft,
    suffixIconColor: AppColors.brandSoft,
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
      borderSide: const BorderSide(color: AppColors.brandSoft, width: 1.6),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      elevation: 0,
      textStyle: _uiStyle(fontSize: 16, weight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.brandSoft,
      backgroundColor: AppColors.darkSurface,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      textStyle: _uiStyle(fontSize: 16, weight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.brandSoft,
      textStyle: _uiStyle(fontSize: 15, weight: FontWeight.w700),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.darkTint,
    contentTextStyle: _uiStyle(fontSize: 14.5).copyWith(color: Colors.white),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.brand,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.brandSoft,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? Colors.white
            : Colors.grey.shade500),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.brand
            : Colors.grey.shade700),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
  ),
  iconTheme: const IconThemeData(color: AppColors.darkInk),
);
