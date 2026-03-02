// lib/core/constants/assets.dart

/// Chemins vers les assets de l'application
class AppAssets {
  // ============================================
  // IMAGES
  // ============================================
  
  /// Logo principal
  static const String logo = 'assets/logo/otakuverse_logo.png';
  
  /// Logo blanc (pour fonds sombres)
  static const String logoWhite = 'assets/logo/otakuverse_logo_white.png';
  
  /// Logo icône seule
  static const String logoIcon = 'assets/logo/otakuverse_icon.png';
  
  /// Placeholder avatar
  static const String avatarPlaceholder = 'assets/images/avatar_placeholder.png';
  
  /// Placeholder post
  static const String postPlaceholder = 'assets/images/post_placeholder.png';
  
  /// Image onboarding 1
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  
  /// Image onboarding 2
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  
  /// Image onboarding 3
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  
  /// Image empty state
  static const String emptyState = 'assets/images/empty_state.png';
  
  /// Image error state
  static const String errorState = 'assets/images/error_state.png';
  
  /// Image no connection
  static const String noConnection = 'assets/images/no_connection.png';
  
  // ============================================
  // ICONS
  // ============================================
  
  /// Icône home
  static const String iconHome = 'assets/icons/home.svg';
  
  /// Icône shorts
  static const String iconShorts = 'assets/icons/shorts.svg';
  
  /// Icône communauté
  static const String iconCommunity = 'assets/icons/community.svg';
  
  /// Icône événements
  static const String iconEvents = 'assets/icons/events.svg';
  
  /// Icône profil
  static const String iconProfile = 'assets/icons/profile.svg';
  
  /// Icône plus (création)
  static const String iconPlus = 'assets/icons/plus.svg';
  
  /// Icône like
  static const String iconLike = 'assets/icons/like.svg';
  
  /// Icône like filled
  static const String iconLikeFilled = 'assets/icons/like_filled.svg';
  
  /// Icône comment
  static const String iconComment = 'assets/icons/comment.svg';
  
  /// Icône share
  static const String iconShare = 'assets/icons/share.svg';
  
  /// Icône bookmark
  static const String iconBookmark = 'assets/icons/bookmark.svg';
  
  /// Icône bookmark filled
  static const String iconBookmarkFilled = 'assets/icons/bookmark_filled.svg';
  
  /// Icône verified badge
  static const String iconVerified = 'assets/icons/verified.svg';
  
  /// Icône live
  static const String iconLive = 'assets/icons/live.svg';
  
  /// Icône game
  static const String iconGame = 'assets/icons/game.svg';
  
  // ============================================
  // ANIMATIONS (Lottie)
  // ============================================
  
  /// Animation loading
  static const String animLoading = 'assets/animations/loading.json';
  
  /// Animation success
  static const String animSuccess = 'assets/animations/success.json';
  
  /// Animation error
  static const String animError = 'assets/animations/error.json';
  
  /// Animation like
  static const String animLike = 'assets/animations/like.json';
  
  /// Animation confetti
  static const String animConfetti = 'assets/animations/confetti.json';
  
  /// Animation empty
  static const String animEmpty = 'assets/animations/empty.json';
  
  /// Animation search
  static const String animSearch = 'assets/animations/search.json';
  
  // ============================================
  // CATEGORY IMAGES (optionnel)
  // ============================================
  
  /// Image catégorie Anime
  static const String categoryAnime = 'assets/images/categories/anime.png';
  
  /// Image catégorie Manga
  static const String categoryManga = 'assets/images/categories/manga.png';
  
  /// Image catégorie Gaming
  static const String categoryGaming = 'assets/images/categories/gaming.png';
  
  /// Image catégorie Cosplay
  static const String categoryCosplay = 'assets/images/categories/cosplay.png';
  
  /// Image catégorie Art
  static const String categoryArt = 'assets/images/categories/art.png';
}

/// Extension pour vérifier si un asset existe
extension AssetExtension on String {
  /// Vérifie si c'est un asset local
  bool get isLocalAsset => startsWith('assets/');
  
  /// Vérifie si c'est une image
  bool get isImage => 
      endsWith('.png') || 
      endsWith('.jpg') || 
      endsWith('.jpeg') || 
      endsWith('.webp');
  
  /// Vérifie si c'est un SVG
  bool get isSvg => endsWith('.svg');
  
  /// Vérifie si c'est une animation Lottie
  bool get isLottie => endsWith('.json');
}
