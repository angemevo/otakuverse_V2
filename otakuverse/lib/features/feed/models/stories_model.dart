class StoryModel {
  final String id;
  final String userId;
  final List<String> mediaUrl;
  final String mediaType;
  final int viewsCount;
  final bool seen;
  final Map<String, dynamic>? user;

  StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.viewsCount,
    this.user,
    this.seen = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: (json['media_url'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mediaType: json['media_type'] as String,
      viewsCount:
          int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'views_count': viewsCount,
    };
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    List<String>? mediaUrl,
    String? mediaType,
    int? viewsCount,
    bool? seen,
    Map<String, dynamic>? user,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      viewsCount: viewsCount ?? this.viewsCount,
      seen: seen ?? this.seen,
      user: user ?? this.user,
    );
  }

  String get username => user?['username'] ?? '';
  String? get avatarUrl => user?['avatar_url'];
}
