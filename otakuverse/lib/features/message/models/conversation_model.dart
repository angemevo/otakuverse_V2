class ConversationModel {
  final String    id;
  final String    type;
  final String?   name;
  final String?   avatarUrl;
  final String?   lastMessageText;
  final DateTime? lastMessageAt;
  final int       unreadCount;

  // ✅ Infos de l'autre utilisateur (conversation directe)
  final String?   otherUserId;
  final String?   otherUsername;
  final String?   otherDisplayName;
  final String?   otherAvatarUrl;

  const ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount  = 0,
    this.otherUserId,
    this.otherUsername,
    this.otherDisplayName,
    this.otherAvatarUrl,
  });

  // ✅ Nom affiché selon le type
  String get displayName {
    if (type == 'group') return name ?? 'Groupe';
    return otherDisplayName ?? otherUsername ?? 'Utilisateur';
  }

  // ✅ Avatar affiché selon le type
  String? get displayAvatar {
    if (type == 'group') return avatarUrl;
    return otherAvatarUrl;
  }

  bool get isGroup => type == 'group';
}
