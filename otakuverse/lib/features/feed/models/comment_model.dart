class CommentModel {
  final String  id;
  final String  postId;
  final String  userId;
  final String? parentId;
  final String  content;
  final int     likesCount;
  final bool    isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── Données du profil (JOIN) ─────────────────────────────────────
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  // ─── Réponses (chargées séparément) ──────────────────────────────
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.likesCount,
    this.isLiked  = false,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.replies  = const [],
  });

  // ─── Getters ─────────────────────────────────────────────────────
  String get displayNameOrUsername => displayName ?? username ?? 'Utilisateur';
  bool   get hasAvatar             => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool   get isReply               => parentId != null;
  bool   get hasReplies            => replies.isNotEmpty;

  // ─── fromJson ────────────────────────────────────────────────────
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return CommentModel(
      id:          json['id']        as String,
      postId:      json['post_id']   as String,
      userId:      json['user_id']   as String,
      parentId:    json['parent_id'] as String?,
      content:     json['content']   as String,
      likesCount:  json['likes_count'] as int? ?? 0,
      createdAt:   json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt:   json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      username:    profile?['username']     as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl:   profile?['avatar_url']   as String?,
    );
  }

  // ─── copyWith ────────────────────────────────────────────────────
  CommentModel copyWith({
    String?             content,
    int?                likesCount,
    bool?               isLiked,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id:          id,
      postId:      postId,
      userId:      userId,
      parentId:    parentId,
      content:     content     ?? this.content,
      likesCount:  likesCount  ?? this.likesCount,
      isLiked:     isLiked     ?? this.isLiked,
      createdAt:   createdAt,
      updatedAt:   updatedAt,
      username:    username,
      displayName: displayName,
      avatarUrl:   avatarUrl,
      replies:     replies     ?? this.replies,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CommentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}