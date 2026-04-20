import 'package:otakuverse/features/profile/models/profile_model.dart';

class UserModel {
  final String id;
  // final String email;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool isPrivate;

  UserModel({
    required this.id,
    // required this.email,
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

  // ─── Depuis la table profiles (Supabase) ─────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:          json['user_id'] as String,        // ✅ user_id pas id
      // email:       json['email']   as String? ?? '',
      username:    json['username'] as String,
      displayName: json['display_name'] as String?,
      bio:         json['bio']          as String?,
      avatarUrl:   json['avatar_url']   as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount:     json['posts_count']     as int? ?? 0,
      isVerified:     json['is_verified']     as bool? ?? false,
      isPrivate:      json['is_private']      as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // ─── Depuis un ProfileModel ───────────────────────────────────────
  factory UserModel.fromProfile(ProfileModel profile) {
    return UserModel(
      id:             profile.userId,
      // email:          profile.email    ?? '',
      username:       profile.username,
      displayName:    profile.displayName,
      bio:            profile.bio,
      avatarUrl:      profile.avatarUrl,
      followersCount: profile.followersCount,
      followingCount: profile.followingCount,
      postsCount:     profile.postsCount,
      isVerified:     profile.isVerified,
      isPrivate:      profile.isPrivate,
      createdAt:      profile.createdAt,
      updatedAt:      profile.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':         id,
    // 'email':           email,
    'username':        username,
    'display_name':    displayName,
    'bio':             bio,
    'avatar_url':      avatarUrl,
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count':     postsCount,
    'is_verified':     isVerified,
    'is_private':      isPrivate,
    'created_at':      createdAt.toIso8601String(),
    'updated_at':      updatedAt.toIso8601String(),
  };

  // ─── Getters ──────────────────────────────────────────────────────
  String get displayNameOrUsername => displayName ?? username;
  String get atUsername            => '@$username';
  bool   get hasAvatar             => avatarUrl != null && avatarUrl!.isNotEmpty;
}
