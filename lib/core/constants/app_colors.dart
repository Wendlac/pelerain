import 'package:flutter/material.dart';

/// Pelerain MVP palette.
///
/// Source of truth: Pelerain_MVP_Specs.md §6.
///
/// - Primary (yellow Pelerain): CTAs, accents.
/// - Content (deep brown): all text (including text on yellow buttons).
/// - Borders/tags (soft yellow): chip outlines, secondary surfaces.
/// - Background (cream): global app background.
///
/// The `content`-on-`primary` pairing matches the spec ("texte `#1D1700` sur
/// fond `#FFDA44`") — high contrast with a warm, local feel.
class AppColors {
  AppColors._();

  // ── Primary brand (yellow Pelerain) ──
  static const Color primary        = Color(0xFFFFDA44);
  /// Slightly stronger yellow for hover / pressed states.
  static const Color primaryDark    = Color(0xFFE9C300);
  /// Soft yellow tint — for hover backgrounds, lightly-tinted surfaces,
  /// inactive chip borders.
  static const Color primarySurface = Color(0xFFFFF6CC);

  /// Backwards-compatible alias for screens that referenced
  /// `AppColors.primaryLight`. Maps to the same soft yellow as primarySurface.
  static const Color primaryLight   = Color(0xFFFFE88C);

  // ── Borders & tags (soft yellow) ──
  /// Border colour for filter tags, chip outlines, dividers within yellow
  /// surfaces.
  static const Color tagBorder = Color(0xFFFFE88C);

  // ── Secondary brand (cyan) — kept for WhatsApp-style accents ──
  static const Color secondary        = Color(0xFF2BD9FE);
  static const Color secondaryLight   = Color(0xFF7FEAFF);
  static const Color secondaryDark    = Color(0xFF00AACC);
  static const Color secondarySurface = Color(0xFFE6FAFF);

  // ── Backgrounds & surfaces ──
  /// Global background used on every screen except the splash. Slightly
  /// lighter than the splash bg so the cards/CTAs pop a bit more.
  static const Color background        = Color(0xFFFFFDFA);
  /// Warmer cream reserved for the splash so the brand intro feels rich.
  static const Color splashBackground  = Color(0xFFFFFBE6);
  /// Card / sheet background. Pure white pops nicely on the cream bg.
  static const Color surface         = Color(0xFFFFFFFF);
  /// Slightly elevated surface for sections inside cards.
  static const Color surfaceElevated = Color(0xFFFFF6CC);
  /// Non-clickable icon backgrounds, neutral fills.
  static const Color surfaceNeutral  = Color(0xFFFFF6CC);

  // ── Semantic ──
  static const Color warning      = Color(0xFFFF9F1C);
  static const Color warningDark  = Color(0xFFB36500);
  static const Color success      = Color(0xFF20BF55);
  static const Color successDark  = Color(0xFF16874A);
  static const Color error        = Color(0xFFDD1155);
  static const Color errorDark    = Color(0xFFA80D3E);

  // ── Content (text) — deep brown family ──
  static const Color content          = Color(0xFF1D1700);
  static const Color contentSecondary = Color(0xFF4A3F1F);
  static const Color contentTertiary  = Color(0xFF8A7E4F);
  static const Color contentDisabled  = Color(0xFFC9C1A3);

  // ── Borders & dividers ──
  static const Color divider     = Color(0xFFFFE88C);
  static const Color border      = Color(0xFFFFE88C);
  static const Color borderLight = Color(0xFFFFF1B8);

  // ── Shadows ──
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark  = Color(0xFFE6CB73);
}
