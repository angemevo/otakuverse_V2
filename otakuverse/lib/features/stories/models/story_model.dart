class StoryModel {
  final String   id;
  final String   userId;
  final String?  mediaUrl;
  final String   mediaType;
  final String?  textContent;
  final String?  bgColor;
  final int      duration;
  final int      viewsCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isDiscovery;

  // ✅ Données de l'auteur (join)
  final String?  username;
  final String?  displayName;
  final String?  avatarUrl;

  // ✅ État local
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.userId,
    this.mediaUrl,
    required this.mediaType,
    this.textContent,
    this.bgColor,
    required this.duration,
    required this.viewsCount,
    required this.createdAt,
    required this.expiresAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isViewed = false,
    this.isDiscovery = false,
  });

  String get displayNameOrUsername =>
      displayName ?? username ?? 'Utilisateur';

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt);

  factory StoryModel.fromJson(
      Map<String, dynamic> json) {
    final profile = json['profiles']
        as Map<String, dynamic>?;

    return StoryModel(
      id:          json['id']          as String,
      userId:      json['user_id']     as String,
      mediaUrl:    json['media_url']   as String?,
      mediaType:   json['media_type']  as String? ??
          'image',
      textContent: json['text_content'] as String?,
      bgColor:     json['bg_color']    as String?,
      duration:    json['duration']    as int? ?? 5,
      viewsCount:  json['views_count'] as int? ?? 0,
      createdAt:   DateTime.parse(
          json['created_at'] as String),
      expiresAt:   DateTime.parse(
          json['expires_at'] as String),
      username:    profile?['username']     as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl:   profile?['avatar_url']   as String?,
      isViewed:    json['is_viewed']         as bool? ??
          false,
      isDiscovery: json['is_discovery'] == true,
    );
  }
}

// ✅ Groupe de stories par utilisateur
class StoryGroup {
  final String        userId;
  final String        username;
  final String?       displayName;
  final String?       avatarUrl;
  final List<StoryModel> stories;
  final bool          hasUnviewed;
  final bool          isMe;
  final bool isDiscovery;
  final bool isSponsored;

  const StoryGroup({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.stories,
    required this.hasUnviewed,
    required this.isMe,
    this.isDiscovery = false,
    this.isSponsored = false,
  });

  String get displayNameOrUsername =>
      displayName ?? username;

  StoryModel get latest => stories.last;
}