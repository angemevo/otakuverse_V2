class NotificationModel {
  final String  id;
  final String  userId;
  final String  actorId;
  final String  type; // like | comment | reply | follow
  final String? postId;
  final String? commentId;
  final bool    isRead;
  final DateTime createdAt;

  // ─── Données de l'acteur (JOIN) ──────────────────────────────────
  final String? actorUsername;
  final String? actorDisplayName;
  final String? actorAvatarUrl;

  // ─── Données du post (JOIN) ──────────────────────────────────────
  final String? postMediaUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.postId,
    this.commentId,
    required this.isRead,
    required this.createdAt,
    this.actorUsername,
    this.actorDisplayName,
    this.actorAvatarUrl,
    this.postMediaUrl,
  });

  // ─── Getters ─────────────────────────────────────────────────────
  String get actorName =>
      actorDisplayName ?? actorUsername ?? 'Utilisateur';

  bool get hasAvatar =>
      actorAvatarUrl != null && actorAvatarUrl!.isNotEmpty;

  bool get hasPost =>
      postId != null;

  bool get hasPostMedia =>
      postMediaUrl != null && postMediaUrl!.isNotEmpty;

  // ─── Message selon le type ───────────────────────────────────────
  String get message {
    switch (type) {
      case 'like':    return 'a aimé ta publication';
      case 'comment': return 'a commenté ta publication';
      case 'reply':   return 'a répondu à ton commentaire';
      case 'follow':  return 'a commencé à te suivre';
      default:        return 'a interagi avec toi';
    }
  }

  // ─── fromJson ────────────────────────────────────────────────────
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor']  as Map<String, dynamic>?;
    final post  = json['post']   as Map<String, dynamic>?;

    return NotificationModel(
      id:               json['id']         as String,
      userId:           json['user_id']    as String,
      actorId:          json['actor_id']   as String,
      type:             json['type']       as String,
      postId:           json['post_id']    as String?,
      commentId:        json['comment_id'] as String?,
      isRead:           json['is_read']    as bool? ?? false,
      createdAt:        DateTime.parse(json['created_at'] as String),
      actorUsername:    actor?['username']     as String?,
      actorDisplayName: actor?['display_name'] as String?,
      actorAvatarUrl:   actor?['avatar_url']   as String?,
      postMediaUrl: (post?['media_urls'] as List?)?.isNotEmpty == true
          ? (post!['media_urls'] as List).first as String
          : null,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id:               id,
      userId:           userId,
      actorId:          actorId,
      type:             type,
      postId:           postId,
      commentId:        commentId,
      isRead:           isRead ?? this.isRead,
      createdAt:        createdAt,
      actorUsername:    actorUsername,
      actorDisplayName: actorDisplayName,
      actorAvatarUrl:   actorAvatarUrl,
      postMediaUrl:     postMediaUrl,
    );
  }
}
