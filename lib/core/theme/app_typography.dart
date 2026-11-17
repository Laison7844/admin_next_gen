import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTypography {
  /// When true (e.g. during unit/widget testing), falls back to system font
  /// to avoid external HTTP font fetch failures in headless test runners.
  static bool useSystemFont = false;

  /// Helper to check whether Flutter bindings are initialized before invoking
  /// GoogleFonts which registers platform message listeners with SchedulerBinding.
  static bool get hasBindings {
    try {
      WidgetsBinding.instance;
      return true;
    } on FlutterError {
      return false;
    } on TypeError {
      return false;
    }
  }

  static TextStyle _font({
    required TextStyle Function() googleFont,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    if (useSystemFont || !hasBindings) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    return googleFont();
  }

  static TextStyle headingLarge({Color color = AppColors.primaryNavy}) {
    return _font(
      googleFont: () => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle headingMedium({Color color = AppColors.primaryNavy}) {
    return _font(
      googleFont: () => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
      ),
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.3,
    );
  }

  static TextStyle headingSmall({Color color = AppColors.primaryNavy}) {
    return _font(
      googleFont: () => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle titleMedium({Color color = AppColors.textPrimary}) {
    return _font(
      googleFont: () => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) {
    return _font(
      googleFont: () => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.textMuted}) {
    return _font(
      googleFont: () => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle buttonText({Color color = AppColors.surfaceWhite}) {
    return _font(
      googleFont: () => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.3,
    );
  }

  static TextStyle navItem({bool isActive = false}) {
    final color = isActive ? AppColors.surfaceWhite : const Color(0xFFB0BDD4);
    final weight = isActive ? FontWeight.w600 : FontWeight.w400;

    return _font(
      googleFont: () => GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: weight,
        color: color,
      ),
      fontSize: 13.5,
      fontWeight: weight,
      color: color,
    );
  }
}
