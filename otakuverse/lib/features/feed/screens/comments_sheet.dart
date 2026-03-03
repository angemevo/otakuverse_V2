import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/controllers/comment_controller.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── FONCTION D'OUVERTURE ─────────────────────────────────────────────
// Appelle simplement showCommentsSheet(context, postId, postAuthor)
// depuis n'importe où dans l'app
void showCommentsSheet(
  BuildContext context, {
  required String postId,
  required String postAuthor,
}) {
  showModalBottomSheet(
    context:           context,
    isScrollControlled: true,    // ✅ Hauteur dynamique
    backgroundColor:   Colors.transparent,
    enableDrag:        true,
    builder: (_) => CommentsSheet(
      postId:     postId,
      postAuthor: postAuthor,
    ),
  );
}

// ─── SHEET ───────────────────────────────────────────────────────────
class CommentsSheet extends StatefulWidget {
  final String postId;
  final String postAuthor;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.postAuthor,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller     = Get.put(CommentController());
  final _textController = TextEditingController();
  final _focusNode      = FocusNode();
  final _scrollController = ScrollController();

  String get _myId =>
      Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _controller.loadComments(widget.postId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── ENVOYER ─────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final success = await _controller.sendComment(
      postId:  widget.postId,
      content: text,
    );

    if (success) {
      _textController.clear();
      _focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 150));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,  // ✅ 60% de l'écran au départ
      minChildSize:     0.4,  // ✅ 40% minimum
      maxChildSize:     0.95, // ✅ 95% maximum
      expand:           false,
      snap:             true,
      snapSizes:        const [0.6, 0.95],
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ─ Handle + Header ────────────────────────────────────
            _buildHeader(),

            // ─ Liste commentaires ─────────────────────────────────
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.crimsonRed),
                  );
                }

                if (_controller.comments.isEmpty) {
                  return _buildEmpty();
                }

                return ListView.builder(
                  controller:  scrollController,
                  padding:     const EdgeInsets.only(
                      top: 8, bottom: 8),
                  itemCount:   _controller.comments.length,
                  itemBuilder: (_, index) {
                    final comment = _controller.comments[index];
                    return _CommentTile(
                      comment:       comment,
                      myId:          _myId,
                      onReply:       () {
                        _controller.setReplyingTo(comment);
                        _focusNode.requestFocus();
                      },
                      onLike:        () =>
                          _controller.toggleLike(comment.id),
                      onDelete:      () =>
                          _controller.deleteComment(comment.id),
                      onReplyLike:   (id) => _controller.toggleLike(
                          id, parentId: comment.id),
                      onReplyDelete: (id) => _controller.deleteComment(
                          id, parentId: comment.id),
                    );
                  },
                );
              }),
            ),

            // ─ Barre de saisie ────────────────────────────────────
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width:  40, height: 4,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Titre + nombre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(children: [
            Text(
              'Commentaires',
              style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize:   16,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:        AppColors.darkGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_controller.comments.length}',
                style: GoogleFonts.inter(
                  color:    AppColors.mediumGray,
                  fontSize: 12,
                ),
              ),
            )),
          ]),
        ),

        Divider(
          height: 1,
          color:  Colors.white.withValues(alpha: 0.06),
        ),
      ],
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline,
              color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text('Aucun commentaire',
              style: GoogleFonts.poppins(
                  color:      AppColors.pureWhite,
                  fontSize:   16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Sois le premier à commenter !',
              style: GoogleFonts.inter(
                  color:    AppColors.mediumGray,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ─── INPUT BAR ───────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
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
          // ─ Bandeau "répondre à" ──────────────────────────────
          Obx(() {
            final replying = _controller.replyingTo.value;
            if (replying == null) return const SizedBox.shrink();
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:   const EdgeInsets.only(bottom: 8),
              padding:  const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColors.darkGray,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.crimsonRed.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.reply,
                    color: AppColors.crimsonRed, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Répondre à ${replying.displayNameOrUsername}',
                    style: GoogleFonts.inter(
                        color:    AppColors.mediumGray,
                        fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: _controller.cancelReply,
                  child: const Icon(Icons.close,
                      color: AppColors.mediumGray, size: 16),
                ),
              ]),
            );
          }),

          // ─ Champ + bouton ────────────────────────────────────
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:        AppColors.darkGray,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode:  _focusNode,
                  maxLines:   4,
                  minLines:   1,
                  maxLength:  500,
                  style: GoogleFonts.inter(
                      color: AppColors.pureWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    hintStyle: GoogleFonts.inter(
                        color:    AppColors.mediumGray,
                        fontSize: 14),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ─ Bouton envoyer ───────────────────────────────────
            Obx(() => GestureDetector(
              onTap: _controller.isSending.value ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.crimsonRed, Color(0xFFFF4D6D)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color:      AppColors.crimsonRed
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: _controller.isSending.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            )),
          ]),
        ],
      ),
    );
  }
}

// ─── COMMENT TILE ────────────────────────────────────────────────────
class _CommentTile extends StatefulWidget {
  final CommentModel          comment;
  final String                myId;
  final VoidCallback          onReply;
  final VoidCallback          onLike;
  final VoidCallback          onDelete;
  final void Function(String) onReplyLike;
  final void Function(String) onReplyDelete;

  const _CommentTile({
    required this.comment,
    required this.myId,
    required this.onReply,
    required this.onLike,
    required this.onDelete,
    required this.onReplyLike,
    required this.onReplyDelete,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Commentaire principal ──────────────────────────────
          _buildCommentRow(
            comment:  widget.comment,
            isReply:  false,
            onLike:   widget.onLike,
            onDelete: widget.onDelete,
          ),

          // ─ Bouton voir réponses ───────────────────────────────
          if (widget.comment.replies.isNotEmpty)
            GestureDetector(
              onTap: () =>
                  setState(() => _showReplies = !_showReplies),
              child: Padding(
                padding: const EdgeInsets.only(left: 48, top: 8),
                child: Row(children: [
                  Container(
                      width: 24, height: 1,
                      color: AppColors.mediumGray),
                  const SizedBox(width: 8),
                  Text(
                    _showReplies
                        ? 'Masquer les réponses'
                        : 'Voir ${widget.comment.replies.length} réponse(s)',
                    style: GoogleFonts.inter(
                      color:      AppColors.mediumGray,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),

          // ─ Réponses ───────────────────────────────────────────
          if (_showReplies)
            ...widget.comment.replies.map((reply) => Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: _buildCommentRow(
                comment:  reply,
                isReply:  true,
                onLike:   () => widget.onReplyLike(reply.id),
                onDelete: () => widget.onReplyDelete(reply.id),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildCommentRow({
    required CommentModel comment,
    required bool         isReply,
    required VoidCallback onLike,
    required VoidCallback onDelete,
  }) {
    final isMe = comment.userId == widget.myId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─ Avatar ──────────────────────────────────────────────
        CircleAvatar(
          radius:          isReply ? 14 : 18,
          backgroundColor: AppColors.darkGray,
          backgroundImage: comment.hasAvatar
              ? NetworkImage(comment.avatarUrl!)
              : null,
          child: !comment.hasAvatar
              ? Text(
                  comment.displayNameOrUsername[0].toUpperCase(),
                  style: TextStyle(
                    color:      AppColors.pureWhite,
                    fontSize:   isReply ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),

        // ─ Contenu ─────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  comment.displayNameOrUsername,
                  style: GoogleFonts.inter(
                    color:      AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                    fontSize:   isReply ? 12 : 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(comment.createdAt),
                  style: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 11,
                  ),
                ),
              ]),
              const SizedBox(height: 3),

              Text(
                comment.content,
                style: GoogleFonts.inter(
                  color:    AppColors.pureWhite,
                  fontSize: isReply ? 13 : 14,
                  height:   1.4,
                ),
              ),
              const SizedBox(height: 6),

              Row(children: [
                // Like
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onLike();
                  },
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        key:   ValueKey(comment.isLiked),
                        color: comment.isLiked
                            ? AppColors.crimsonRed
                            : AppColors.mediumGray,
                        size:  16,
                      ),
                    ),
                    if (comment.likesCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likesCount}',
                        style: GoogleFonts.inter(
                          color:    comment.isLiked
                              ? AppColors.crimsonRed
                              : AppColors.mediumGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(width: 16),

                if (!isReply)
                  GestureDetector(
                    onTap: widget.onReply,
                    child: Text('Répondre',
                        style: GoogleFonts.inter(
                          color:      AppColors.mediumGray,
                          fontSize:   12,
                          fontWeight: FontWeight.w500,
                        )),
                  ),

                const Spacer(),

                if (isMe)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.mediumGray, size: 16),
                  ),
              ]),
            ],
          ),
        ),
      ],
    );
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