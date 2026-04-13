import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';

/// Tuile affichant un commentaire et ses réponses.
/// Gère l'affichage/masquage des réponses en local.
class CommentTile extends StatefulWidget {
  final CommentModel          comment;
  final String                myId;
  final VoidCallback          onReply;
  final VoidCallback          onLike;
  final VoidCallback          onDelete;
  final void Function(String) onReplyLike;
  final void Function(String) onReplyDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.myId,
    required this.onReply,
    required this.onLike,
    required this.onDelete,
    required this.onReplyLike,
    required this.onReplyDelete,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentRow(
            comment:  widget.comment,
            myId:     widget.myId,
            isReply:  false,
            onLike:   widget.onLike,
            onDelete: widget.onDelete,
            onReply:  widget.onReply,
          ),
          if (widget.comment.replies.isNotEmpty) ...[
            _buildToggleRepliesBtn(),
            if (_showReplies) _buildReplies(),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRepliesBtn() {
    return GestureDetector(
      onTap: () => setState(() => _showReplies = !_showReplies),
      child: Padding(
        padding: const EdgeInsets.only(left: 48, top: 8),
        child: Row(children: [
          Container(width: 24, height: 1, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            _showReplies
                ? 'Masquer les réponses'
                : 'Voir ${widget.comment.replies.length} réponse(s)',
            style: GoogleFonts.inter(
              color:      AppColors.textMuted,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildReplies() {
    return Column(
      children: widget.comment.replies.map((reply) => Padding(
        padding: const EdgeInsets.only(left: 48, top: 8),
        child: _CommentRow(
          comment:  reply,
          myId:     widget.myId,
          isReply:  true,
          onLike:   () => widget.onReplyLike(reply.id),
          onDelete: () => widget.onReplyDelete(reply.id),
          onReply:  widget.onReply,
        ),
      )).toList(),
    );
  }
}

// ─── Ligne commentaire ────────────────────────────────────────────────

class _CommentRow extends StatelessWidget {
  final CommentModel comment;
  final String       myId;
  final bool         isReply;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  const _CommentRow({
    required this.comment,
    required this.myId,
    required this.isReply,
    required this.onLike,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = comment.userId == myId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius:          isReply ? 14 : 18,
          backgroundColor: AppColors.bgCard,
          backgroundImage: comment.hasAvatar
              ? NetworkImage(comment.avatarUrl!) : null,
          child: !comment.hasAvatar
              ? Text(
                  comment.displayNameOrUsername[0].toUpperCase(),
                  style: TextStyle(
                    color:      AppColors.textPrimary,
                    fontSize:   isReply ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  comment.displayNameOrUsername,
                  style: GoogleFonts.inter(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   isReply ? 12 : 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(comment.createdAt),
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ]),
              const SizedBox(height: 3),
              Text(
                comment.content,
                style: GoogleFonts.inter(
                  color:    AppColors.textPrimary,
                  fontSize: isReply ? 13 : 14,
                  height:   1.4,
                ),
              ),
              const SizedBox(height: 6),
              _buildActions(isMe),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isMe) {
    return Row(children: [
      GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onLike(); },
        child: Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              comment.isLiked ? Icons.favorite : Icons.favorite_border,
              key:   ValueKey(comment.isLiked),
              color: comment.isLiked ? AppColors.primary : AppColors.textMuted,
              size:  16,
            ),
          ),
          if (comment.likesCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${comment.likesCount}',
              style: GoogleFonts.inter(
                color: comment.isLiked
                    ? AppColors.primary : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(width: 16),
      if (!isReply)
        GestureDetector(
          onTap: onReply,
          child: Text('Répondre',
              style: GoogleFonts.inter(
                color:      AppColors.textMuted,
                fontSize:   12,
                fontWeight: FontWeight.w500,
              )),
        ),
      const Spacer(),
      if (isMe)
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.delete_outline,
              color: AppColors.textMuted, size: 16),
        ),
    ]);
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours   < 24) return '${diff.inHours} h';
    if (diff.inDays    < 7)  return '${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }
}