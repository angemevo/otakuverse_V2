class ConversationModel {
  final String id;
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final String? lastMessageSender; // 'me' ou 'them'

  ConversationModel({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastMessageSender,
  });

  String get displayNameOrUsername => displayName ?? username ?? 'Utilisateur';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      username: json['user']?['username']?.toString(),
      displayName: json['user']?['display_name']?.toString(),
      avatarUrl: json['user']?['avatar_url']?.toString(),
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      isOnline: json['is_online'] ?? false,
      lastMessageSender: json['last_message_sender']?.toString(),
    );
  }
}