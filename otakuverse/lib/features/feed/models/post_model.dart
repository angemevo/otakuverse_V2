class PostModel {
  final String id;
  final String userId;
  final String caption;
  final List<String> mediaUrls;
  final String? location;
  final bool allowComments;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isPinned;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── Données du profil (JOIN Supabase) ───────────────────────────
  final String? username;
  final String? displayName; // ✅ ajouté — était référencé mais absent
  final String? avatarUrl;

  const PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    required this.mediaUrls,
    this.location,
    required this.allowComments,
    required this.likesCount,
    required this.commentsCount,
    this.sharesCount = 0,
    this.viewsCount  = 0,
    required this.isPinned,
    this.isLiked     = false,
    this.username,
    this.displayName, // ✅
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── GETTERS ─────────────────────────────────────────────────────
  // ✅ Un seul getter — plus de doublons
  String get displayNameOrUsername =>
      displayName ?? username ?? 'Utilisateur';
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get isCarousel  => mediaUrls.length > 1;
  int  get mediaCount  => mediaUrls.length;
  bool get hasMedia    => mediaUrls.isNotEmpty;

  // ─── fromJson ────────────────────────────────────────────────────
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return PostModel(
      id:            json['id']       as String,
      userId:        json['user_id']  as String,
      caption:       json['caption']  as String?  ?? '',
      mediaUrls:     (json['media_urls'] as List<dynamic>? ?? [])
                         .map((e) => e.toString()).toList(),
      location:      json['location']       as String?,
      allowComments: json['allow_comments'] as bool?   ?? true,
      likesCount:    json['likes_count']    as int?    ?? 0,
      commentsCount: json['comments_count'] as int?    ?? 0,
      sharesCount:   json['shares_count']   as int?    ?? 0,
      viewsCount:    json['views_count']    as int?    ?? 0,
      isPinned:      json['is_pinned']      as bool?   ?? false,
      // ✅ Récupère username ET display_name depuis le JOIN profiles
      username:     profile?['username']     as String?
                        ?? json['username']  as String?,
      displayName:  profile?['display_name'] as String?
                        ?? json['display_name'] as String?,
      avatarUrl:    profile?['avatar_url']   as String?
                        ?? json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // ─── toJson ──────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':             id,
    'user_id':        userId,
    'caption':        caption,
    'media_urls':     mediaUrls,
    if (location != null) 'location': location,
    'allow_comments': allowComments,
    'likes_count':    likesCount,
    'comments_count': commentsCount,
    'shares_count':   sharesCount,
    'views_count':    viewsCount,
    'is_pinned':      isPinned,
    'created_at':     createdAt.toIso8601String(),
    'updated_at':     updatedAt.toIso8601String(),
  };

  // ─── copyWith ────────────────────────────────────────────────────
  PostModel copyWith({
    String? caption,
    List<String>? mediaUrls,
    String? location,
    bool? allowComments,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isPinned,
    bool? isLiked,
    String? username,
    String? displayName, // ✅
    String? avatarUrl,
  }) {
    return PostModel(
      id:            id,
      userId:        userId,
      caption:       caption       ?? this.caption,
      mediaUrls:     mediaUrls     ?? this.mediaUrls,
      location:      location      ?? this.location,
      allowComments: allowComments ?? this.allowComments,
      likesCount:    likesCount    ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount:   sharesCount   ?? this.sharesCount,
      viewsCount:    viewsCount    ?? this.viewsCount,
      isPinned:      isPinned      ?? this.isPinned,
      isLiked:       isLiked       ?? this.isLiked,
      username:      username      ?? this.username,
      displayName:   displayName   ?? this.displayName, // ✅
      avatarUrl:     avatarUrl     ?? this.avatarUrl,
      createdAt:     createdAt,
      updatedAt:     updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PostModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}