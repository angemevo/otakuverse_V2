import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/message/widgets/date_separator.dart';
import 'package:otakuverse/features/message/widgets/message_bubble.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatMessagesList extends StatelessWidget {
  final List<MessageModel>             messages;
  final bool                           isLoading;
  final bool                           hasMore;
  final String                         uid;
  final ConversationModel              conv;
  final ScrollController               scrollCtrl;
  final bool Function(DateTime, DateTime) isSameDay;
  final VoidCallback                   onLoadMore;
  final ValueChanged<MessageModel>     onReply;

  const ChatMessagesList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.hasMore,
    required this.uid,
    required this.conv,
    required this.scrollCtrl,
    required this.isSameDay,
    required this.onLoadMore,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (messages.isEmpty) return _EmptyChat(conv: conv);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification &&
            scrollCtrl.position.pixels <= 100 &&
            hasMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (_, i) {
          final msg  = messages[i];
          final isMe = msg.senderId == uid;
          final prev = i > 0 ? messages[i - 1] : null;
          final next = i < messages.length - 1
              ? messages[i + 1] : null;

          return Column(children: [
            if (prev == null ||
                !isSameDay(prev.createdAt, msg.createdAt))
              DateSeparator(date: msg.createdAt),
            MessageBubble(
              message:    msg,
              isMe:       isMe,
              showAvatar: !isMe &&
                  (next == null || next.senderId != msg.senderId),
              isFirst:    prev == null ||
                  prev.senderId != msg.senderId,
              isLast:     next == null ||
                  next.senderId != msg.senderId,
              onReply:    () => onReply(msg),
            ),
          ]);
        },
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final ConversationModel conv;
  const _EmptyChat({required this.conv});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CachedAvatar(
            url:            conv.displayAvatar,
            radius:         36,
            fallbackLetter: conv.displayName,
          ),
          const SizedBox(height: 16),
          Text(
            conv.displayName,
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize:   18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commence la conversation !',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
