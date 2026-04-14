class ProfileModel {
  final String  id;
  final String  userId;
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

  // ✅ Nouveau — Rank système
  final String otakuRank;    // Novice, Otaku, Senpai...
  final int    otakuLevel;   // 1-50
  final int    otakuPoints;  // Points bruts
  final int    watchlistCount;
  final int    reviewsCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
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

  String get displayNameOrUsername =>
      displayName?.isNotEmpty == true ? displayName! : username;

  // ✅ Prochain niveau — points nécessaires
  int get pointsForNextLevel {
    final next = otakuLevel + 1;
    return (next * next * 10);
  }

  // ✅ Progression vers le niveau suivant (0.0 à 1.0)
  double get levelProgress {
    final current = otakuLevel * otakuLevel * 10;
    final next    = pointsForNextLevel;
    if (next <= current) return 1.0;
    return ((otakuPoints - current) / (next - current)).clamp(0.0, 1.0);
  }

  String get username => displayName ?? 'utilisateur';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id:             (json['id'] ?? json['user_id']) as String,
      userId:         json['user_id']    as String,
      displayName:    json['display_name'] as String?,
      bio:            json['bio']          as String?,
      avatarUrl:      json['avatar_url']   as String?,
      bannerUrl:      json['banner_url']   as String?,
      website:        json['website']      as String?,
      gender:         json['gender']       as String?,
      location:       json['location']     as String?,
      birthDate:      json['birth_date']   as String?,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount:     (json['posts_count']     as num?)?.toInt() ?? 0,
      isPrivate:      json['is_private']   as bool? ?? false,
      isVerified:     json['is_verified']  as bool? ?? false,
      favoriteAnime:  _parseList(json['favorite_anime']),
      favoriteManga:  _parseList(json['favorite_manga']),
      favoriteGames:  _parseList(json['favorite_games']),
      favoriteGenres: _parseList(json['favorite_genres']),
      // ✅ Rank
      otakuRank:     json['otaku_rank']   as String? ?? 'Novice',
      otakuLevel:   (json['otaku_level']   as num?)?.toInt() ?? 1,
      otakuPoints:  (json['otaku_points']  as num?)?.toInt() ?? 0,
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

  ProfileModel copyWith({
    String?       displayName,
    String?       bio,
    String?       avatarUrl,
    String?       bannerUrl,
    String?       website,
    List<String>? favoriteGenres,
    List<String>? favoriteAnime,
    List<String>? favoriteManga,
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
    displayName:    displayName    ?? this.displayName,
    bio:            bio            ?? this.bio,
    avatarUrl:      avatarUrl      ?? this.avatarUrl,
    bannerUrl:      bannerUrl      ?? this.bannerUrl,
    website:        website        ?? this.website,
    gender:         gender,
    location:       location,
    birthDate:      birthDate,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
    postsCount:     postsCount     ?? this.postsCount,
    isPrivate:      isPrivate,
    isVerified:     isVerified,
    favoriteAnime:  favoriteAnime  ?? this.favoriteAnime,
    favoriteManga:  favoriteManga  ?? this.favoriteManga,
    favoriteGames:  favoriteGames,
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