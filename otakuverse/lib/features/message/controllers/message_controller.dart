import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';

class MessageController extends GetxController {
  final _service  = MessageService();
  final _supabase = Supabase.instance.client;

  final RxList<ConversationModel> conversations =
      <ConversationModel>[].obs;
  final RxBool   isLoading    = false.obs;
  final RxString searchQuery  = ''.obs;

  RealtimeChannel? _channel;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    super.onClose();
  }

  // ─── REALTIME ────────────────────────────────────────────────────
  void _subscribeRealtime() {
    _channel = _supabase
        .channel('messaging_realtime')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'messages',
          callback: (_) => loadConversations(),
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.update,
          schema:   'public',
          table:    'conversations',
          callback: (_) => loadConversations(),
        );
    _channel!.subscribe((status, [error]) {
      debugPrint('📡 Messaging Realtime: $status');
    });
  }

  // ─── CHARGER ─────────────────────────────────────────────────────
  Future<void> loadConversations() async {
    isLoading.value = true;
    try {
      final data =
          await _service.getConversations();
      conversations.assignAll(data);
    } catch (e) {
      debugPrint('❌ loadConversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── FILTRES ─────────────────────────────────────────────────────
  List<ConversationModel> get filtered {
    final q = searchQuery.value
        .toLowerCase().trim();
    if (q.isEmpty) return conversations;
    return conversations.where((c) =>
        c.displayName.toLowerCase().contains(q) ||
        (c.otherUsername ?? '')
            .toLowerCase().contains(q)
    ).toList();
  }

  int get totalUnread => conversations
      .fold(0, (s, c) => s + c.unreadCount);

  // ─── CRÉER / OUVRIR ──────────────────────────────────────────────
  Future<String?> getOrCreateConversation(
      String otherUserId) async {
    return _service
        .getOrCreateConversation(otherUserId);
  }
}
