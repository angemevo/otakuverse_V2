import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode             focusNode;
  final bool                  isSending;
  final VoidCallback          onSend;
  final VoidCallback          onImage;

  const ChatInput({
    super.key,
    required this.textCtrl,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left:   12, right: 12,
        top:    8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ─ Bouton image ────────────────────────────────────
          GestureDetector(
            onTap: onImage,
            child: Container(
              width: 38, height: 38,
              margin: const EdgeInsets.only(right: 8, bottom: 1),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.image_outlined,
                  color: AppColors.textMuted, size: 20),
            ),
          ),
          // ─ Champ texte ─────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color:        AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListenableBuilder(
                listenable: textCtrl,
                builder: (_, __) => TextField(
                  key: AppKeys.chatInput,
                  controller: textCtrl,
                  focusNode:  focusNode,
                  maxLines:   null,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 15),
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText:  'Message...',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 15),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ─ Bouton envoyer ──────────────────────────────────
          ListenableBuilder(
            listenable: textCtrl,
            builder: (_, __) {
              final hasText = textCtrl.text.trim().isNotEmpty;
              return GestureDetector(
                key: AppKeys.chatSend,
                onTap: onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.primary
                        : AppColors.bgCard,
                    shape: BoxShape.circle,
                  ),
                  child: isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: hasText
                              ? Colors.white
                              : AppColors.textMuted,
                          size: 18,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
