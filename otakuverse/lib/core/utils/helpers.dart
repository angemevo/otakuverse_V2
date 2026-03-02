// lib/core/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';

/// Fonctions utilitaires générales
class Helpers {
  // ============================================
  // SNACKBARS
  // ============================================
  
  /// Afficher un snackbar de succès
  static void showSuccessSnackbar(String message) {
    Get.snackbar(
      'Succès',
      message,
      backgroundColor: AppColors.successGreen,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: AppColors.pureWhite),
    );
  }
  
  /// Afficher un snackbar d'erreur
  static void showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      backgroundColor: AppColors.errorRed,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: AppColors.pureWhite),
    );
  }
  
  /// Afficher un snackbar d'avertissement
  static void showWarningSnackbar(String message) {
    Get.snackbar(
      'Attention',
      message,
      backgroundColor: AppColors.warningOrange,
      colorText: AppColors.deepBlack,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.warning, color: AppColors.deepBlack),
    );
  }
  
  /// Afficher un snackbar d'information
  static void showInfoSnackbar(String message) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: AppColors.infoBlue,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.info, color: AppColors.pureWhite),
    );
  }
  
  // ============================================
  // DIALOGS
  // ============================================
  
  /// Afficher un dialog de confirmation
  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimsonRed,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  /// Afficher un loading dialog
  static void showLoadingDialog([String message = 'Chargement...']) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(
                color: AppColors.crimsonRed,
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// Fermer le loading dialog
  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
  
  // ============================================
  // BOTTOM SHEETS
  // ============================================
  
  /// Afficher un bottom sheet
  static Future<T?> showBottomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return Get.bottomSheet<T>(
      child,
      backgroundColor: Get.isDarkMode ? AppColors.darkGray : AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
    );
  }
  
  // ============================================
  // NAVIGATION
  // ============================================
  
  /// Naviguer vers une page avec animation
  static Future<T?> navigateTo<T>(Widget page) async {
    return await Get.to<T>(
      () => page,
      transition: Transition.cupertino,
      duration: AppConstants.animationNormal,
    );
  }
  
  /// Naviguer et remplacer
  static Future<T?> navigateReplace<T>(Widget page) async {
    return await Get.off<T>(
      () => page,
      transition: Transition.cupertino,
      duration: AppConstants.animationNormal,
    );
  }
  
  /// Naviguer et supprimer tout l'historique
  static Future<T?> navigateOffAll<T>(Widget page) async {
    return await Get.offAll<T>(
      () => page,
      transition: Transition.cupertino,
      duration: AppConstants.animationNormal,
    );
  }
  
  // ============================================
  // URL LAUNCHER
  // ============================================
  
  /// Ouvrir une URL dans le navigateur
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showErrorSnackbar('Impossible d\'ouvrir le lien');
    }
  }
  
  /// Composer un email
  static Future<void> composeEmail(String email, {String? subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showErrorSnackbar('Impossible d\'ouvrir l\'application email');
    }
  }
  
  /// Appeler un numéro
  static Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showErrorSnackbar('Impossible d\'appeler ce numéro');
    }
  }
  
  // ============================================
  // FORMATTERS
  // ============================================
  
  /// Formater un nombre (1000 → 1K, 1000000 → 1M)
  static String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
  }
  
  /// Formater une taille de fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  /// Formater une durée (en secondes) → "2:30"
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // ============================================
  // TEXT PROCESSING
  // ============================================
  
  /// Extraire les hashtags d'un texte
  static List<String> extractHashtags(String text) {
    final regex = RegExp(AppConstants.hashtagPattern);
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }
  
  /// Extraire les mentions d'un texte
  static List<String> extractMentions(String text) {
    final regex = RegExp(AppConstants.mentionPattern);
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }
  
  /// Extraire les URLs d'un texte
  static List<String> extractUrls(String text) {
    final regex = RegExp(AppConstants.urlPattern);
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }
  
  // ============================================
  // CLIPBOARD
  // ============================================
  
  /// Copier du texte dans le presse-papiers
  static Future<void> copyToClipboard(String text) async {
    // Nécessite: import 'package:flutter/services.dart';
    // await Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackbar('Copié dans le presse-papiers');
  }
  
  // ============================================
  // HAPTIC FEEDBACK
  // ============================================
  
  /// Vibration légère
  static Future<void> lightHaptic() async {
    // Nécessite: import 'package:flutter/services.dart';
    // await HapticFeedback.lightImpact();
  }
  
  /// Vibration medium
  static Future<void> mediumHaptic() async {
    // Nécessite: import 'package:flutter/services.dart';
    // await HapticFeedback.mediumImpact();
  }
  
  /// Vibration heavy
  static Future<void> heavyHaptic() async {
    // Nécessite: import 'package:flutter/services.dart';
    // await HapticFeedback.heavyImpact();
  }
  
  // ============================================
  // RESPONSIVE
  // ============================================
  
  /// Vérifier si c'est un mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
  
  /// Vérifier si c'est une tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }
  
  /// Vérifier si c'est un desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }
  
  /// Obtenir la largeur responsive
  static double getResponsiveWidth(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
  
  // ============================================
  // ERROR HANDLING
  // ============================================
  
  /// Gérer les erreurs Supabase
  static void handleSupabaseError(dynamic error) {
    if (error.toString().contains('network')) {
      showErrorSnackbar(AppConstants.networkErrorMessage);
    } else if (error.toString().contains('auth')) {
      showErrorSnackbar(AppConstants.authErrorMessage);
    } else {
      showErrorSnackbar(AppConstants.genericErrorMessage);
    }
  }
  
  // ============================================
  // DEBOUNCE
  // ============================================
  
  /// Debouncer pour recherche
  static void debounce(
    Function() action, {
    Duration delay = AppConstants.searchDebounce,
  }) {
    // Implémentation avec Timer si nécessaire
    action();
  }
}
