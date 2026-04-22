import 'package:flutter/material.dart';

class SeniSafeTheme {
  static const Color pineGreen = Color(0xFF2D5A27);
  static const Color pineGreenDeep = Color(0xFF1F3E1B);
  static const Color warmApricot = Color(0xFFF9E4B7);
  static const Color mistWhite = Color(0xFFF5F5F5);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color quietText = Color(0xFF5E665B);
  static const Color warningOrange = Color(0xFFE98B2A);
  static const Color emergencyRed = Color(0xFFB63A2B);

  static const double largeRadius = 32.0;
  static const double sectionSpacing = 24.0;
  static const double interactiveMinHeight = 80.0;

  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: pineGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: pineGreen,
      secondary: warmApricot,
      surface: Colors.white,
      error: emergencyRed,
    );

    const TextTheme textTheme = TextTheme(
      displayMedium: TextStyle(
        fontSize: 40,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 28,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 20,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: quietText,
      ),
      labelLarge: TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: mistWhite,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: mistWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, interactiveMinHeight),
          backgroundColor: pineGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, interactiveMinHeight),
          foregroundColor: pineGreen,
          side: const BorderSide(color: pineGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 96,
        backgroundColor: Colors.white,
        indicatorColor: warmApricot,
        surfaceTintColor: Colors.transparent,
        iconTheme: const MaterialStatePropertyAll(
          IconThemeData(size: 30),
        ),
        labelTextStyle: MaterialStatePropertyAll(
          textTheme.labelMedium?.copyWith(color: pineGreen),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: pineGreenDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerColor: pineGreen.withOpacity(0.08),
    );
  }
}
