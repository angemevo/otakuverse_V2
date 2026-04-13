import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import '../models/message_model.dart';

class ChatReplyPreview extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onCancel;

  const ChatReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.darkGray,
        border: Border(
          top: BorderSide(
              color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // ─ Barre colorée ─────────────────────────────────
          Container(
            width: 3, height: 36,
            color: AppColors.crimsonRed,
          ),
          const SizedBox(width: 10),

          // ─ Contenu ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName.isNotEmpty
                      ? message.senderName
                      : 'Utilisateur',
                  style: GoogleFonts.inter(
                    color:      AppColors.crimsonRed,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.imageUrl != null
                      ? '📷 Photo'
                      : message.text ?? '',
                  style: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ─ Fermer ────────────────────────────────────────
          GestureDetector(
            onTap: onCancel,
            child: const Icon(
              Icons.close,
              color: AppColors.mediumGray,
              size:  18,
            ),
          ),
        ],
      ),
    );
  }
}