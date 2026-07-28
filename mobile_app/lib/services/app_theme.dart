import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global design system for Lumíne — Direction C (Deep Presence dark).
class AppTheme {
  // ═══════════════════════════════════════════════════════════
  // FOUNDATION COLORS — never change per emotion
  // ═══════════════════════════════════════════════════════════
  static const Color bgDeep       = Color(0xFF0F1214); // deep midnight base
  static const Color bgSlate      = Color(0xFF1A1D21); // card surface
  static const Color bgSlateHigh  = Color(0xFF22262B); // slightly lifted slate
  static const Color bgSlateGlow  = Color(0xFF2A2E36); // glow bleed color

  // ═══════════════════════════════════════════════════════════
  // TEXT
  // ═══════════════════════════════════════════════════════════
  static const Color textPrimary   = Color(0xFFF5F1EA); // warm off-white
  static const Color textSecondary = Color(0xFF8C8579); // warm stone
  static const Color textTertiary  = Color(0xFF5A554D); // dim
  static const Color borderSoft    = Color(0xFF2A2E33);

  // ═══════════════════════════════════════════════════════════
  // BRAND ACCENT — sacred gold, always constant
  // ═══════════════════════════════════════════════════════════
   // Champagne Gold (matches screenshot)
  // Sacred gold — glow-optimized (uses ARGB with alpha for natural bleed)
  static const Color goldCenter = Color(0xFFFFF8E5); // bright center — for text on gold, star core
  static const Color goldGlow   = Color(0x66F1D98A); // 40% alpha — for glows, halos, shadows
  static const Color goldHalo   = Color(0x22FFF3CF); // 13% alpha — for very soft outer bleed

  // Legacy aliases (so I don't have to rewrite all my code) — these point to the new colors
  static const Color goldSoft = goldCenter;
  static const Color goldMid  = Color(0xFFF1D98A); // solid version of goldGlow for buttons
  static const Color goldDeep = Color(0xFFC9A845); // solid darker for text on gold
// ═══════════════════════════════════════════════════════════
  // FONTS — Cormorant Garamond (display) + Manrope (body)
  // ═══════════════════════════════════════════════════════════
  static TextStyle display({
    double size = 34,
    Color? color,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = -0.5,
    double height = 1.2,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle body({
    double size = 15,
    Color? color,
    FontWeight weight = FontWeight.w300,
    double letterSpacing = 0.2,
    double height = 1.5,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  static TextStyle label({
    double size = 12,
    Color? color,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 1.8,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textSecondary,
        letterSpacing: letterSpacing,
      );

  /// Verse style — Literata, elegant readable serif for scripture
  static TextStyle verse({
    double size = 15,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double height = 1.6,
    FontStyle fontStyle = FontStyle.italic,
    double letterSpacing = 0.1,
  }) =>
      GoogleFonts.literata(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimary,
        height: height,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );
  // ═══════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════
  static const double spaceXS = 4;
  static const double spaceS  = 8;
  static const double spaceM  = 16;
  static const double spaceL  = 24;
  static const double spaceXL = 40;
  static const double spaceXXL = 60;

  // ═══════════════════════════════════════════════════════════
  // ANIMATION TIMINGS
  // ═══════════════════════════════════════════════════════════
  static const Duration fast       = Duration(milliseconds: 200);
  static const Duration standard   = Duration(milliseconds: 400);
  static const Duration slow       = Duration(milliseconds: 800);
  static const Duration transition = Duration(milliseconds: 1200);
  static const Duration ambient    = Duration(seconds: 20);

  // ═══════════════════════════════════════════════════════════
  // RADII
  // ═══════════════════════════════════════════════════════════
  static const double radiusS  = 12;
  static const double radiusM  = 20;
  static const double radiusL  = 28;
  static const double radiusXL = 40;
}