import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessageService {
  final _supabase = Supabase.instance.client;
  String get _uid => _supabase.auth.currentUser!.id;

  // ─── CONVERSATIONS ───────────────────────────────────────────────
  Future<List<ConversationModel>>
    getConversations() async {
    try {
      final uid = _supabase.auth.currentUser!.id;

      // ✅ Récupérer mes conversation_ids
      final myParts = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      final myIds = (myParts as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      if (myIds.isEmpty) return [];

      // ✅ Charger les conversations avec TOUS les participants
      final data = await _supabase
          .from('conversations')
          .select('''
            id, type, name, avatar_url,
            last_message_text, last_message_at,
            conversation_participants(
              user_id,
              last_read_at,
              profiles(
                user_id,
                username,
                display_name,
                avatar_url
              )
            )
          ''')
          .inFilter('id', myIds)
          .order('last_message_at',
              ascending: false, nullsFirst: false);

      return (data as List).map((json) {
        return _mapConversation(
            json as Map<String, dynamic>, uid);
      }).toList();
    } catch (e) {
      debugPrint('❌ getConversations: $e');
      return [];
    }
  }

  // ─── MAPPER UNE CONVERSATION ─────────────────────────────────────
  ConversationModel _mapConversation(
    Map<String, dynamic> json, String uid) {

    final parts = (json['conversation_participants']
            as List? ?? [])
        .cast<Map<String, dynamic>>();

    debugPrint('📋 Participants: ${parts.length}');
    for (final p in parts) {
      debugPrint(
          '  → user_id: ${p['user_id']} '
          'profile: ${p['profiles']}');
    }

    // ✅ L'autre participant
    final other = parts.firstWhere(
      (p) => p['user_id'] != uid,
      orElse: () => <String, dynamic>{},
    );

    final otherProfile =
        other['profiles'] as Map<String, dynamic>?;

    debugPrint(
        '📋 otherProfile: $otherProfile');

    // ✅ Calculer non lus via last_read_at
    final myPart = parts.firstWhere(
      (p) => p['user_id'] == uid,
      orElse: () => <String, dynamic>{},
    );

    final lastReadAt = myPart['last_read_at'] != null
        ? DateTime.parse(
            myPart['last_read_at'] as String)
        : null;

    final lastMsgAt =
        json['last_message_at'] != null
            ? DateTime.parse(
                json['last_message_at'] as String)
            : null;

    final isUnread = lastMsgAt != null &&
        (lastReadAt == null ||
            lastMsgAt.isAfter(lastReadAt));

    return ConversationModel(
      id:    json['id']   as String,
      type:  json['type'] as String? ?? 'direct',
      name:      json['name']       as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastMessageText:
          json['last_message_text'] as String?,
      lastMessageAt: lastMsgAt,
      unreadCount:   isUnread ? 1 : 0,
      // ✅ Depuis le profil jointé de l'autre participant
      otherUserId:
          otherProfile?['user_id']      as String?,
      otherUsername:
          otherProfile?['username']     as String?,
      otherDisplayName:
          otherProfile?['display_name'] as String?,
      otherAvatarUrl:
          otherProfile?['avatar_url']   as String?,
    );
  }

  // ─── CRÉER OU RÉCUPÉRER UNE CONVERSATION ─────────────────────────
  Future<String?> getOrCreateConversation(
    String otherUserId) async {
    try {
      // ✅ S'assurer que la session est valide
      final session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint('❌ Aucune session');
        return null;
      }

      // ✅ Refresh si expirée
      if (session.isExpired) {
        await _supabase.auth.refreshSession();
      }

      final uid = _supabase.auth.currentUser!.id;
      debugPrint('🔵 UID: $uid');
      debugPrint('🔵 otherUserId: $otherUserId');

      // ─ Chercher conversation existante ───────────────────────────
      final myParts = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      final myIds = (myParts as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      debugPrint('🔵 Mes convs: ${myIds.length}');

      if (myIds.isNotEmpty) {
        final common = await _supabase
            .from('conversation_participants')
            .select('conversation_id')
            .eq('user_id', otherUserId)
            .inFilter('conversation_id', myIds);

        for (final c in common as List) {
          final convId =
              c['conversation_id'] as String;
          final conv = await _supabase
              .from('conversations')
              .select('id, type')
              .eq('id', convId)
              .eq('type', 'direct')
              .maybeSingle();

          if (conv != null) {
            debugPrint('✅ Conv existante: $convId');
            return conv['id'] as String;
          }
        }
      }

      // ─ Créer la conversation ──────────────────────────────────────
      debugPrint('🔵 Création conv...');

      // ✅ Test minimal — juste id et type
      final newConv = await _supabase
          .from('conversations')
          .insert({
            'type': 'direct',
            'created_by': uid,
          })
          .select('id')
          .single();

      final convId = newConv['id'] as String;
      debugPrint('✅ Conv créée: $convId');

      // ─ Ajouter participants ───────────────────────────────────────
      await _supabase
          .from('conversation_participants')
          .insert([
            {'conversation_id': convId, 'user_id': uid},
            {'conversation_id': convId, 'user_id': otherUserId},
          ]);

      debugPrint('✅ Participants ajoutés');
      return convId;
    } catch (e, s) {
      debugPrint('❌ getOrCreateConversation: $e');
      debugPrint('❌ Stack: $s');
      return null;
    }
  }

  // ─── MESSAGES D'UNE CONVERSATION ─────────────────────────────────
  Future<List<MessageModel>> getMessages(
    String conversationId,
    {int limit = 50, int offset = 0}) async {
  try {
    final data = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles(
            user_id, username,
            display_name, avatar_url
          )
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final messages = (data as List)
        .map((m) => MessageModel.fromJson(
            m as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();

    // ✅ Charger les messages originaux des replies
    final replyIds = messages
        .where((m) => m.replyToId != null)
        .map((m) => m.replyToId!)
        .toSet()
        .toList();

    if (replyIds.isEmpty) return messages;

    final repliesData = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles(
            user_id, username,
            display_name, avatar_url
          )
        ''')
        .inFilter('id', replyIds);

    // ✅ Map id → MessageModel
    final repliesMap = {
      for (final r in repliesData as List)
        (r as Map<String, dynamic>)['id'] as String:
            MessageModel.fromJson(r),
    };

    // ✅ Associer chaque message à son original
    return messages.map((m) {
      if (m.replyToId != null &&
          repliesMap.containsKey(m.replyToId)) {
        return m.copyWith(
          replyToMessage: repliesMap[m.replyToId],
        );
      }
      return m;
    }).toList();
  } catch (e) {
    debugPrint('❌ getMessages: $e');
    return [];
  }
}

  // ─── ENVOYER UN MESSAGE ──────────────────────────────────────────
  Future<MessageModel?> sendMessage({
    required String conversationId,
    String?         text,
    String?         imageUrl,
    String?         replyToId,
  }) async {
    try {
      final data = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id':       _uid,
            if (text      != null) 'text':        text,
            if (imageUrl  != null) 'image_url':   imageUrl,
            if (replyToId != null) 'reply_to_id': replyToId,
          })
          .select('''
            *,
            sender:profiles(
              user_id, username,
              display_name, avatar_url
            )
          ''')
          .single();

      debugPrint('✅ sendMessage OK: ${data['id']}');
      return MessageModel.fromJson(
          data);
    } catch (e) {
      debugPrint('❌ sendMessage: $e');
      return null;
    }
  }
  // ─── MARQUER COMME LU ────────────────────────────────────────────
  Future<void> markAsRead(
      String conversationId) async {
    try {
      // ✅ Marquer les messages comme lus
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', _uid)
          .eq('is_read', false);

      // ✅ Mettre à jour last_read_at
      await _supabase
          .from('conversation_participants')
          .update({
            'last_read_at':
                DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', _uid);
    } catch (e) {
      debugPrint('❌ markAsRead: $e');
    }
  }
}