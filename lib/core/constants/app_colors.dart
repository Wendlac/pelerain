import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary brand (violet — interactive elements only) ──
  static const Color primary      = Color(0xFF761CEA);
  static const Color primaryLight = Color(0xFF9B5CF6);
  static const Color primaryDark  = Color(0xFF5B0FB0);
  /// Soft lavender — ONLY use for tinting clickable elements (buttons, chips, tabs)
  static const Color primarySurface = Color(0xFFF4EBFF);

  // ── Secondary brand (cyan) ──
  static const Color secondary        = Color(0xFF2BD9FE);
  static const Color secondaryLight   = Color(0xFF7FEAFF);
  static const Color secondaryDark    = Color(0xFF00AACC);
  static const Color secondarySurface = Color(0xFFE6FAFF);

  // ── Backgrounds & surfaces (neutral — no purple tint) ──
  static const Color background        = Color(0xFFF8F8F8);
  static const Color surface           = Color(0xFFFFFFFF);
  static const Color surfaceElevated   = Color(0xFFF3F3F3);
  static const Color surfaceNeutral    = Color(0xFFF0F0F0); // icon bg, non-clickable rows

  // ── Semantic ──
  static const Color warning      = Color(0xFFFFE45E);
  static const Color warningDark  = Color(0xFFD4A800);
  static const Color success      = Color(0xFF20BF55);
  static const Color successDark  = Color(0xFF16874A);
  static const Color error        = Color(0xFFDD1155);
  static const Color errorDark    = Color(0xFFA80D3E);

  // ── Content (text) ──
  static const Color content          = Color(0xFF131515);
  static const Color contentSecondary = Color(0xFF4A4A4A);
  static const Color contentTertiary  = Color(0xFF70746E);
  static const Color contentDisabled  = Color(0xFFB0B0B0);

  // ── Borders & dividers (neutral) ──
  static const Color divider    = Color(0xFFEEEEEE);
  static const Color border     = Color(0xFFE0E0E0);
  static const Color borderLight= Color(0xFFEEEEEE);

  // ── Shadows ──
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark  = Color(0xFFCCCCCC);

  // ── Reservation status ──
  static const Color pending   = Color(0xFFFFE45E);
  static const Color confirmed = Color(0xFF20BF55);
  static const Color cancelled = Color(0xFFDD1155);
  static const Color expired   = Color(0xFF70746E);
}
