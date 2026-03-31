class StoryModel {
  final String       id;
  final String       userId;
  final String?      mediaUrl;
  final String       mediaType;
  // ✅ Ajout multi-médias
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final String?      textContent;
  final String?      bgColor;
  final int          duration;
  final int          viewsCount;
  final DateTime     createdAt;
  final DateTime     expiresAt;
  final bool         isDiscovery;
  final String?      username;
  final String?      displayName;
  final String?      avatarUrl;
  final bool         isViewed;

  const StoryModel({
    required this.id,
    required this.userId,
    this.mediaUrl,
    required this.mediaType,
    this.mediaUrls  = const [],  // ✅
    this.mediaTypes = const [],  // ✅
    this.textContent,
    this.bgColor,
    required this.duration,
    required this.viewsCount,
    required this.createdAt,
    required this.expiresAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isViewed    = false,
    this.isDiscovery = false,
  });

  // ✅ Tous les médias unifiés
  List<String> get allMediaUrls {
    if (mediaUrls.isNotEmpty) return mediaUrls;
    if (mediaUrl != null)     return [mediaUrl!];
    return [];
  }

  List<String> get allMediaTypes {
    if (mediaTypes.isNotEmpty) return mediaTypes;
    return List.filled(
        allMediaUrls.length, mediaType);
  }

  // ✅ Nombre de slides
  int get slidesCount =>
      mediaType == 'text' ? 1 : allMediaUrls.length.clamp(1, 10);

  String get displayNameOrUsername =>
      displayName ?? username ?? 'Utilisateur';

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt);

  factory StoryModel.fromJson(
      Map<String, dynamic> json) {
    final profile =
        json['profiles'] as Map<String, dynamic>?;

    // ✅ Parser les listes correctement
    final rawUrls  = json['media_urls']  as List?;
    final rawTypes = json['media_types'] as List?;

    return StoryModel(
      id:          json['id']         as String,
      userId:      json['user_id']    as String,
      mediaUrl:    json['media_url']  as String?,      // ✅ String?
      mediaType:   json['media_type'] as String? ?? 'image',
      mediaUrls:   rawUrls?.cast<String>()  ?? [],     // ✅ List<String>
      mediaTypes:  rawTypes?.cast<String>() ?? [],     // ✅ List<String>
      textContent: json['text_content'] as String?,
      bgColor:     json['bg_color']     as String?,
      duration:   (json['duration']     as num?)?.toInt() ?? 5,
      viewsCount: (json['views_count']  as num?)?.toInt() ?? 0,
      createdAt:   DateTime.parse(
          json['created_at'] as String),
      expiresAt:   DateTime.parse(
          json['expires_at'] as String),
      username:    profile?['username']     as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl:   profile?['avatar_url']   as String?,
      isViewed:    json['is_viewed']    == true,
      isDiscovery: json['is_discovery'] == true,
    );
  }

  // ✅ copyWith pour les mises à jour optimistes
  StoryModel copyWith({
    bool?         isViewed,
    int?          viewsCount,
  }) {
    return StoryModel(
      id:          id,
      userId:      userId,
      mediaUrl:    mediaUrl,
      mediaType:   mediaType,
      mediaUrls:   mediaUrls,
      mediaTypes:  mediaTypes,
      textContent: textContent,
      bgColor:     bgColor,
      duration:    duration,
      viewsCount:  viewsCount  ?? this.viewsCount,
      createdAt:   createdAt,
      expiresAt:   expiresAt,
      username:    username,
      displayName: displayName,
      avatarUrl:   avatarUrl,
      isViewed:    isViewed    ?? this.isViewed,
      isDiscovery: isDiscovery,
    );
  }
}

// ─── STORY GROUP ─────────────────────────────────────────────────────
class StoryGroup {
  final String           userId;
  final String           username;
  final String?          displayName;
  final String?          avatarUrl;
  final List<StoryModel> stories;
  final bool             hasUnviewed;
  final bool             isMe;
  final bool             isDiscovery;
  final bool             isSponsored;

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

  // ✅ Nombre total de stories non vues
  int get unviewedCount =>
      stories.where((s) => !s.isViewed).length;
}