import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/message/models/conversation_model.dart';

class ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      onTap: onTap,
      leading: Stack(
        children: [
          // Avatar
          ClipOval(
            child: conversation.avatarUrl != null && 
                   conversation.avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: conversation.avatarUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildAvatarPlaceholder(),
                    errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
          
          // Badge online
          if (conversation.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.deepBlack,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.displayNameOrUsername,
              style: GoogleFonts.inter(
                color: AppColors.pureWhite,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w700
                    : FontWeight.w600,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageAt),
            style: GoogleFonts.inter(
              color: conversation.unreadCount > 0
                  ? AppColors.crimsonRed
                  : AppColors.mediumGray,
              fontSize: 12,
              fontWeight: conversation.unreadCount > 0
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          // Icône message envoyé par moi
          if (conversation.lastMessageSender == 'me') ...[
            const Icon(
              HeroiconsOutline.arrowUturnLeft,
              size: 14,
              color: AppColors.mediumGray,
            ),
            const SizedBox(width: 4),
          ],
          
          Expanded(
            child: Text(
              conversation.lastMessage,
              style: GoogleFonts.inter(
                color: conversation.unreadCount > 0
                    ? AppColors.pureWhite
                    : AppColors.mediumGray,
                fontSize: 14,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Badge non lu
          if (conversation.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                color: AppColors.crimsonRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.unreadCount > 99
                      ? '99+'
                      : '${conversation.unreadCount}',
                  style: GoogleFonts.inter(
                    color: AppColors.pureWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.mediumGray,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        HeroiconsOutline.user,
        color: AppColors.pureWhite,
        size: 28,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'maintenant';
    if (difference.inMinutes < 60) return '${difference.inMinutes}min';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}j';
    
    return '${dateTime.day}/${dateTime.month}';
  }
}