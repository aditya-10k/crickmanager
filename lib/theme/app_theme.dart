import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CricManager App Theme — Black Primary + Neon Pink Secondary
class AppTheme {
  // ── Core Palette ──────────────────────────────────────────────
  static const Color background    = Color(0xFF000000);
  static const Color surface       = Color(0xFF0D0D0D);
  static const Color surfaceCard   = Color(0xFF111111);
  static const Color surfaceBorder = Color(0xFF222222);

  static const Color neonPink      = Color(0xFFFF2D78);  // Primary accent
  static const Color neonPinkGlow  = Color(0x55FF2D78);  // Glow
  static const Color neonPinkDim   = Color(0x22FF2D78);  // Subtle fill

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted     = Color(0xFF4B5563);

  // ── Role / Status Colours ────────────────────────────────────
  static const Color batColor   = Color(0xFF34D399); // emerald
  static const Color bowlColor  = Color(0xFF60A5FA); // blue
  static const Color arColor    = Color(0xFFA78BFA); // violet
  static const Color wkColor    = Color(0xFFFBBF24); // amber
  static const Color errorColor = Color(0xFFF87171);
  static const Color gold       = Color(0xFFFFD700);

  // ── Shadows / Glows ──────────────────────────────────────────
  static List<BoxShadow> pinkGlow = [
    BoxShadow(color: neonPinkGlow, blurRadius: 20, spreadRadius: 0),
    BoxShadow(color: neonPinkGlow.withOpacity(0.3), blurRadius: 50, spreadRadius: -10),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF2D78), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D0D0D), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF000000), Color(0xFF0A0005)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Border Decorations ───────────────────────────────────────
  static BoxDecoration cardDecoration({bool highlighted = false}) => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: highlighted ? neonPink.withOpacity(0.5) : surfaceBorder,
      width: highlighted ? 1.5 : 1.0,
    ),
    boxShadow: highlighted ? pinkGlow : cardShadow,
  );

  static BoxDecoration glassDecoration() => BoxDecoration(
    color: const Color(0x18FFFFFF),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0x22FFFFFF), width: 1.0),
    boxShadow: cardShadow,
  );

  // ── Text Styles ──────────────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 36, fontWeight: FontWeight.w900, color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle headingMedium = GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary,
  );

  static TextStyle headingSmall = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.2,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13, color: textSecondary, height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 11, color: textMuted,
  );

  static TextStyle neonStat = GoogleFonts.outfit(
    fontSize: 28, fontWeight: FontWeight.w900, color: neonPink,
  );

  // ── Input Decoration ────────────────────────────────────────
  static InputDecoration inputDecoration({required String hint, Widget? prefix}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
    prefixIcon: prefix,
    filled: true,
    fillColor: const Color(0xFF0D0D0D),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF222222)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF222222)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: neonPink, width: 1.5),
    ),
  );

  // ── Button Styles ────────────────────────────────────────────
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: neonPink,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: neonPink,
    side: const BorderSide(color: neonPink, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
