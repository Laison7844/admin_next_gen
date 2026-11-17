import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final useFallback =
        AppTypography.useSystemFont || !AppTypography.hasBindings;
    final baseTextTheme = useFallback
        ? ThemeData.light().textTheme
        : GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryNavy,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        onPrimary: AppColors.surfaceWhite,
        primaryContainer: AppColors.lightNavy,
        secondary: AppColors.primaryGold,
        onSecondary: AppColors.primaryNavy,
        secondaryContainer: AppColors.softGoldBg,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textPrimary,
        error: AppColors.errorRed,
        onError: AppColors.surfaceWhite,
        outline: AppColors.borderLight,
        outlineVariant: AppColors.borderMedium,
      ),
      textTheme: useFallback
          ? baseTextTheme
          : baseTextTheme.copyWith(
              displaySmall: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
              headlineMedium: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
              headlineSmall: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
              titleLarge: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
              titleMedium: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
              bodyMedium: GoogleFonts.inter(color: AppColors.textSecondary),
              labelLarge: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        hintStyle: useFallback
            ? const TextStyle(fontSize: 14, color: AppColors.textMuted)
            : GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        labelStyle: useFallback
            ? const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              )
            : GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: AppColors.surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: useFallback
              ? const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                )
              : GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.borderMedium),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: useFallback
              ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
              : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
