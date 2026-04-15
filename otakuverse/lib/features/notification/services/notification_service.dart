import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/notification/models/notification_model.dart';

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
    int offset = 0,
  }) async {
    final data = await _supabase
        .from('notifications')
        .select(_select)
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .range(offset, offset + 19);

    return (data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  // ─── RÉCUPÉRER UNE notification par ID (pour le realtime) ────────
  Future<NotificationModel?> getById(String id) async {
    final data = await _supabase
        .from('notifications')
        .select(_select)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return NotificationModel.fromJson(data);
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

  // ─── CRÉER une notification (statique — appelé depuis les controllers)
  static Future<void> createNotification({
    required String targetUserId,
    required String type,
    String? postId,
    String? commentId,
  }) async {
    final supabase = Supabase.instance.client;
    final actorId  = supabase.auth.currentUser?.id;

    // Ne pas notifier si acteur == cible ou si non connecté
    if (actorId == null || actorId == targetUserId) return;

    try {
      await supabase.from('notifications').insert({
        'user_id':    targetUserId,
        'actor_id':   actorId,
        'type':       type,
        'post_id':    ?postId,
        'comment_id': ?commentId,
        'is_read':    false,
      });

      // ✅ Push notification (fire-and-forget, l'échec ne bloque pas l'UX)
      _sendPush(targetUserId, type, postId: postId);
    } catch (e) {
      debugPrint('⚠️ createNotification: $e');
    }
  }

  // ─── ENVOYER la push via Edge Function ───────────────────────────
  static void _sendPush(
    String targetUserId,
    String type, {
    String? postId,
  }) {
    final supabase  = Supabase.instance.client;
    final meta      = supabase.auth.currentUser?.userMetadata;
    final actorId   = supabase.auth.currentUser?.id ?? '';
    final actorName =
        (meta?['display_name'] ?? meta?['username'] ?? 'Quelqu\'un') as String;

    final body = switch (type) {
      'like'    => '$actorName a aimé ta publication',
      'comment' => '$actorName a commenté ta publication',
      'reply'   => '$actorName a répondu à ton commentaire',
      'follow'  => '$actorName a commencé à te suivre',
      _         => '$actorName a interagi avec toi',
    };

    // ignore: discarded_futures
    () async {
      try {
        await supabase.functions.invoke('send-notification', body: {
          'userId': targetUserId,
          'title':  'Otakuverse',
          'body':   body,
          'data': {
            'type':    type,
            'user_id': actorId,
            'post_id': ?postId,
          },
        });
      } catch (e) {
        debugPrint('⚠️ Push notification: $e');
      }
    }();
  }
}
