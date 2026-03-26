import 'package:get/get.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
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
      print('🔴 Erreur notifications : $e');
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

    } catch (e) {
      print('🔴 Erreur loadMore notifications : $e');
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
      print('🔴 Erreur markAsRead : $e');
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
      print('🔴 Erreur markAllAsRead : $e');
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
      print('🔴 Erreur deleteNotification : $e');
    }
  }
}