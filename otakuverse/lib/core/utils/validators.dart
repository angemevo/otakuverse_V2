// lib/core/utils/validators.dart
import '../constants/app_constants.dart';

/// Validateurs de formulaires pour Otakuverse
class Validators {
  // ============================================
  // EMAIL
  // ============================================
  
  /// Valider un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    
    return null;
  }
  
  // ============================================
  // PASSWORD
  // ============================================
  
  /// Valider un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères';
    }
    
    // Au moins une lettre
    if (!value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Le mot de passe doit contenir au moins une lettre';
    }
    
    // Au moins un chiffre
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    return null;
  }
  
  /// Valider confirmation mot de passe
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    
    return null;
  }
  
  // ============================================
  // USERNAME
  // ============================================
  
  /// Valider un username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    
    if (value.length < AppConstants.minUsernameLength) {
      return 'Le nom d\'utilisateur doit contenir au moins ${AppConstants.minUsernameLength} caractères';
    }
    
    if (value.length > AppConstants.maxUsernameLength) {
      return 'Le nom d\'utilisateur ne peut pas dépasser ${AppConstants.maxUsernameLength} caractères';
    }
    
    final usernameRegex = RegExp(AppConstants.usernamePattern);
    if (!usernameRegex.hasMatch(value)) {
      return 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et underscore';
    }
    
    return null;
  }
  
  // ============================================
  // DISPLAY NAME
  // ============================================
  
  /// Valider un nom d'affichage
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    if (value.length > 50) {
      return 'Le nom d\'affichage ne peut pas dépasser 50 caractères';
    }
    
    return null;
  }
  
  // ============================================
  // BIO
  // ============================================
  
  /// Valider une bio
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    if (value.length > AppConstants.maxBioLength) {
      return 'La bio ne peut pas dépasser ${AppConstants.maxBioLength} caractères';
    }
    
    return null;
  }
  
  // ============================================
  // POST CAPTION
  // ============================================
  
  /// Valider une légende de post
  static String? validateCaption(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    if (value.length > AppConstants.maxCaptionLength) {
      return 'La légende ne peut pas dépasser ${AppConstants.maxCaptionLength} caractères';
    }
    
    return null;
  }
  
  // ============================================
  // COMMENT
  // ============================================
  
  /// Valider un commentaire
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le commentaire ne peut pas être vide';
    }
    
    if (value.length > AppConstants.maxCommentLength) {
      return 'Le commentaire ne peut pas dépasser ${AppConstants.maxCommentLength} caractères';
    }
    
    return null;
  }
  
  // ============================================
  // COMMUNITY NAME
  // ============================================
  
  /// Valider un nom de communauté
  static String? validateCommunityName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom de la communauté est requis';
    }
    
    if (value.length < 3) {
      return 'Le nom doit contenir au moins 3 caractères';
    }
    
    if (value.length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }
    
    return null;
  }
  
  // ============================================
  // EVENT TITLE
  // ============================================
  
  /// Valider un titre d'événement
  static String? validateEventTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le titre est requis';
    }
    
    if (value.length < 3) {
      return 'Le titre doit contenir au moins 3 caractères';
    }
    
    if (value.length > 100) {
      return 'Le titre ne peut pas dépasser 100 caractères';
    }
    
    return null;
  }
  
  // ============================================
  // URL
  // ============================================
  
  /// Valider une URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    final urlRegex = RegExp(AppConstants.urlPattern);
    if (!urlRegex.hasMatch(value)) {
      return 'URL invalide';
    }
    
    return null;
  }
  
  // ============================================
  // PHONE
  // ============================================
  
  /// Valider un numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    // Format international ou local
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }
  
  // ============================================
  // REQUIRED FIELD
  // ============================================
  
  /// Valider un champ requis
  static String? validateRequired(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }
  
  // ============================================
  // NUMBER
  // ============================================
  
  /// Valider un nombre
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nombre';
    }
    
    if (int.tryParse(value) == null) {
      return 'Veuillez entrer un nombre valide';
    }
    
    return null;
  }
  
  /// Valider un nombre dans une plage
  static String? validateNumberRange(String? value, int min, int max) {
    final numberError = validateNumber(value);
    if (numberError != null) return numberError;
    
    final number = int.parse(value!);
    if (number < min || number > max) {
      return 'Le nombre doit être entre $min et $max';
    }
    
    return null;
  }
  
  // ============================================
  // DATE
  // ============================================
  
  /// Valider une date future
  static String? validateFutureDate(DateTime? value) {
    if (value == null) {
      return 'Veuillez sélectionner une date';
    }
    
    if (value.isBefore(DateTime.now())) {
      return 'La date doit être dans le futur';
    }
    
    return null;
  }
  
  /// Valider une date passée
  static String? validatePastDate(DateTime? value) {
    if (value == null) {
      return 'Veuillez sélectionner une date';
    }
    
    if (value.isAfter(DateTime.now())) {
      return 'La date doit être dans le passé';
    }
    
    return null;
  }
  
  // ============================================
  // AGE
  // ============================================
  
  /// Valider l'âge minimum (13 ans)
  static String? validateMinimumAge(DateTime? birthDate, {int minimumAge = 13}) {
    if (birthDate == null) {
      return 'Veuillez sélectionner votre date de naissance';
    }
    
    final age = DateTime.now().year - birthDate.year;
    if (age < minimumAge) {
      return 'Vous devez avoir au moins $minimumAge ans';
    }
    
    return null;
  }
  
  // ============================================
  // FILE SIZE
  // ============================================
  
  /// Valider la taille d'un fichier
  static String? validateFileSize(int fileSizeBytes, int maxSizeBytes) {
    if (fileSizeBytes > maxSizeBytes) {
      final maxSizeMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'Le fichier ne doit pas dépasser $maxSizeMB MB';
    }
    return null;
  }
  
  // ============================================
  // CUSTOM VALIDATORS
  // ============================================
  
  /// Composer plusieurs validateurs
  static String? composeValidators(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
