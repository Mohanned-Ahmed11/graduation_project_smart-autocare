import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF14181B),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.85)),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFECECEC),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: AppColors.cardDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.9)),
    );
  }
}
