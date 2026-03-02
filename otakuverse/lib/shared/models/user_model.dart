class UserModel {
  final String id;
  final String email;
  final String username;
  final String? displayName;   // nullable → reste null si absent
  final String? bio;           // nullable → reste null si absent
  final String? avatarUrl;     // nullable → reste null si absent
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool isPrivate;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    this.isPrivate = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,   // ✅ null si absent
      bio: json['bio'] as String?,                    // ✅ null si absent
      avatarUrl: json['avatar_url'] as String?,       // ✅ null si absent
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isPrivate: json['is_private'] ?? false,
      createdAt: json['created_at'] != null          // ✅ protection crash
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count': postsCount,
    'is_verified': isVerified,
    'is_private': isPrivate,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}