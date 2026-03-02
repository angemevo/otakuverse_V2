import 'package:flutter/material.dart';

/// Couleurs de la charte graphique Otakuverse
/// Rouge Crimson (#DC143C) + Noir profond (#0A0A0A)
class AppColors {
  // ============================================
  // COULEURS PRINCIPALES
  // ============================================
  
  /// Rouge Crimson - Couleur principale de la marque
  /// Utilisation : CTA, accents, éléments interactifs importants
  static const Color crimsonRed = Color(0xFFDC143C);
  
  /// Noir profond - Couleur secondaire
  /// Utilisation : Textes principaux, arrière-plans, éléments structurels
  static const Color deepBlack = Color(0xFF0A0A0A);
  
  // ============================================
  // COULEURS SECONDAIRES
  // ============================================
  
  /// Rouge clair - Pour hover states et éléments secondaires
  static const Color lightCrimson = Color(0xFFFF4D6D);
  
  /// Gris foncé - Arrière-plans alternatifs
  static const Color darkGray = Color(0xFF1A1A1A);
  
  /// Gris moyen - Textes secondaires, icônes inactives
  static const Color mediumGray = Color(0xFF4A4A4A);
  
  /// Gris clair - Arrière-plans clairs, séparateurs
  static const Color lightGray = Color(0xFFE5E5E5);
  
  // ============================================
  // COULEURS D'INTERFACE
  // ============================================
  
  /// Vert succès - Messages de succès, validations
  static const Color successGreen = Color(0xFF00C853);
  
  /// Orange avertissement - Alertes, avertissements
  static const Color warningOrange = Color(0xFFFFB300);
  
  /// Rouge erreur - Erreurs, actions destructives
  static const Color errorRed = Color(0xFFD32F2F);
  
  /// Bleu info - Informations, tips, liens externes
  static const Color infoBlue = Color(0xFF1976D2);
  
  /// Blanc pur - Arrière-plans clairs, textes sur fond sombre
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Maron - Bordure
  static const Color border = Color(0xFF2A2A2A); 
  
  // ============================================
  // GRADIENTS
  // ============================================
  
  /// Gradient principal (rouge vers rouge clair)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [crimsonRed, lightCrimson],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradient sombre (noir vers gris foncé)
  static const LinearGradient darkGradient = LinearGradient(
    colors: [deepBlack, darkGray],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Gradient overlay (transparent vers noir)
  static LinearGradient overlayGradient = LinearGradient(
    colors: [
      Colors.transparent,
      deepBlack.withOpacity(0.7),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // ============================================
  // COULEURS AVEC OPACITÉ
  // ============================================
  
  /// Rouge avec opacité pour backgrounds
  static Color crimsonWithOpacity(double opacity) =>
    crimsonRed.withValues(alpha: opacity);
  
  /// Noir avec opacité pour overlays
  static Color blackWithOpacity(double opacity) =>
    Colors.black.withValues(alpha: opacity);
  
  // ============================================
  // COULEURS SPÉCIFIQUES AUX FONCTIONNALITÉS
  // ============================================
  
  /// Couleur pour les posts likés
  static const Color likedRed = crimsonRed;
  
  /// Couleur pour les badges vérifiés
  static const Color verifiedBlue = Color(0xFF1DA1F2);
  
  /// Couleur pour les lives actifs
  static const Color liveRed = Color(0xFFFF0000);
  
  /// Couleur pour les notifications
  static const Color notificationBadge = crimsonRed;
  
  // ============================================
  // SHADOW COLORS
  // ============================================
  
  /// Ombre principale
  static const Color shadowColor = Color(0x33000000); // Noir 20%
  
  /// Ombre pour les cards
  static const Color cardShadow = Color(0x1A000000); // Noir 10%
  
  /// Ombre pour le rouge (effets spéciaux)
  static const Color crimsonShadow = Color(0x4DDC143C); // Rouge 30%
}
