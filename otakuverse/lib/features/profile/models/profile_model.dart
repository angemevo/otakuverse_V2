class ProfileModel {
  final String id;
  final String userId;
  final String username;           // ✅ ajouté — obligatoire
  final String? email;             // ✅ ajouté
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? birthDate;
  final String? gender;
  final String? location;
  final String? website;
  final List<String> favoriteAnime;
  final List<String> favoriteManga;
  final List<String> favoriteGames;  // ✅ ajouté
  final List<String> favoriteGenres;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isPrivate;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.username,          // ✅
    this.email,                      // ✅
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.bannerUrl,
    this.birthDate,
    this.gender,
    this.location,
    this.website,
    required this.favoriteAnime,
    required this.favoriteManga,
    required this.favoriteGames,     // ✅
    required this.favoriteGenres,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isPrivate,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── fromJson ──────────────────────────────────────────────────────
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id:          json['id']       as String? ?? json['user_id'] as String,
      userId:      json['user_id']  as String,
      // ✅ username peut être null si le trigger ne l'a pas encore mis
      username:    json['username'] as String? ?? 'utilisateur',
      email:       json['email']    as String?,
      displayName: json['display_name'] as String?,
      bio:         json['bio']          as String?,
      avatarUrl:   json['avatar_url']   as String?,
      bannerUrl:   json['banner_url']   as String?,
      birthDate:   json['birth_date']   as String?,
      gender:      json['gender']       as String?,
      location:    json['location']     as String?,
      website:     json['website']      as String?,
      favoriteAnime: (json['favorite_anime'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      favoriteManga: (json['favorite_manga'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      favoriteGames: (json['favorite_games'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      favoriteGenres: (json['favorite_genres'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount:     json['posts_count']     as int? ?? 0,
      isPrivate:      json['is_private']      as bool? ?? false,
      isVerified:     json['is_verified']     as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // ─── toJson ────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':              id,
    'user_id':         userId,
    'username':        username,
    'email':           email,
    'display_name':    displayName,
    'bio':             bio,
    'avatar_url':      avatarUrl,
    'banner_url':      bannerUrl,
    'birth_date':      birthDate,
    'gender':          gender,
    'location':        location,
    'website':         website,
    'favorite_anime':  favoriteAnime,
    'favorite_manga':  favoriteManga,
    'favorite_games':  favoriteGames, // ✅
    'favorite_genres': favoriteGenres,
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count':     postsCount,
    'is_private':      isPrivate,
    'is_verified':     isVerified,
  };

  // ─── copyWith ──────────────────────────────────────────────────────
  ProfileModel copyWith({
    String? username,
    String? email,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
    String? birthDate,
    String? gender,
    String? location,
    String? website,
    List<String>? favoriteAnime,
    List<String>? favoriteManga,
    List<String>? favoriteGames,  // ✅
    List<String>? favoriteGenres,
    bool? isPrivate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) {
    return ProfileModel(
      id:             id,
      userId:         userId,
      username:       username      ?? this.username,
      email:          email         ?? this.email,
      displayName:    displayName   ?? this.displayName,
      bio:            bio           ?? this.bio,
      avatarUrl:      avatarUrl     ?? this.avatarUrl,
      bannerUrl:      bannerUrl     ?? this.bannerUrl,
      birthDate:      birthDate     ?? this.birthDate,
      gender:         gender        ?? this.gender,
      location:       location      ?? this.location,
      website:        website       ?? this.website,
      favoriteAnime:  favoriteAnime  ?? this.favoriteAnime,
      favoriteManga:  favoriteManga  ?? this.favoriteManga,
      favoriteGames:  favoriteGames  ?? this.favoriteGames, // ✅
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount:     postsCount     ?? this.postsCount,
      isPrivate:      isPrivate      ?? this.isPrivate,
      isVerified:     isVerified,
      createdAt:      createdAt,
      updatedAt:      DateTime.now(),
    );
  }

  // ─── Getters ───────────────────────────────────────────────────────
  /// Affiche le displayName si défini, sinon le @username
  String get displayNameOrUsername => displayName ?? username;

  /// @username formaté
  String get atUsername => '@$username';

  bool get hasAvatar   => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasBanner   => bannerUrl != null && bannerUrl!.isNotEmpty;
  bool get hasBio      => bio != null && bio!.isNotEmpty;
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get hasWebsite  => website != null && website!.isNotEmpty;
}