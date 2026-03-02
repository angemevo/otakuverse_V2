class ProfileModel {
  final String id;
  final String userId;
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
    required this.favoriteGenres,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isPrivate,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      // ✅ Fix : cast explicite pour les listes JSON
      favoriteAnime: (json['favorite_anime'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      favoriteManga: (json['favorite_manga'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      favoriteGenres: (json['favorite_genres'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'banner_url': bannerUrl,
    'birth_date': birthDate,
    'gender': gender,
    'location': location,
    'website': website,
    'favorite_anime': favoriteAnime,
    'favorite_manga': favoriteManga,
    'favorite_genres': favoriteGenres,
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count': postsCount,
    'is_private': isPrivate,
    'is_verified': isVerified,
  };

  ProfileModel copyWith({
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
    List<String>? favoriteGenres,
    bool? isPrivate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) {
    return ProfileModel(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      website: website ?? this.website,
      favoriteAnime: favoriteAnime ?? this.favoriteAnime,
      favoriteManga: favoriteManga ?? this.favoriteManga,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isPrivate: isPrivate ?? this.isPrivate,
      isVerified: isVerified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayNameOrUsername => displayName ?? 'Utilisateur';
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasBanner => bannerUrl != null && bannerUrl!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;
}