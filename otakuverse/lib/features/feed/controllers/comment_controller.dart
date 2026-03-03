import 'dart:ui';
import 'package:get/get.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';
import 'package:otakuverse/features/feed/services/comment_service.dart';

class CommentController extends GetxController {
  final _service = CommentService();

  // ─── STATE ───────────────────────────────────────────────────────
  final RxList<CommentModel> comments   = <CommentModel>[].obs;
  final RxBool  isLoading               = false.obs;
  final RxBool  isSending               = false.obs;
  final RxString errorMessage           = ''.obs;
  final Rxn<CommentModel> replyingTo    = Rxn<CommentModel>();

  // ─── CHARGER les commentaires ────────────────────────────────────
  Future<void> loadComments(String postId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _service.getComments(postId);
      comments.assignAll(data);
    } catch (e) {
      errorMessage.value = 'Impossible de charger les commentaires';
      print('🔴 Erreur loadComments : $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── ENVOYER un commentaire ───────────────────────────────────────
  Future<bool> sendComment({
    required String postId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    isSending.value = true;
    try {
      final comment = await _service.addComment(
        postId:   postId,
        content:  content,
        parentId: replyingTo.value?.id,
      );

      if (replyingTo.value != null) {
        // ✅ Ajouter la réponse au bon commentaire
        final parentIndex = comments.indexWhere(
            (c) => c.id == replyingTo.value!.id);
        if (parentIndex != -1) {
          final parent  = comments[parentIndex];
          final updated = parent.copyWith(
            replies: [...parent.replies, comment],
          );
          comments[parentIndex] = updated;
        }
      } else {
        // ✅ Ajouter en bas de la liste
        comments.add(comment);
      }

      cancelReply();
      return true;
    } catch (e) {
      print('🔴 Erreur sendComment : $e');
      Get.snackbar(
        'Erreur', '❌ Impossible d\'envoyer le commentaire',
        backgroundColor: const Color(0xFF1A1A1A),
        colorText:        const Color(0xFFFFFFFF),
      );
      return false;
    } finally {
      isSending.value = false;
    }
  }

  // ─── SUPPRIMER un commentaire ────────────────────────────────────
  Future<void> deleteComment(String commentId, {String? parentId}) async {
    try {
      await _service.deleteComment(commentId);

      if (parentId != null) {
        // Supprimer une réponse
        final parentIndex = comments.indexWhere((c) => c.id == parentId);
        if (parentIndex != -1) {
          final parent  = comments[parentIndex];
          final updated = parent.copyWith(
            replies: parent.replies
                .where((r) => r.id != commentId)
                .toList(),
          );
          comments[parentIndex] = updated;
        }
      } else {
        comments.removeWhere((c) => c.id == commentId);
      }
    } catch (e) {
      print('🔴 Erreur deleteComment : $e');
    }
  }

  // ─── LIKER un commentaire ─────────────────────────────────────────
  Future<void> toggleLike(String commentId, {String? parentId}) async {
    // ✅ Optimistic update
    _updateCommentLike(commentId, parentId: parentId);

    try {
      final comment = _findComment(commentId, parentId: parentId);
      if (comment == null) return;

      if (comment.isLiked) {
        await _service.unlikeComment(commentId);
      } else {
        await _service.likeComment(commentId);
      }
    } catch (e) {
      // ✅ Rollback
      _updateCommentLike(commentId, parentId: parentId);
      print('🔴 Erreur toggleLike commentaire : $e');
    }
  }

  // ─── RÉPONDRE à un commentaire ───────────────────────────────────
  void setReplyingTo(CommentModel comment) {
    replyingTo.value = comment;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  // ─── HELPERS PRIVÉS ──────────────────────────────────────────────
  CommentModel? _findComment(String id, {String? parentId}) {
    if (parentId != null) {
      final parent = comments.firstWhereOrNull((c) => c.id == parentId);
      return parent?.replies.firstWhereOrNull((r) => r.id == id);
    }
    return comments.firstWhereOrNull((c) => c.id == id);
  }

  void _updateCommentLike(String commentId, {String? parentId}) {
    if (parentId != null) {
      final parentIndex = comments.indexWhere((c) => c.id == parentId);
      if (parentIndex == -1) return;
      final parent  = comments[parentIndex];
      final replies = parent.replies.map((r) {
        if (r.id != commentId) return r;
        return r.copyWith(
          isLiked:    !r.isLiked,
          likesCount: r.isLiked
              ? r.likesCount - 1
              : r.likesCount + 1,
        );
      }).toList();
      comments[parentIndex] = parent.copyWith(replies: replies);
    } else {
      final index = comments.indexWhere((c) => c.id == commentId);
      if (index == -1) return;
      final c = comments[index];
      comments[index] = c.copyWith(
        isLiked:    !c.isLiked,
        likesCount: c.isLiked
            ? c.likesCount - 1
            : c.likesCount + 1,
      );
    }
  }
}