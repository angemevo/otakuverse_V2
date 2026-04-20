import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/features/feed/controllers/comment_controller.dart';

/// Barre de saisie des commentaires.
/// Affiche un bandeau "Répondre à X" quand une réponse est en cours.
class CommentsInputBar extends StatelessWidget {
  final CommentController    controller;
  final TextEditingController textController;
  final FocusNode            focusNode;
  final VoidCallback         onSend;

  const CommentsInputBar({
    super.key,
    required this.controller,
    required this.textController,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06), width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left:   12,
        right:  12,
        top:    10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 10
            : MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReplyBanner(),
          _buildInputRow(),
        ],
      ),
    );
  }

  // ─── Bandeau "Répondre à" ────────────────────────────────────────

  Widget _buildReplyBanner() {
    return Obx(() {
      final replying = controller.replyingTo.value;
      if (replying == null) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.only(bottom: 8),
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.reply, color: AppColors.primary, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Répondre à ${replying.displayNameOrUsername}',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: controller.cancelReply,
            child: const Icon(Icons.close,
                color: AppColors.textMuted, size: 16),
          ),
        ]),
      );
    });
  }

  // ─── Ligne input + bouton ────────────────────────────────────────

  Widget _buildInputRow() {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: TextField(
            key: AppKeys.commentInput,
            controller: textController,
            focusNode:  focusNode,
            maxLines:   4,
            minLines:   1,
            maxLength:  500,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:  'Ajouter un commentaire...',
              hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 14),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              counterText: '',
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Obx(() => GestureDetector(
        key: AppKeys.commentSend,
        onTap: controller.isSending.value ? null : onSend,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF4D6D)],
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color:      AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: controller.isSending.value
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
        ),
      )),
    ]);
  }
}
