// lib/src/config/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NVColors {
  // Core backgrounds
  static const bgDeep = Color(0xFF0A0E1A);
  static const bgSurface = Color(0xFF111827);
  static const bgCard = Color(0xFF1A2235);
  static const bgCardHover = Color(0xFF1F2D45);

  // Borders
  static const border = Color(0xFF1E293B);
  static const borderBright = Color(0xFF334155);

  // Primary - Cyan/AI
  static const primary = Color(0xFF00D4FF);
  static const primaryDark = Color(0xFF0090B8);
  static const primaryGlow = Color(0x3300D4FF);

  // Secondary - Purple/Research
  static const secondary = Color(0xFF7C3AED);
  static const secondaryGlow = Color(0x337C3AED);

  // Accent - Health Green
  static const accent = Color(0xFF10B981);
  static const accentGlow = Color(0x3310B981);

  // Status colors
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF3B82F6);

  // Text
  static const textPrimary = Color(0xFFF9FAFB);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const textDisabled = Color(0xFF4B5563);

  // Role colors
  static const doctorColor = Color(0xFF00D4FF);
  static const radiologistColor = Color(0xFF7C3AED);
  static const researcherColor = Color(0xFF10B981);

  // Gradients
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0090B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSecondary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF4F1D96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientAccent = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF065F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientBackground = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0F172A), Color(0xFF0A0E1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class NVTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NVColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: NVColors.primary,
        secondary: NVColors.secondary,
        tertiary: NVColors.accent,
        surface: NVColors.bgSurface,
        error: NVColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: NVColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: NVColors.textPrimary, fontSize: 48, fontWeight: FontWeight.bold),
          displayMedium: const TextStyle(color: NVColors.textPrimary, fontSize: 36, fontWeight: FontWeight.bold),
          headlineLarge: const TextStyle(color: NVColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
          headlineMedium: const TextStyle(color: NVColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          headlineSmall: const TextStyle(color: NVColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(color: NVColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: NVColors.textPrimary, fontSize: 16),
          bodyMedium: const TextStyle(color: NVColors.textSecondary, fontSize: 14),
          bodySmall: const TextStyle(color: NVColors.textMuted, fontSize: 12),
          labelLarge: const TextStyle(color: NVColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NVColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: NVColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: NVColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NVColors.bgCard,
        hintStyle: const TextStyle(color: NVColors.textMuted),
        labelStyle: const TextStyle(color: NVColors.textSecondary),
        prefixIconColor: NVColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NVColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NVColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NVColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NVColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NVColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NVColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NVColors.primary,
          side: const BorderSide(color: NVColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: NVColors.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NVColors.border),
        ),
      ),
      dividerColor: NVColors.border,
      iconTheme: const IconThemeData(color: NVColors.textSecondary),
    );
  }
}