import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/notification/services/notification_service.dart';
import 'package:otakuverse/features/profile/services/follow_service.dart';

class FollowController extends GetxController {
  final _followService = FollowService();

  // ─── STATE ───────────────────────────────────────────────────────
  final RxMap<String, bool> _followingMap = <String, bool>{}.obs;
  final RxBool isLoading = false.obs;

  // ─── GETTER ──────────────────────────────────────────────────────
  bool isFollowing(String userId) => _followingMap[userId] ?? false;

  // ─── CHARGER ÉTAT INITIAL ────────────────────────────────────────
  Future<void> loadFollowState(String targetUserId) async {
    try {
      final following = await _followService.isFollowing(targetUserId);
      _followingMap[targetUserId] = following;
    } catch (e) {
      debugPrint('⚠️ Erreur loadFollowState : $e');
    }
  }

  // ─── TOGGLE avec optimistic update ───────────────────────────────
  Future<void> toggleFollow(String targetUserId) async {
    // ✅ Optimistic update — UI réagit immédiatement
    final current = _followingMap[targetUserId] ?? false;
    _followingMap[targetUserId] = !current;

    try {
      isLoading.value = true;
      final result = await _followService.toggleFollow(targetUserId);
      _followingMap[targetUserId] = result; // ✅ Sync avec la DB
      // ✅ Notifier l'utilisateur suivi
      if (result) {
        unawaited(NotificationService.createNotification(
          targetUserId: targetUserId,
          type:         'follow',
        ));
      }
    } catch (e) {
      // ✅ Rollback si erreur
      _followingMap[targetUserId] = current;
      debugPrint('🔴 Erreur toggleFollow : $e');
      Get.snackbar(
        'Erreur',
        '❌ Impossible de modifier le suivi',
        backgroundColor: const Color(0xFF1A1A1A),
        colorText:        const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
