import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';
import 'package:otakuverse/features/feed/services/comment_service.dart';
import 'package:otakuverse/features/notification/services/notification_service.dart';

class CommentController extends GetxController {
  final _service = CommentService();

  // ─── STATE ───────────────────────────────────────────────────────
  final RxList<CommentModel> comments    = <CommentModel>[].obs;
  final RxBool               isLoading   = false.obs;
  final RxBool               isSending   = false.obs;
  final RxString             errorMessage = ''.obs;
  final Rxn<CommentModel>    replyingTo  = Rxn<CommentModel>();

  String? _currentPostId; // ✅ Sera assigné dans loadComments

  // ─── CHARGER les commentaires ────────────────────────────────────
  Future<void> loadComments(String postId) async {
    _currentPostId     = postId; // ✅ Assignation manquante
    isLoading.value    = true;
    errorMessage.value = '';
    try {
      final data = await _service.getComments(postId);
      comments.assignAll(data);
    } catch (e) {
      errorMessage.value =
          'Impossible de charger les commentaires';
      debugPrint('🔴 Erreur loadComments : $e');
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
        content:  content.trim(),
        parentId: replyingTo.value?.id,
      );

      if (replyingTo.value != null) {
        // ─ Réponse → ajouter dans les replies du parent
        final parentIndex = comments.indexWhere(
            (c) => c.id == replyingTo.value!.id);
        if (parentIndex != -1) {
          final parent  = comments[parentIndex];
          final updated = parent.copyWith(
            replies: [...parent.replies, comment],
          );
          comments[parentIndex] = updated;
        }
        // ✅ Notifier l'auteur du commentaire parent
        unawaited(NotificationService.createNotification(
          targetUserId: replyingTo.value!.userId,
          type:         'reply',
          postId:       postId,
          commentId:    replyingTo.value!.id,
        ));
      } else {
        // ─ Commentaire racine → ajouter en bas
        comments.add(comment);
        // ✅ Notifier l'auteur du post
        final postAuthorId = Get.isRegistered<PostsController>()
            ? Get.find<PostsController>()
                .posts
                .firstWhereOrNull((p) => p.id == postId)
                ?.userId
            : null;
        if (postAuthorId != null) {
          unawaited(NotificationService.createNotification(
            targetUserId: postAuthorId,
            type:         'comment',
            postId:       postId,
            commentId:    comment.id,
          ));
        }
      }

      // ✅ Incrémenter commentsCount dans le feed
      _incrementPostCommentsCount(postId);

      cancelReply();
      return true;
    } catch (e) {
      debugPrint('🔴 Erreur sendComment : $e');
      return false;
    } finally {
      isSending.value = false;
    }
  }

  // ─── SUPPRIMER un commentaire ────────────────────────────────────
  Future<void> deleteComment(
    String commentId, {
    String? parentId,
  }) async {
    try {
      await _service.deleteComment(commentId);

      if (parentId != null) {
        // ─ Supprimer une réponse
        final parentIndex =
            comments.indexWhere((c) => c.id == parentId);
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
        // ─ Supprimer un commentaire racine
        comments.removeWhere((c) => c.id == commentId);
      }

      // ✅ Décrémenter commentsCount dans le feed
      if (_currentPostId != null) {
        _decrementPostCommentsCount(_currentPostId!);
      }

    } catch (e) {
      debugPrint('🔴 Erreur deleteComment : $e');
      // ✅ Rollback — recharger les commentaires
      if (_currentPostId != null) {
        await loadComments(_currentPostId!);
      }
    }
  }

  // ─── LIKER un commentaire ─────────────────────────────────────────
  Future<void> toggleLike(
    String commentId, {
    String? parentId,
  }) async {
    // ✅ Optimistic update
    _updateCommentLike(commentId, parentId: parentId);

    try {
      final comment =
          _findComment(commentId, parentId: parentId);
      if (comment == null) return;

      if (comment.isLiked) {
        await _service.unlikeComment(commentId);
      } else {
        await _service.likeComment(commentId);
      }
    } catch (e) {
      // ✅ Rollback
      _updateCommentLike(commentId, parentId: parentId);
      debugPrint('🔴 Erreur toggleLike commentaire : $e');
    }
  }

  // ─── RÉPONDRE ────────────────────────────────────────────────────
  void setReplyingTo(CommentModel comment) {
    replyingTo.value = comment;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  // ─── HELPERS PRIVÉS ──────────────────────────────────────────────

  // ✅ Méthode définie — manquait dans ton code
  void _incrementPostCommentsCount(String postId) {
    if (Get.isRegistered<PostsController>()) {
      Get.find<PostsController>()
          .incrementCommentsCount(postId);
    }
  }

  // ✅ Méthode définie — manquait dans ton code
  void _decrementPostCommentsCount(String postId) {
    if (Get.isRegistered<PostsController>()) {
      Get.find<PostsController>()
          .decrementCommentsCount(postId);
    }
  }

  CommentModel? _findComment(
    String id, {
    String? parentId,
  }) {
    if (parentId != null) {
      final parent =
          comments.firstWhereOrNull((c) => c.id == parentId);
      return parent?.replies
          .firstWhereOrNull((r) => r.id == id);
    }
    return comments.firstWhereOrNull((c) => c.id == id);
  }

  void _updateCommentLike(
    String commentId, {
    String? parentId,
  }) {
    if (parentId != null) {
      final parentIndex =
          comments.indexWhere((c) => c.id == parentId);
      if (parentIndex == -1) return;
      final parent  = comments[parentIndex];
      final replies = parent.replies.map((r) {
        if (r.id != commentId) return r;
        return r.copyWith(
          isLiked:    !r.isLiked,
          likesCount: r.isLiked
              ? (r.likesCount - 1).clamp(0, 999999)
              : r.likesCount + 1,
        );
      }).toList();
      comments[parentIndex] =
          parent.copyWith(replies: replies);
    } else {
      final index =
          comments.indexWhere((c) => c.id == commentId);
      if (index == -1) return;
      final c = comments[index];
      comments[index] = c.copyWith(
        isLiked:    !c.isLiked,
        likesCount: c.isLiked
            ? (c.likesCount - 1).clamp(0, 999999)
            : c.likesCount + 1,
      );
    }
  }
}
