class ProfileModel {
  final String  id;
  final String  userId;
  final String  username;       // ✅ AJOUTÉ — champ réel de la table
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? website;
  final String? gender;
  final String? location;
  final String? birthDate;

  // ─── Stats sociales ──────────────────────────────────────────────
  final int  followersCount;
  final int  followingCount;
  final int  postsCount;
  final bool isPrivate;
  final bool isVerified;

  // ─── Goûts otaku ─────────────────────────────────────────────────
  final List<String> favoriteAnime;
  final List<String> favoriteManga;
  final List<String> favoriteGames;
  final List<String> favoriteGenres;

  // ─── Rank système ────────────────────────────────────────────────
  final String otakuRank;
  final int    otakuLevel;
  final int    otakuPoints;
  final int    watchlistCount;
  final int    reviewsCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.bannerUrl,
    this.website,
    this.gender,
    this.location,
    this.birthDate,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isPrivate,
    required this.isVerified,
    this.favoriteAnime  = const [],
    this.favoriteManga  = const [],
    this.favoriteGames  = const [],
    this.favoriteGenres = const [],
    this.otakuRank      = 'Novice',
    this.otakuLevel     = 1,
    this.otakuPoints    = 0,
    this.watchlistCount = 0,
    this.reviewsCount   = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── Getters ─────────────────────────────────────────────────────

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasBanner => bannerUrl != null && bannerUrl!.isNotEmpty;
  bool get hasBio    => bio != null && bio!.isNotEmpty;

  /// ✅ FIX — retourne displayName si défini, sinon le vrai username
  /// Avant : retournait displayName via un getter username incorrect
  String get displayNameOrUsername =>
      displayName?.isNotEmpty == true ? displayName! : username;

  // ✅ FIX — supprimé le getter `username` qui écrasait le champ
  // (le champ username est maintenant directement accessible via model.username)

  // ─── OtakuRank ───────────────────────────────────────────────────

  int get pointsForNextLevel {
    final next = otakuLevel + 1;
    return next * next * 10;
  }

  double get levelProgress {
    final current = otakuLevel * otakuLevel * 10;
    final next    = pointsForNextLevel;
    if (next <= current) return 1.0;
    return ((otakuPoints - current) / (next - current)).clamp(0.0, 1.0);
  }

  // ─── fromJson ────────────────────────────────────────────────────

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      // ✅ FIX — id redondant supprimé : userId est la PK réelle
      id:             json['user_id'] as String,
      userId:         json['user_id'] as String,
      // ✅ AJOUTÉ — username parsé depuis la table
      username:       json['username'] as String? ?? '',
      displayName:    json['display_name']  as String?,
      bio:            json['bio']           as String?,
      avatarUrl:      json['avatar_url']    as String?,
      bannerUrl:      json['banner_url']    as String?,
      website:        json['website']       as String?,
      gender:         json['gender']        as String?,
      location:       json['location']      as String?,
      birthDate:      json['birth_date']    as String?,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount:     (json['posts_count']     as num?)?.toInt() ?? 0,
      isPrivate:      json['is_private']    as bool? ?? false,
      isVerified:     json['is_verified']   as bool? ?? false,
      favoriteAnime:  _parseList(json['favorite_anime']),
      favoriteManga:  _parseList(json['favorite_manga']),
      favoriteGames:  _parseList(json['favorite_games']),
      favoriteGenres: _parseList(json['favorite_genres']),
      otakuRank:     json['otaku_rank']     as String? ?? 'Novice',
      otakuLevel:   (json['otaku_level']    as num?)?.toInt() ?? 1,
      otakuPoints:  (json['otaku_points']   as num?)?.toInt() ?? 0,
      watchlistCount:(json['watchlist_count'] as num?)?.toInt() ?? 0,
      reviewsCount:  (json['reviews_count']   as num?)?.toInt() ?? 0,
      createdAt:     DateTime.parse(json['created_at'] as String),
      updatedAt:     DateTime.parse(json['updated_at'] as String),
    );
  }

  static List<String> _parseList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  // ─── copyWith ────────────────────────────────────────────────────
  // ✅ FIX — ajout des champs manquants : username, location, gender,
  //          birthDate, isPrivate, isVerified, favoriteGames

  ProfileModel copyWith({
    String?       username,
    String?       displayName,
    String?       bio,
    String?       avatarUrl,
    String?       bannerUrl,
    String?       website,
    String?       location,
    String?       gender,
    String?       birthDate,
    bool?         isPrivate,
    bool?         isVerified,
    List<String>? favoriteAnime,
    List<String>? favoriteManga,
    List<String>? favoriteGames,
    List<String>? favoriteGenres,
    int?          followersCount,
    int?          followingCount,
    int?          postsCount,
    int?          watchlistCount,
    int?          reviewsCount,
    String?       otakuRank,
    int?          otakuLevel,
    int?          otakuPoints,
  }) => ProfileModel(
    id:             id,
    userId:         userId,
    username:       username       ?? this.username,
    displayName:    displayName    ?? this.displayName,
    bio:            bio            ?? this.bio,
    avatarUrl:      avatarUrl      ?? this.avatarUrl,
    bannerUrl:      bannerUrl      ?? this.bannerUrl,
    website:        website        ?? this.website,
    location:       location       ?? this.location,
    gender:         gender         ?? this.gender,
    birthDate:      birthDate      ?? this.birthDate,
    isPrivate:      isPrivate      ?? this.isPrivate,
    isVerified:     isVerified     ?? this.isVerified,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
    postsCount:     postsCount     ?? this.postsCount,
    favoriteAnime:  favoriteAnime  ?? this.favoriteAnime,
    favoriteManga:  favoriteManga  ?? this.favoriteManga,
    favoriteGames:  favoriteGames  ?? this.favoriteGames,
    favoriteGenres: favoriteGenres ?? this.favoriteGenres,
    otakuRank:      otakuRank      ?? this.otakuRank,
    otakuLevel:     otakuLevel     ?? this.otakuLevel,
    otakuPoints:    otakuPoints    ?? this.otakuPoints,
    watchlistCount: watchlistCount ?? this.watchlistCount,
    reviewsCount:   reviewsCount   ?? this.reviewsCount,
    createdAt:      createdAt,
    updatedAt:      updatedAt,
  );
}
