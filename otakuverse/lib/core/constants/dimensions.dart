// lib/core/constants/dimensions.dart

/// Système d'espacement basé sur 8px
/// Garantit cohérence et harmonie visuelle
class AppDimensions {
  // ============================================
  // SPACING (basé sur 8px)
  // ============================================
  
  /// XS - 4px (espacements minimaux)
  static const double spacingXS = 4.0;
  
  /// S - 8px (espacements internes légers)
  static const double spacingS = 8.0;
  
  /// M - 16px (espacement standard)
  static const double spacingM = 16.0;
  
  /// L - 24px (sections, groupes d'éléments)
  static const double spacingL = 24.0;
  
  /// XL - 32px (grandes sections)
  static const double spacingXL = 32.0;
  
  /// 2XL - 48px (espacement entre blocs principaux)
  static const double spacing2XL = 48.0;
  
  /// 3XL - 64px (espacement header/footer)
  static const double spacing3XL = 64.0;
  
  // ============================================
  // PADDING
  // ============================================
  
  /// Padding minimal
  static const double paddingXS = spacingXS;
  
  /// Padding petit
  static const double paddingS = spacingS;
  
  /// Padding standard
  static const double paddingM = spacingM;
  
  /// Padding large
  static const double paddingL = spacingL;
  
  /// Padding extra large
  static const double paddingXL = spacingXL;
  
  /// Padding de page (horizontal)
  static const double pagePadding = spacingM;
  
  /// Padding de card
  static const double cardPadding = spacingM;
  
  // ============================================
  // MARGIN
  // ============================================
  
  /// Margin minimal
  static const double marginXS = spacingXS;
  
  /// Margin petit
  static const double marginS = spacingS;
  
  /// Margin standard
  static const double marginM = spacingM;
  
  /// Margin large
  static const double marginL = spacingL;
  
  /// Margin extra large
  static const double marginXL = spacingXL;
  
  // ============================================
  // BORDER RADIUS
  // ============================================
  
  /// Radius minimal (4px)
  static const double radiusXS = 4.0;
  
  /// Radius petit (8px)
  static const double radiusS = 8.0;
  
  /// Radius standard (12px)
  static const double radiusM = 12.0;
  
  /// Radius large (16px)
  static const double radiusL = 16.0;
  
  /// Radius extra large (24px)
  static const double radiusXL = 24.0;
  
  /// Radius circulaire (999px)
  static const double radiusCircular = 999.0;
  
  // ============================================
  // ICON SIZES
  // ============================================
  
  /// Icône extra small (16px)
  static const double iconXS = 16.0;
  
  /// Icône small (20px)
  static const double iconS = 20.0;
  
  /// Icône medium (24px)
  static const double iconM = 24.0;
  
  /// Icône large (32px)
  static const double iconL = 32.0;
  
  /// Icône extra large (48px)
  static const double iconXL = 48.0;
  
  // ============================================
  // AVATAR SIZES
  // ============================================
  
  /// Avatar extra small (24px)
  static const double avatarXS = 24.0;
  
  /// Avatar small (32px)
  static const double avatarS = 32.0;
  
  /// Avatar medium (40px)
  static const double avatarM = 40.0;
  
  /// Avatar large (56px)
  static const double avatarL = 56.0;
  
  /// Avatar extra large (80px)
  static const double avatarXL = 80.0;
  
  /// Avatar 2XL (120px) - pour profil
  static const double avatar2XL = 120.0;
  
  // ============================================
  // BUTTON SIZES
  // ============================================
  
  /// Hauteur bouton small (32px)
  static const double buttonHeightS = 32.0;
  
  /// Hauteur bouton medium (40px)
  static const double buttonHeightM = 40.0;
  
  /// Hauteur bouton large (48px)
  static const double buttonHeightL = 48.0;
  
  /// Hauteur bouton extra large (56px)
  static const double buttonHeightXL = 56.0;
  
  /// Padding horizontal bouton
  static const double buttonPaddingH = 24.0;
  
  /// Padding vertical bouton
  static const double buttonPaddingV = 12.0;
  
  // ============================================
  // INPUT FIELD SIZES
  // ============================================
  
  /// Hauteur input field standard (48px)
  static const double inputHeight = 48.0;
  
  /// Hauteur input field small (40px)
  static const double inputHeightS = 40.0;
  
  /// Padding horizontal input
  static const double inputPaddingH = 16.0;
  
  /// Padding vertical input
  static const double inputPaddingV = 12.0;
  
  // ============================================
  // APP BAR
  // ============================================
  
  /// Hauteur AppBar (64px)
  static const double appBarHeight = 64.0;
  
  /// Hauteur AppBar small (56px)
  static const double appBarHeightS = 56.0;
  
  // ============================================
  // BOTTOM NAV BAR
  // ============================================
  
  /// Hauteur BottomNavBar (64px + safe area)
  static const double bottomNavHeight = 64.0;
  
  /// Taille icône nav (28px)
  static const double navIconSize = 28.0;
  
  // ============================================
  // CARD SIZES
  // ============================================
  
  /// Hauteur card small (80px)
  static const double cardHeightS = 80.0;
  
  /// Hauteur card medium (120px)
  static const double cardHeightM = 120.0;
  
  /// Hauteur card large (160px)
  static const double cardHeightL = 160.0;
  
  /// Élévation card (2.0)
  static const double cardElevation = 2.0;
  
  /// Élévation card hover (8.0)
  static const double cardElevationHover = 8.0;
  
  // ============================================
  // POST DIMENSIONS
  // ============================================
  
  /// Largeur max post (600px)
  static const double postMaxWidth = 600.0;
  
  /// Ratio post Instagram (1:1)
  static const double postAspectRatio = 1.0;
  
  /// Hauteur max image post (400px)
  static const double postImageMaxHeight = 400.0;
  
  // ============================================
  // SHORT/VIDEO DIMENSIONS
  // ============================================
  
  /// Ratio short TikTok (9:16)
  static const double shortAspectRatio = 9 / 16;
  
  /// Hauteur thumbnail short (200px)
  static const double shortThumbnailHeight = 200.0;
  
  // ============================================
  // DIVIDER
  // ============================================
  
  /// Épaisseur divider (1px)
  static const double dividerThickness = 1.0;
  
  /// Indent divider (16px)
  static const double dividerIndent = spacingM;
  
  // ============================================
  // BORDER WIDTH
  // ============================================
  
  /// Bordure fine (1px)
  static const double borderThin = 1.0;
  
  /// Bordure medium (2px)
  static const double borderMedium = 2.0;
  
  /// Bordure épaisse (3px)
  static const double borderThick = 3.0;
  
  // ============================================
  // SHADOW / ELEVATION
  // ============================================
  
  /// Blur radius shadow small (4px)
  static const double shadowBlurS = 4.0;
  
  /// Blur radius shadow medium (8px)
  static const double shadowBlurM = 8.0;
  
  /// Blur radius shadow large (16px)
  static const double shadowBlurL = 16.0;
  
  /// Offset shadow (2px)
  static const double shadowOffset = 2.0;
  
  // ============================================
  // TOUCH TARGETS (minimum 44x44 iOS, 48x48 Android)
  // ============================================
  
  /// Touch target minimum (44px)
  static const double touchTarget = 44.0;
  
  /// Touch target large (48px)
  static const double touchTargetL = 48.0;
  
  // ============================================
  // BADGE
  // ============================================
  
  /// Taille badge (18px)
  static const double badgeSize = 18.0;
  
  /// Taille badge small (14px)
  static const double badgeSizeS = 14.0;
  
  // ============================================
  // LOADING INDICATOR
  // ============================================
  
  /// Taille loading indicator small (20px)
  static const double loadingIndicatorS = 20.0;
  
  /// Taille loading indicator medium (32px)
  static const double loadingIndicatorM = 32.0;
  
  /// Taille loading indicator large (48px)
  static const double loadingIndicatorL = 48.0;
  
  // ============================================
  // DIALOG
  // ============================================
  
  /// Largeur dialog small (280px)
  static const double dialogWidthS = 280.0;
  
  /// Largeur dialog medium (360px)
  static const double dialogWidthM = 360.0;
  
  /// Largeur dialog large (480px)
  static const double dialogWidthL = 480.0;
  
  /// Border radius dialog
  static const double dialogRadius = radiusL;
  
  // ============================================
  // BOTTOM SHEET
  // ============================================
  
  /// Border radius top bottom sheet
  static const double bottomSheetRadius = radiusXL;
  
  /// Handle width bottom sheet (40px)
  static const double bottomSheetHandleWidth = 40.0;
  
  /// Handle height bottom sheet (4px)
  static const double bottomSheetHandleHeight = 4.0;
  
  // ============================================
  // GRID
  // ============================================
  
  /// Nombre de colonnes grid mobile
  static const int gridColumnsM = 2;
  
  /// Nombre de colonnes grid tablet
  static const int gridColumnsT = 3;
  
  /// Espacement grid
  static const double gridSpacing = spacingS;
  
  // ============================================
  // BREAKPOINTS (responsive)
  // ============================================
  
  /// Mobile max width (600px)
  static const double mobileBreakpoint = 600.0;
  
  /// Tablet max width (900px)
  static const double tabletBreakpoint = 900.0;
  
  /// Desktop min width (900px)
  static const double desktopBreakpoint = 900.0;
}
