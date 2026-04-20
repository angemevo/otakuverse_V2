import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/features/message/controllers/message_controller.dart';
import 'package:otakuverse/features/message/widgets/chat_app_bar.dart';
import 'package:otakuverse/features/message/widgets/chat_input.dart';
import 'package:otakuverse/features/message/widgets/chat_messages_list.dart';
import 'package:otakuverse/features/message/widgets/chat_reply_preview.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conv;
  const ChatScreen({super.key, required this.conv});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver {

  final _service    = MessageService();
  final _supabase   = Supabase.instance.client;
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  String get _uid => _supabase.auth.currentUser!.id;

  List<MessageModel> _messages  = [];
  bool               _isLoading = true;
  bool               _isSending = false;
  bool               _hasMore   = true;
  MessageModel?      _replyTo;

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _subscribeRealtime();
    _markAsRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _markAsRead();
  }

  // ─── Realtime ────────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel = _supabase
        .channel('chat:${widget.conv.id}')

        // ✅ Nouveau message
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'messages',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value:  widget.conv.id,
          ),
          callback: (payload) async {
            final newId = payload.newRecord['id'] as String?;
            if (newId == null) return;

            if (_messages.any((m) => m.id == newId)) return;

            final data = await _supabase
                .from('messages')
                .select('*, sender:profiles(user_id, username, display_name, avatar_url)')
                .eq('id', newId)
                .single();

            MessageModel msg = MessageModel.fromJson(data);

            // ✅ Charger le message original si c'est une réponse
            if (msg.replyToId != null) {
              try {
                final replyData = await _supabase
                    .from('messages')
                    .select('*, sender:profiles(user_id, username, display_name, avatar_url)')
                    .eq('id', msg.replyToId!)
                    .maybeSingle();
                if (replyData != null) {
                  msg = msg.copyWith(
                    replyToMessage: MessageModel.fromJson(replyData),
                  );
                }
              } catch (e) {
                debugPrint('⚠️ Reply fetch error: $e');
              }
            }

            if (!mounted) return;
            setState(() => _messages.add(msg));
            _scrollToBottom();
            if (msg.senderId != _uid) _markAsRead();
          },
        )

        // ✅ Mise à jour is_read (ticks WhatsApp)
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'messages',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value:  widget.conv.id,
          ),
          callback: (payload) {
            final updatedId = payload.newRecord['id'] as String?;
            final isRead    = payload.newRecord['is_read'] as bool? ?? false;
            if (updatedId == null || !mounted) return;

            setState(() {
              final idx = _messages.indexWhere((m) => m.id == updatedId);
              if (idx != -1) {
                _messages[idx] = _messages[idx].copyWith(isRead: isRead);
              }
            });
          },
        )
        .subscribe();
  }

  // ─── Chargement ──────────────────────────────────────────────────

  Future<void> _loadMessages({bool more = false}) async {
    if (!more) setState(() => _isLoading = true);

    final offset = more ? _messages.length : 0;
    final data   = await _service.getMessages(
      widget.conv.id, limit: 50, offset: offset);

    if (!mounted) return;
    setState(() {
      _messages  = more ? [...data, ..._messages] : data;
      _hasMore   = data.length >= 50;
      _isLoading = false;
    });
    if (!more) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  // ─── Marquer lu ──────────────────────────────────────────────────

  Future<void> _markAsRead() async {
    await _service.markAsRead(widget.conv.id);
    if (!mounted) return;
    setState(() {
      _messages = _messages.map((m) =>
        m.senderId != _uid && !m.isRead
            ? m.copyWith(isRead: true)
            : m,
      ).toList();
    });
    if (Get.isRegistered<MessageController>()) {
      Get.find<MessageController>().loadConversations();
    }
  }

  // ─── Envoyer texte ───────────────────────────────────────────────

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();
    _textCtrl.clear();

    final replyId  = _replyTo?.id;
    final replyMsg = _replyTo;
    setState(() => _replyTo = null);

    final sent = await _service.sendMessage(
      conversationId: widget.conv.id,
      text:           text,
      replyToId:      replyId,
    );

    if (sent != null && mounted) {
      final msgWithReply = replyMsg != null
          ? sent.copyWith(replyToMessage: replyMsg)
          : sent;

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == sent.id);
        if (idx == -1) {
          _messages.add(msgWithReply);
        } else if (replyMsg != null) {
          _messages[idx] = _messages[idx]
              .copyWith(replyToMessage: replyMsg);
        }
      });
      _scrollToBottom();
    }
    if (mounted) setState(() => _isSending = false);
  }

  // ─── Envoyer image ───────────────────────────────────────────────

  Future<void> _sendImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isSending = true);
    try {
      final bytes = await file.readAsBytes();
      final ext   = file.path.split('.').last;
      final path  = 'messages/${widget.conv.id}/'
          '${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from('messages')
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(upsert: false));

      final url = _supabase.storage
          .from('messages').getPublicUrl(path);

      await _service.sendMessage(
        conversationId: widget.conv.id,
        imageUrl:       url,
        replyToId:      _replyTo?.id,
      );
      if (mounted) setState(() => _replyTo = null);
    } catch (e) {
      // ✅ Helpers remplace Get.snackbar avec couleurs hardcodées
      Helpers.showErrorSnackbar('Impossible d\'envoyer l\'image');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Scroll ──────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal(), lb = b.toLocal();
    return la.year  == lb.year  &&
           la.month == lb.month &&
           la.day   == lb.day;
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: ChatAppBar(conv: widget.conv),
      body: Column(children: [
        Expanded(
          child: ChatMessagesList(
            messages:   _messages,
            isLoading:  _isLoading,
            hasMore:    _hasMore,
            uid:        _uid,
            conv:       widget.conv,
            scrollCtrl: _scrollCtrl,
            isSameDay:  _isSameDay,
            onLoadMore: () => _loadMessages(more: true),
            onReply:    (msg) => setState(() => _replyTo = msg),
          ),
        ),
        if (_replyTo != null)
          ChatReplyPreview(
            message:  _replyTo!,
            onCancel: () => setState(() => _replyTo = null),
          ),
        ChatInput(
          textCtrl:  _textCtrl,
          focusNode: _focusNode,
          isSending: _isSending,
          onSend:    _send,
          onImage:   _sendImage,
        ),
      ]),
    );
  }
}
