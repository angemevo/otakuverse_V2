import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/controllers/comment_controller.dart';
import 'package:otakuverse/features/feed/screens/comments/widgets/comment_tile.dart';
import 'package:otakuverse/features/feed/screens/comments/widgets/comments_input_bar.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Fonction d'ouverture ─────────────────────────────────────────────

void showCommentsSheet(
  BuildContext context, {
  required String postId,
  required String postAuthor,
}) {
  if (Get.isRegistered<CommentController>()) {
    Get.delete<CommentController>();
  }
  showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    enableDrag:         true,
    builder: (_) => CommentsSheet(postId: postId, postAuthor: postAuthor),
  );
}

// ─── Sheet ───────────────────────────────────────────────────────────

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
  late final CommentController _ctrl;
  final _textController   = TextEditingController();
  final _focusNode        = FocusNode();
  final _scrollController = ScrollController();

  String get _myId => Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(CommentController());
    _ctrl.loadComments(widget.postId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final ok = await _ctrl.sendComment(
        postId: widget.postId, content: text);
    if (!ok) return;

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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      expand:           false,
      snap:             true,
      snapSizes:        const [0.6, 0.95],
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color:        Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildList(scrollCtrl)),
          CommentsInputBar(
            controller:     _ctrl,
            textController: _textController,
            focusNode:      _focusNode,
            onSend:         _send,
          ),
        ]),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(children: [
      Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40, height: 4,
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          Text('Commentaires',
              style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize:   16,
              )),
          const SizedBox(width: 8),
          Obx(() {
            final total = _ctrl.comments.fold<int>(
                0, (s, c) => s + 1 + c.replies.length);
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:        AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$total',
                  style: GoogleFonts.inter(
                      color:    AppColors.textMuted,
                      fontSize: 12)),
            );
          }),
        ]),
      ),
      Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
    ]);
  }

  // ─── Liste ───────────────────────────────────────────────────────

  Widget _buildList(ScrollController scrollCtrl) {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      if (_ctrl.comments.isEmpty) {
        return _buildEmpty();
      }
      return ListView.builder(
        controller: scrollCtrl,
        padding:    const EdgeInsets.symmetric(vertical: 8),
        itemCount:  _ctrl.comments.length,
        itemBuilder: (_, i) {
          final comment = _ctrl.comments[i];
          return CommentTile(
            comment:       comment,
            myId:          _myId,
            onReply:       () {
              _ctrl.setReplyingTo(comment);
              _focusNode.requestFocus();
            },
            onLike:        () => _ctrl.toggleLike(comment.id),
            onDelete:      () => _ctrl.deleteComment(comment.id),
            onReplyLike:   (id) =>
                _ctrl.toggleLike(id, parentId: comment.id),
            onReplyDelete: (id) =>
                _ctrl.deleteComment(id, parentId: comment.id),
          );
        },
      );
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.chat_bubble_outline,
            color: AppColors.textMuted, size: 48),
        const SizedBox(height: 12),
        Text('Aucun commentaire',
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontSize:   16,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        Text('Sois le premier à commenter !',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13)),
      ]),
    );
  }
}
