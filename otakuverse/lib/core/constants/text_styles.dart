// lib/core/constants/text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Système de typographie Otakuverse
/// Police principale : Inter (textes courants)
/// Police secondaire : Poppins (titres et headers)
class AppTextStyles {
  // ============================================
  // HEADINGS (Poppins)
  // ============================================
  
  /// H1 - Titres principaux (32px / 2rem)
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    height: 1.25, // Line height 40px
    letterSpacing: 0.5,
  );
  
  /// H2 - Sous-titres (24px / 1.5rem)
  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semi-Bold
    height: 1.33, // Line height 32px
    letterSpacing: 0.25,
  );
  
  /// H3 - Sections (20px / 1.25rem)
  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semi-Bold
    height: 1.4, // Line height 28px
    letterSpacing: 0.15,
  );
  
  /// H4 - Sous-sections (18px / 1.125rem)
  static TextStyle h4 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44, // Line height 26px
  );
  
  // ============================================
  // BODY TEXT (Inter)
  // ============================================
  
  /// Body Large - Texte principal large (16px / 1rem)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5, // Line height 24px
  );
  
  /// Body - Texte standard (14px / 0.875rem)
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43, // Line height 20px
    color: AppColors.infoBlue
  );
  
  /// Body Small - Texte secondaire (12px / 0.75rem)
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33, // Line height 16px
  );
  
  /// Caption - Légendes (10px / 0.625rem)
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4, // Line height 14px
  );
  
  // ============================================
  // VARIANTS - BOLD
  // ============================================
  
  /// Body Large Bold
  static TextStyle bodyLargeBold = bodyLarge.copyWith(
    fontWeight: FontWeight.w700,
  );
  
  /// Body Bold
  static TextStyle bodyBold = body.copyWith(
    fontWeight: FontWeight.w700,
  );
  
  /// Body Small Bold
  static TextStyle bodySmallBold = bodySmall.copyWith(
    fontWeight: FontWeight.w700,
  );
  
  // ============================================
  // VARIANTS - MEDIUM
  // ============================================
  
  /// Body Medium
  static TextStyle bodyMedium = body.copyWith(
    fontWeight: FontWeight.w500,
  );
  
  /// Body Small Medium
  static TextStyle bodySmallMedium = bodySmall.copyWith(
    fontWeight: FontWeight.w500,
  );
  
  // ============================================
  // SPECIAL STYLES
  // ============================================
  
  /// Button Text (14px, Semi-Bold)
  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  /// Link Text (14px, Medium, Underline)
  static TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.underline,
    color: AppColors.infoBlue,
  );
  
  /// Username (@mention style)
  static TextStyle username = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.crimsonRed,
  );
  
  /// Hashtag (#tag style)
  static TextStyle hashtag = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.infoBlue,
  );
  
  /// Overline (étiquettes, labels)
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
  );
  
  // ============================================
  // APP BAR
  // ============================================
  
  /// AppBar Title
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    color: AppColors.crimsonRed
  );
  
  // ============================================
  // BOTTOM NAV BAR
  // ============================================
  
  /// Bottom Nav Label (10px)
  static TextStyle navLabel = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
  
  // ============================================
  // FORMS
  // ============================================
  
  /// Input Label
  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );
  
  /// Input Text
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.pureWhite
  );
  
  /// Input Hint
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
  );
  
  /// Error Text
  static TextStyle errorText = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.errorRed,
  );
  
  // ============================================
  // STATS (likes, comments, etc.)
  // ============================================
  
  /// Stat Number (gros chiffres)
  static TextStyle statNumber = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  
  /// Stat Label (petits labels)
  static TextStyle statLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
  );
  
  // ============================================
  // TIME STAMPS
  // ============================================
  
  /// Timestamp (il y a 2h, etc.)
  static TextStyle timestamp = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
  );
  
  // ============================================
  // BADGES
  // ============================================
  
  /// Badge Text (notifications, compteurs)
  static TextStyle badge = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.pureWhite,
  );
  
  // ============================================
  // DIALOG
  // ============================================
  
  /// Dialog Title
  static TextStyle dialogTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  /// Dialog Content
  static TextStyle dialogContent = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // ============================================
  // SNACKBAR / TOAST
  // ============================================
  
  /// Snackbar Text
  static TextStyle snackbar = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.pureWhite,
  );
  
  // ============================================
  // THEMED VARIANTS
  // ============================================
  
  /// Obtenir un style avec une couleur spécifique
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  /// Obtenir un style avec une taille spécifique
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
  
  /// Obtenir un style avec un poids spécifique
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}

/// Extension pour faciliter l'utilisation
extension TextStyleExtension on TextStyle {
  /// Appliquer la couleur primaire
  TextStyle get primary => copyWith(color: AppColors.crimsonRed);
  
  /// Appliquer la couleur secondaire
  TextStyle get secondary => copyWith(color: AppColors.deepBlack);
  
  /// Appliquer la couleur de texte désactivé
  TextStyle get disabled => copyWith(color: AppColors.mediumGray);
  
  /// Appliquer la couleur d'erreur
  TextStyle get error => copyWith(color: AppColors.errorRed);
  
  /// Appliquer la couleur de succès
  TextStyle get success => copyWith(color: AppColors.successGreen);
  
  /// Appliquer le gras
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  
  /// Appliquer le semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  
  /// Appliquer l'italique
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
}
