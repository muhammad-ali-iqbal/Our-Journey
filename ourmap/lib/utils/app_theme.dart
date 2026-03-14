import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── DESIGN TOKENS (from Stitch HTML) ───────────────────────────────────────
class AppColors {
  // Primary: orange from Stitch (#ec5b13)
  static const primary = Color(0xFFEC5B13);
  static const primaryLight = Color(0xFFFFF0E8);
  static const primaryDark = Color(0xFFCC4A0A);

  // Gold accent (#d4af37)
  static const gold = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFB8960B);
  static const goldGlow = Color(0x40D4AF37);

  // Backgrounds
  static const bgLight = Color(0xFFF8F6F6);
  static const bgDark = Color(0xFF0A1128);
  static const bgDarkSurface = Color(0xFF111827);

  // Text
  static const textDark = Color(0xFF1E1E1E);
  static const textMid = Color(0xFF64748B);
  static const textLight = Color(0xFFCBD5E1);
  static const textWhite = Color(0xFFF8FAFC);

  // Surfaces
  static const cardBg = Color(0xFF1E293B);
  static const divider = Color(0x1AEC5B13);
}

/// Returns a Playfair Display TextStyle merged with [extra].
TextStyle playfair({
  double fontSize = 16,
  FontStyle fontStyle = FontStyle.normal,
  FontWeight fontWeight = FontWeight.w400,
  Color color = AppColors.textDark,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.playfairDisplay(
    fontSize: fontSize,
    fontStyle: fontStyle,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.gold,
          surface: AppColors.bgLight,
        ),
        textTheme: GoogleFonts.publicSansTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgLight,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.primary.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 15,
            ),
          ),
        ),
      );
}
