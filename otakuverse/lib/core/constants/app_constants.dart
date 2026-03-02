// lib/core/constants/app_constants.dart

/// Constantes générales de l'application Otakuverse
class AppConstants {
  // ============================================
  // APP INFO
  // ============================================
  
  /// Nom de l'application
  static const String appName = 'Otakuverse';
  
  /// Version de l'app
  static const String appVersion = '1.0.0';
  
  /// Tagline
  static const String appTagline = 'Le réseau social des passionnés d\'anime et manga';
  
  // ============================================
  // SOCIAL LIMITS
  // ============================================
  
  /// Longueur max caption post (Instagram-style)
  static const int maxCaptionLength = 2200;
  
  /// Longueur max description short (TikTok-style)
  static const int maxShortDescriptionLength = 500;
  
  /// Longueur max bio profil
  static const int maxBioLength = 500;
  
  /// Longueur max commentaire
  static const int maxCommentLength = 500;
  
  /// Longueur max message privé
  static const int maxMessageLength = 2000;
  
  /// Longueur min username
  static const int minUsernameLength = 3;
  
  /// Longueur max username
  static const int maxUsernameLength = 30;
  
  /// Longueur min password
  static const int minPasswordLength = 8;
  
  // ============================================
  // MEDIA LIMITS
  // ============================================
  
  /// Nombre max d'images par post
  static const int maxImagesPerPost = 10;
  
  /// Taille max image (5 MB)
  static const int maxImageSize = 5 * 1024 * 1024;
  
  /// Taille max vidéo (100 MB)
  static const int maxVideoSize = 100 * 1024 * 1024;
  
  /// Durée max short (60 secondes)
  static const int maxShortDuration = 60;
  
  /// Durée max live (4 heures)
  static const int maxLiveDuration = 4 * 60 * 60;
  
  // ============================================
  // PAGINATION
  // ============================================
  
  /// Items par page (feed)
  static const int postsPerPage = 20;
  
  /// Items par page (shorts)
  static const int shortsPerPage = 15;
  
  /// Items par page (commentaires)
  static const int commentsPerPage = 30;
  
  /// Items par page (recherche)
  static const int searchResultsPerPage = 20;
  
  /// Items par page (notifications)
  static const int notificationsPerPage = 50;
  
  // ============================================
  // CACHE DURATIONS
  // ============================================
  
  /// Durée cache posts (5 minutes)
  static const Duration postsCacheDuration = Duration(minutes: 5);
  
  /// Durée cache profil (10 minutes)
  static const Duration profileCacheDuration = Duration(minutes: 10);
  
  /// Durée cache feed (3 minutes)
  static const Duration feedCacheDuration = Duration(minutes: 3);
  
  // ============================================
  // TIMEOUTS
  // ============================================
  
  /// Timeout requête API (30 secondes)
  static const Duration apiTimeout = Duration(seconds: 30);
  
  /// Timeout upload média (2 minutes)
  static const Duration uploadTimeout = Duration(minutes: 2);
  
  /// Timeout connexion (10 secondes)
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // ============================================
  // REGEX PATTERNS
  // ============================================
  
  /// Pattern email
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  /// Pattern username (alphanumeric + underscore)
  static const String usernamePattern = r'^[a-zA-Z0-9_]{3,30}$';
  
  /// Pattern hashtag
  static const String hashtagPattern = r'#(\w+)';
  
  /// Pattern mention
  static const String mentionPattern = r'@(\w+)';
  
  /// Pattern URL
  static const String urlPattern =
      r'https?://[^\s]+';
  
  // ============================================
  // DATE FORMATS
  // ============================================
  
  /// Format date affichage (27 janv. 2026)
  static const String displayDateFormat = 'd MMM yyyy';
  
  /// Format date heure (27/01/2026 14:30)
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  /// Format heure (14:30)
  static const String timeFormat = 'HH:mm';
  
  /// Format date complète (Mardi 27 janvier 2026)
  static const String fullDateFormat = 'EEEE d MMMM yyyy';
  
  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  
  /// Durée animation rapide (150ms)
  static const Duration animationFast = Duration(milliseconds: 150);
  
  /// Durée animation standard (300ms)
  static const Duration animationNormal = Duration(milliseconds: 300);
  
  /// Durée animation lente (500ms)
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // ============================================
  // DEBOUNCE DURATIONS
  // ============================================
  
  /// Debounce recherche (500ms)
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  /// Debounce input (300ms)
  static const Duration inputDebounce = Duration(milliseconds: 300);
  
  // ============================================
  // RETRY CONFIGURATION
  // ============================================
  
  /// Nombre max de tentatives
  static const int maxRetryAttempts = 3;
  
  /// Délai entre tentatives (2 secondes)
  static const Duration retryDelay = Duration(seconds: 2);
  
  // ============================================
  // STORAGE KEYS
  // ============================================
  
  /// Clé token auth
  static const String tokenKey = 'auth_token';
  
  /// Clé user id
  static const String userIdKey = 'user_id';

  /// Clé user data
  static const String userDatakey = 'user_data';
  
  /// Clé theme mode
  static const String themeModeKey = 'theme_mode';
  
  /// Clé langue
  static const String languageKey = 'language';
  
  /// Clé onboarding completed
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  /// Clé notifications enabled
  static const String notificationsEnabledKey = 'notifications_enabled';
  
  // ============================================
  // SUPABASE BUCKETS
  // ============================================
  
  /// Bucket avatars
  static const String avatarsBucket = 'avatars';
  
  /// Bucket posts
  static const String postsBucket = 'posts';
  
  /// Bucket shorts
  static const String shortsBucket = 'shorts';
  
  /// Bucket banners
  static const String bannersBucket = 'banners';
  
  // ============================================
  // NOTIFICATION TYPES
  // ============================================
  
  /// Type notif like
  static const String notifLike = 'like';
  
  /// Type notif comment
  static const String notifComment = 'comment';
  
  /// Type notif follow
  static const String notifFollow = 'follow';
  
  /// Type notif mention
  static const String notifMention = 'mention';
  
  /// Type notif event
  static const String notifEvent = 'event';
  
  /// Type notif live
  static const String notifLive = 'live';
  
  /// Type notif message
  static const String notifMessage = 'message';
  
  // ============================================
  // EXTERNAL LINKS
  // ============================================
  
  /// Lien privacy policy
  static const String privacyPolicyUrl = 'https://otakuverse.app/privacy';
  
  /// Lien terms of service
  static const String termsOfServiceUrl = 'https://otakuverse.app/terms';
  
  /// Lien support
  static const String supportUrl = 'https://otakuverse.app/support';
  
  // ============================================
  // ERROR MESSAGES
  // ============================================
  
  /// Message erreur réseau
  static const String networkErrorMessage = 
      'Erreur de connexion. Vérifiez votre connexion internet.';
  
  /// Message erreur serveur
  static const String serverErrorMessage = 
      'Erreur serveur. Veuillez réessayer plus tard.';
  
  /// Message erreur authentification
  static const String authErrorMessage = 
      'Session expirée. Veuillez vous reconnecter.';
  
  /// Message erreur générique
  static const String genericErrorMessage = 
      'Une erreur est survenue. Veuillez réessayer.';
  
  // ============================================
  // COMMUNITY CATEGORIES
  // ============================================
  
  /// Catégories de communautés
  static const List<String> communityCategories = [
    'Anime',
    'Manga',
    'Gaming',
    'Cosplay',
    'Art',
    'Discussion',
    'Autre',
  ];
  
  // ============================================
  // EVENT CATEGORIES
  // ============================================
  
  /// Catégories d'événements
  static const List<String> eventCategories = [
    'Convention',
    'Watch Party',
    'Meetup',
    'Tournament',
    'Autre',
  ];
  
  // ============================================
  // REPORT REASONS
  // ============================================
  
  /// Raisons de signalement
  static const List<String> reportReasons = [
    'Spam',
    'Harcèlement',
    'Contenu inapproprié',
    'Droits d\'auteur',
    'Autre',
  ];
}
