import 'package:flutter/material.dart';

class AppColors {

  // ─── FONDS ───────────────────────────────────────────────────────
  static const Color bgPrimary   = Color(0xFF0D0D14);
  static const Color bgSecondary = Color(0xFF13131F);
  static const Color bgCard      = Color(0xFF1A1A2E);
  static const Color bgElevated  = Color(0xFF212134);
  static const Color bgSheet     = Color(0xFF16162A);

  // ─── PRIMAIRE — Violet électrique ────────────────────────────────
  static const Color primary      = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7FF0);
  static const Color primaryDark  = Color(0xFF4A3DB8);

  // ─── ACCENT — Orange passion ──────────────────────────────────────
  static const Color accent      = Color(0xFFFF7043);
  static const Color accentLight = Color(0xFFFF8A65);
  static const Color accentDark  = Color(0xFFE64A19);

  // ─── SPÉCIAUX OTAKU ──────────────────────────────────────────────
  static const Color sakura   = Color(0xFFFF6B9D); // Romance, douceur
  static const Color gold     = Color(0xFFFFD700); // Rangs, trophées
  static const Color neonBlue = Color(0xFF00D4FF); // Online, live, tech
  static const Color jade     = Color(0xFF00C896); // Succès, nature

  // ─── TEXTES ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9B9BC0);
  static const Color textMuted     = Color(0xFF5C5C7A);
  static const Color textDisabled  = Color(0xFF3A3A55);

  // ─── ÉTATS ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB300);
  static const Color error   = Color(0xFFFF4757);
  static const Color info    = Color(0xFF00D4FF);

  // ─── BORDURES ────────────────────────────────────────────────────
  static const Color border        = Color(0xFF2A2A3E);
  static const Color borderLight   = Color(0xFF353550);
  static const Color borderFocus   = Color(0xFF6C5CE7);

  // ─── BLANC / NOIR ────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ─── RANGS — couleurs par niveau ─────────────────────────────────
  static const Color rankNovice  = Color(0xFF9B9BC0); // Gris
  static const Color rankOtaku   = Color(0xFF00D4FF); // Bleu neon
  static const Color rankSenpai  = Color(0xFF00C896); // Jade
  static const Color rankSensei  = Color(0xFF6C5CE7); // Primary
  static const Color rankMangaka = Color(0xFFFF7043); // Accent
  static const Color rankKami    = Color(0xFFFFD700); // Gold

  // ─── GRADIENTS ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );

  static const LinearGradient kamiGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF7043)],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [bgPrimary, bgSecondary],
    begin:  Alignment.topCenter,
    end:    Alignment.bottomCenter,
  );

  static LinearGradient overlayGradient = LinearGradient(
    colors: [
      Colors.transparent,
      bgPrimary.withValues(alpha: 0.85),
    ],
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
  );

  // ─── HELPER — couleur du rang ─────────────────────────────────────
  static Color rankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'kami':    return rankKami;
      case 'mangaka': return rankMangaka;
      case 'sensei':  return rankSensei;
      case 'senpai':  return rankSenpai;
      case 'otaku':   return rankOtaku;
      default:        return rankNovice;
    }
  }

  // ─── HELPER — couleur avec opacité ───────────────────────────────
  static Color primaryAlpha(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color accentAlpha(double opacity) =>
      accent.withValues(alpha: opacity);
  static Color whiteAlpha(double opacity) =>
      white.withValues(alpha: opacity);
}