class MessageModel {
  final String    id;
  final String    conversationId;
  final String    senderId;
  final String?   text;
  final String?   imageUrl;
  final bool      isRead;
  final DateTime  createdAt;
  final String?   replyToId;
  final MessageModel? replyToMessage;

  // ✅ Infos sender (join)
  final String?   senderUsername;
  final String?   senderDisplayName;
  final String?   senderAvatarUrl;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    this.replyToId,
    this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    this.replyToMessage,
  });

  MessageModel copyWith({
    bool? isRead, 
    MessageModel? replyToMessage}) {
    return MessageModel(
      id:             id,
      conversationId: conversationId,
      senderId:       senderId,
      text:           text,
      imageUrl:       imageUrl,
      isRead:         isRead ?? this.isRead,
      createdAt:      createdAt,
      replyToId:      replyToId,
      senderUsername:    senderUsername,
      senderDisplayName: senderDisplayName,
      senderAvatarUrl:   senderAvatarUrl,
      replyToMessage: replyToMessage ??
          this.replyToMessage,
    );
  }

  String get senderName =>
      senderDisplayName ?? senderUsername ?? '';

  factory MessageModel.fromJson(
      Map<String, dynamic> json) {
    final sender =
        json['sender'] as Map<String, dynamic>?;
    return MessageModel(
      id:             json['id']              as String,
      conversationId: json['conversation_id'] as String,
      senderId:       json['sender_id']       as String,
      text:           json['text']            as String?,
      imageUrl:       json['image_url']       as String?,
      isRead:         json['is_read']         as bool? ?? false,
      createdAt:      DateTime.parse(
          json['created_at'] as String),
      replyToId:      json['reply_to_id']     as String?,
      senderUsername:
          sender?['username']     as String?,
      senderDisplayName:
          sender?['display_name'] as String?,
      senderAvatarUrl:
          sender?['avatar_url']   as String?,
    );
  }
}