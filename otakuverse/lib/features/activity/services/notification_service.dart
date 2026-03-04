import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/activity/models/notification_model.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  static const _select = '''
    *,
    actor:profiles!actor_id(username, display_name, avatar_url),
    post:posts!post_id(media_urls)
  ''';

  // ─── RÉCUPÉRER les notifications ─────────────────────────────────
  Future<List<NotificationModel>> getNotifications({
    int offset = 0, // ✅ Pagination
  }) async {
    final data = await _supabase
        .from('notifications')
        .select(_select)
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .range(offset, offset + 19); // ✅ 20 par page

    return (data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  // ─── COMPTER les non lues ────────────────────────────────────────
  Future<int> getUnreadCount() async {
    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', _uid)
        .eq('is_read', false);

    return (data as List).length;
  }

  // ─── MARQUER UNE notif comme lue ─────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id',      notificationId)
        .eq('user_id', _uid);
  }

  // ─── MARQUER TOUTES comme lues ───────────────────────────────────
  Future<void> markAllAsRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
  }

  // ─── SUPPRIMER une notif ─────────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id',      notificationId)
        .eq('user_id', _uid);
  }
}