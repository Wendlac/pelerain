import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _dm(double size, FontWeight weight, double lineHeight, double letterSpacing, [Color color = AppColors.content]) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Headings
  static TextStyle headingXL  = _dm(40, FontWeight.w700, 48, -1.2);
  static TextStyle headingL   = _dm(32, FontWeight.w700, 40, -1);
  static TextStyle headingM   = _dm(24, FontWeight.w700, 32, -0.8);
  static TextStyle headingS   = _dm(20, FontWeight.w700, 28, -0.6);
  static TextStyle headingXS  = _dm(16, FontWeight.w700, 24, -0.3);
  static TextStyle heading2XS = _dm(14, FontWeight.w700, 20, -0.2);

  /// Display headline used at the top of every search-related screen
  /// (home, search results, trip detail, company detail).
  /// Per design spec: Denk One, 40 px, letter-spacing −4 px, line-height 1.0.
  /// Always rendered uppercase by callers so the condensed display font
  /// keeps the same look across screens.
  static TextStyle pageHeadline = GoogleFonts.denkOne(
    fontSize: 40,
    fontWeight: FontWeight.w400, // Denk One ships in a single regular weight
    color: AppColors.content,
    letterSpacing: -4,
    height: 1.0,
  );

  // Body text (16-20px: less aggressive letter-spacing)
  static TextStyle textXLMedium = _dm(20, FontWeight.w500, 28, 0);
  static TextStyle textXLBold   = _dm(20, FontWeight.w700, 28, 0);
  static TextStyle textLMedium  = _dm(16, FontWeight.w500, 24, 0);
  static TextStyle textLBold    = _dm(16, FontWeight.w700, 24, 0);
  static TextStyle textMMedium  = _dm(14, FontWeight.w500, 20, -0.2);
  static TextStyle textMBold    = _dm(14, FontWeight.w700, 20, -0.2);
  static TextStyle textSMedium  = _dm(12, FontWeight.w500, 16, -0.2);
  static TextStyle textSBold    = _dm(12, FontWeight.w700, 16, -0.2);
  static TextStyle textXSMedium = _dm(10, FontWeight.w500, 14, -0.1);
  static TextStyle textXSBold   = _dm(10, FontWeight.w700, 14, -0.1);

  // Colored variants
  static TextStyle primaryLabel = _dm(14, FontWeight.w700, 20, -0.2, AppColors.primary);
  static TextStyle errorLabel   = _dm(14, FontWeight.w500, 20, -0.2, AppColors.error);
  static TextStyle mutedLabel   = _dm(14, FontWeight.w500, 20, -0.2, AppColors.contentTertiary);
}
