import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class AppTextStyles {

  // ─── DISPLAY — Bangers (impact, titres anime) ────────────────────
  static TextStyle display1 = GoogleFonts.bangers(
    fontSize:      48,
    color:         AppColors.textPrimary,
    letterSpacing: 2,
    height:        1.1,
  );

  static TextStyle display2 = GoogleFonts.bangers(
    fontSize:      36,
    color:         AppColors.textPrimary,
    letterSpacing: 1.5,
    height:        1.15,
  );

  static TextStyle display3 = GoogleFonts.bangers(
    fontSize:      28,
    color:         AppColors.textPrimary,
    letterSpacing: 1.2,
    height:        1.2,
  );

  // ─── HEADINGS — Nunito Bold ───────────────────────────────────────
  static TextStyle h1 = GoogleFonts.nunito(
    fontSize:      26,
    fontWeight:    FontWeight.w800,
    color:         AppColors.textPrimary,
    height:        1.25,
    letterSpacing: 0.3,
  );

  static TextStyle h2 = GoogleFonts.nunito(
    fontSize:      22,
    fontWeight:    FontWeight.w700,
    color:         AppColors.textPrimary,
    height:        1.3,
    letterSpacing: 0.2,
  );

  static TextStyle h3 = GoogleFonts.nunito(
    fontSize:      18,
    fontWeight:    FontWeight.w700,
    color:         AppColors.textPrimary,
    height:        1.35,
  );

  static TextStyle h4 = GoogleFonts.nunito(
    fontSize:      16,
    fontWeight:    FontWeight.w700,
    color:         AppColors.textPrimary,
    height:        1.4,
  );

  // ─── BODY — Nunito Regular ────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize:   16,
    fontWeight: FontWeight.w400,
    color:      AppColors.textPrimary,
    height:     1.55,
  );

  static TextStyle body = GoogleFonts.nunito(
    fontSize:   14,
    fontWeight: FontWeight.w400,
    color:      AppColors.textPrimary,
    height:     1.5,
  );

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize:   12,
    fontWeight: FontWeight.w400,
    color:      AppColors.textSecondary,
    height:     1.45,
  );

  static TextStyle bodySemiBold = GoogleFonts.nunito(
    fontSize:   14,
    fontWeight: FontWeight.w600,
    color:      AppColors.textPrimary,
    height:     1.5,
  );

  // ─── LABELS ───────────────────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.nunito(
    fontSize:      13,
    fontWeight:    FontWeight.w700,
    color:         AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle label = GoogleFonts.nunito(
    fontSize:      11,
    fontWeight:    FontWeight.w600,
    color:         AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static TextStyle labelUppercase = GoogleFonts.nunito(
    fontSize:      10,
    fontWeight:    FontWeight.w700,
    color:         AppColors.textSecondary,
    letterSpacing: 1.5,
  );

  // ─── CAPTIONS ─────────────────────────────────────────────────────
  static TextStyle caption = GoogleFonts.nunito(
    fontSize:   11,
    fontWeight: FontWeight.w400,
    color:      AppColors.textMuted,
    height:     1.4,
  );

  static TextStyle captionBold = GoogleFonts.nunito(
    fontSize:   11,
    fontWeight: FontWeight.w700,
    color:      AppColors.textMuted,
  );

  // ─── STATS — JetBrains Mono (chiffres, rangs) ────────────────────
  static TextStyle statLarge = GoogleFonts.jetBrainsMono(
    fontSize:   22,
    fontWeight: FontWeight.w700,
    color:      AppColors.textPrimary,
    height:     1.2,
  );

  static TextStyle stat = GoogleFonts.jetBrainsMono(
    fontSize:   16,
    fontWeight: FontWeight.w600,
    color:      AppColors.textPrimary,
  );

  static TextStyle statSmall = GoogleFonts.jetBrainsMono(
    fontSize:   12,
    fontWeight: FontWeight.w500,
    color:      AppColors.textSecondary,
  );

  static TextStyle level = GoogleFonts.jetBrainsMono(
    fontSize:      13,
    fontWeight:    FontWeight.w700,
    color:         AppColors.gold,
    letterSpacing: 0.5,
  );

  // ─── UI SPÉCIFIQUES ───────────────────────────────────────────────
  static TextStyle appBarTitle = GoogleFonts.bangers(
    fontSize:      24,
    color:         AppColors.primary,
    letterSpacing: 2,
  );

  static TextStyle navLabel = GoogleFonts.nunito(
    fontSize:   10,
    fontWeight: FontWeight.w700,
  );

  static TextStyle button = GoogleFonts.nunito(
    fontSize:      15,
    fontWeight:    FontWeight.w700,
    letterSpacing: 0.5,
    height:        1.0,
  );

  static TextStyle buttonSmall = GoogleFonts.nunito(
    fontSize:      13,
    fontWeight:    FontWeight.w700,
    letterSpacing: 0.3,
  );

  static TextStyle inputText = GoogleFonts.nunito(
    fontSize:   15,
    fontWeight: FontWeight.w400,
    color:      AppColors.textPrimary,
  );

  static TextStyle inputHint = GoogleFonts.nunito(
    fontSize:   15,
    fontWeight: FontWeight.w400,
    color:      AppColors.textMuted,
  );

  static TextStyle inputLabel = GoogleFonts.nunito(
    fontSize:   12,
    fontWeight: FontWeight.w600,
    color:      AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle badge = GoogleFonts.jetBrainsMono(
    fontSize:   10,
    fontWeight: FontWeight.w700,
    color:      AppColors.white,
    height:     1.4,
  );

  static TextStyle timestamp = GoogleFonts.nunito(
    fontSize:   11,
    fontWeight: FontWeight.w400,
    color:      AppColors.textMuted,
  );

  static TextStyle rank = GoogleFonts.nunito(
    fontSize:   12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );

  static TextStyle mention = GoogleFonts.nunito(
    fontSize:   14,
    fontWeight: FontWeight.w700,
    color:      AppColors.primary,
  );

  static TextStyle hashtag = GoogleFonts.nunito(
    fontSize:   14,
    fontWeight: FontWeight.w600,
    color:      AppColors.neonBlue,
  );

  static TextStyle link = GoogleFonts.nunito(
    fontSize:    14,
    fontWeight:  FontWeight.w600,
    color:       AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  // ─── HELPERS ─────────────────────────────────────────────────────
  static TextStyle withColor(TextStyle s, Color c) =>
      s.copyWith(color: c);

  static TextStyle withSize(TextStyle s, double size) =>
      s.copyWith(fontSize: size);
}

// ─── EXTENSIONS ──────────────────────────────────────────────────────
extension TextStyleX on TextStyle {
  TextStyle get primary   => copyWith(color: AppColors.primary);
  TextStyle get accent    => copyWith(color: AppColors.accent);
  TextStyle get muted     => copyWith(color: AppColors.textMuted);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get error     => copyWith(color: AppColors.error);
  TextStyle get success   => copyWith(color: AppColors.success);
  TextStyle get gold      => copyWith(color: AppColors.gold);
  TextStyle get sakura    => copyWith(color: AppColors.sakura);
  TextStyle get bold      => copyWith(fontWeight: FontWeight.w700);
  TextStyle get extraBold => copyWith(fontWeight: FontWeight.w800);
  TextStyle get semiBold  => copyWith(fontWeight: FontWeight.w600);
  TextStyle get italic    => copyWith(fontStyle: FontStyle.italic);
}