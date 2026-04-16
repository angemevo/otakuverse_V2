import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/notification/models/notification_model.dart';
import 'package:otakuverse/features/notification/services/notification_service.dart';

class NotificationController extends GetxController {
  final _service = NotificationService();

  // ─── State ───────────────────────────────────────────────────────
  final RxList<NotificationModel> notifications =
      <NotificationModel>[].obs;
  final RxBool isLoading     = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore       = true.obs;
  final RxInt  unreadCount   = 0.obs;

  // ─── Pagination ──────────────────────────────────────────────────
  int              _offset   = 0;
  static const int _pageSize = 20;

  // ─── Realtime ────────────────────────────────────────────────────
  RealtimeChannel? _channel;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    _subscribeToRealtime();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    super.onClose();
  }

  // ─── REALTIME — nouvelles notifications ──────────────────────────
  void _subscribeToRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    _channel = Supabase.instance.client
        .channel('notifications:$uid')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'notifications',
          // Filtre serveur : seules les notifs de cet utilisateur
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  uid,
          ),
          callback: (payload) => _onNewNotification(payload),
        )
        .subscribe();
  }

  Future<void> _onNewNotification(
      PostgresChangePayload payload) async {
    // Vérifier que la notif appartient bien à l'utilisateur courant
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final notifUserId = payload.newRecord['user_id'] as String?;
    if (notifUserId != uid) return;

    final id = payload.newRecord['id'] as String?;
    if (id == null) return;

    try {
      // Récupérer la notif complète avec les JOINs (actor + post)
      final notif = await _service.getById(id);
      if (notif == null) return;

      // Éviter les doublons si loadNotifications() a déjà chargé la notif
      if (notifications.any((n) => n.id == id)) return;

      notifications.insert(0, notif);
      unreadCount.value++;
    } catch (e) {
      debugPrint('🔴 _onNewNotification: $e');
    }
  }

  // ─── CHARGER (première page) ─────────────────────────────────────
  Future<void> loadNotifications() async {
    isLoading.value = true;
    _offset         = 0;
    hasMore.value   = true;

    try {
      final data =
          await _service.getNotifications(offset: 0);
      notifications.assignAll(data);

      // ✅ Compter les non lues
      unreadCount.value =
          data.where((n) => !n.isRead).length;

      if (data.length < _pageSize) hasMore.value = false;
      _offset = data.length;

    } catch (e) {
      debugPrint('🔴 Erreur notifications : $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CHARGER la page suivante ────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final data = await _service.getNotifications(
          offset: _offset);

      if (data.isEmpty || data.length < _pageSize) {
        hasMore.value = false;
      }

      notifications.addAll(data);
      _offset += data.length;

      // Ajouter les non-lues de la nouvelle page au compteur
      final newUnread = data.where((n) => !n.isRead).length;
      if (newUnread > 0) unreadCount.value += newUnread;

    } catch (e) {
      debugPrint('🔴 loadMore notifications: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── MARQUER UNE comme lue ───────────────────────────────────────
  Future<void> markAsRead(String notifId) async {
    final index =
        notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    // ✅ Optimistic update
    final notif = notifications[index];
    if (!notif.isRead) {
      notifications[index] = notif.copyWith(isRead: true);
      unreadCount.value =
          (unreadCount.value - 1).clamp(0, 999);
    }

    try {
      await _service.markAsRead(notifId);
    } catch (e) {
      // ✅ Rollback
      notifications[index] = notif;
      unreadCount.value++;
      debugPrint('🔴 markAsRead: $e');
    }
  }

  // ─── MARQUER TOUTES comme lues ───────────────────────────────────
  Future<void> markAllAsRead() async {
    // ✅ Optimistic update
    final updated = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifications.assignAll(updated);
    unreadCount.value = 0;

    try {
      await _service.markAllAsRead();
    } catch (e) {
      // ✅ Rollback
      await loadNotifications();
      debugPrint('🔴 markAllAsRead: $e');
    }
  }

  // ─── SUPPRIMER ───────────────────────────────────────────────────
  Future<void> deleteNotification(String notifId) async {
    final index =
        notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    // ✅ Optimistic update
    final notif = notifications[index];
    notifications.removeAt(index);
    if (!notif.isRead) {
      unreadCount.value =
          (unreadCount.value - 1).clamp(0, 999);
    }

    try {
      await _service.deleteNotification(notifId);
    } catch (e) {
      // ✅ Rollback
      notifications.insert(index, notif);
      if (!notif.isRead) unreadCount.value++;
      debugPrint('🔴 deleteNotification: $e');
    }
  }
}
