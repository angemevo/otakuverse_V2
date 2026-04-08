import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conv;
  const ChatScreen({super.key, required this.conv});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service      = MessageService();
  final _supabase     = Supabase.instance.client;
  final _textCtrl     = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final _focusNode    = FocusNode();

  String get _uid => _supabase.auth.currentUser!.id;

  List<MessageModel> _messages    = [];
  bool               _isLoading   = true;
  bool               _isSending   = false;
  bool               _hasMore     = true;
  MessageModel?      _replyTo;

  RealtimeChannel?   _channel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
    _markAsRead();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ─── REALTIME ────────────────────────────────────────────────────
  void _subscribeRealtime() {
    _channel = _supabase
        .channel('chat:${widget.conv.id}')
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
            // ✅ Charger le message avec le sender jointé
            final data = await _supabase
                .from('messages')
                .select('''
                  *,
                  sender:profiles(
                    user_id, username,
                    display_name, avatar_url
                  )
                ''')
                .eq('id',
                    payload.newRecord['id'] as String)
                .single();

            final msg = MessageModel.fromJson(
                data as Map<String, dynamic>);

            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
              // ✅ Marquer comme lu si pas moi
              if (msg.senderId != _uid) _markAsRead();
            }
          },
        )
        .subscribe();
  }

  // ─── CHARGER MESSAGES ────────────────────────────────────────────
  Future<void> _loadMessages({bool more = false}) async {
    if (!more) setState(() => _isLoading = true);

    final offset = more ? _messages.length : 0;
    final data   = await _service.getMessages(
      widget.conv.id,
      limit:  50,
      offset: offset,
    );

    if (mounted) {
      setState(() {
        if (more) {
          _messages = [...data, ..._messages];
        } else {
          _messages = data;
        }
        _hasMore  = data.length >= 50;
        _isLoading = false;
      });

      if (!more) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  // ─── MARQUER LU ──────────────────────────────────────────────────
  Future<void> _markAsRead() async {
    await _service.markAsRead(widget.conv.id);
  }

  // ─── ENVOYER ─────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    _textCtrl.clear();
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);

    await _service.sendMessage(
      conversationId: widget.conv.id,
      text:           text,
      replyToId:      replyId,
    );

    setState(() => _isSending = false);
  }

  // ─── ENVOYER IMAGE ───────────────────────────────────────────────
  Future<void> _sendImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isSending = true);

    try {
      final bytes = await file.readAsBytes();
      final ext   = file.path.split('.').last;
      final path  =
          'messages/${widget.conv.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from('messages')
          .uploadBinary(path, bytes,
              fileOptions:
                  const FileOptions(upsert: false));

      final url = _supabase.storage
          .from('messages')
          .getPublicUrl(path);

      await _service.sendMessage(
        conversationId: widget.conv.id,
        imageUrl:       url,
        replyToId:      _replyTo?.id,
      );

      setState(() => _replyTo = null);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer l\'image',
        backgroundColor: AppColors.errorRed,
        colorText:       AppColors.pureWhite,
        snackPosition:   SnackPosition.BOTTOM,
        margin:          const EdgeInsets.all(16),
        borderRadius:    12,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── SCROLL ──────────────────────────────────────────────────────
  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve:    Curves.easeOut,
      );
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar:          _buildAppBar(),
      body: Column(
        children: [
          // ─ Messages ────────────────────────────────────────
          Expanded(child: _buildMessagesList()),

          // ─ Reply preview ───────────────────────────────────
          if (_replyTo != null) _buildReplyPreview(),

          // ─ Input ───────────────────────────────────────────
          _buildInput(),
        ],
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.deepBlack,
      elevation:       0,
      leadingWidth:    40,
      leading: IconButton(
        icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.pureWhite, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: () {}, // TODO: ouvrir profil
        child: Row(
          children: [
            CachedAvatar(
              url:           widget.conv.displayAvatar,
              radius:        18,
              fallbackLetter: widget.conv.displayName,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conv.displayName,
                    style: GoogleFonts.inter(
                      color:      AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                      fontSize:   15,
                    ),
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${widget.conv.otherUsername ?? ''}',
                    style: GoogleFonts.inter(
                      color:    AppColors.mediumGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
              Icons.videocam_outlined,
              color: AppColors.pureWhite, size: 22),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(
              Icons.more_vert,
              color: AppColors.pureWhite),
          onPressed: () {},
        ),
      ],
    );
  }

  // ─── LISTE MESSAGES ──────────────────────────────────────────────
  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.crimsonRed),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedAvatar(
              url:           widget.conv.displayAvatar,
              radius:        36,
              fallbackLetter: widget.conv.displayName,
            ),
            const SizedBox(height: 16),
            Text(
              widget.conv.displayName,
              style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize:   18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commence la conversation !',
              style: GoogleFonts.inter(
                color:    AppColors.mediumGray,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // ✅ Charger plus en scrollant vers le haut
        if (n is ScrollStartNotification &&
            _scrollCtrl.position.pixels <= 100 &&
            _hasMore) {
          _loadMessages(more: true);
        }
        return false;
      },
      child: ListView.builder(
        controller:  _scrollCtrl,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final msg    = _messages[i];
          final isMe   = msg.senderId == _uid;
          final prev   = i > 0 ? _messages[i - 1] : null;
          final next   = i < _messages.length - 1
              ? _messages[i + 1] : null;

          // ✅ Grouper les messages du même sender
          final showAvatar = !isMe &&
              (next == null ||
                  next.senderId != msg.senderId);
          final isFirst = prev == null ||
              prev.senderId != msg.senderId;
          final isLast  = next == null ||
              next.senderId != msg.senderId;

          // ✅ Afficher la date si changement de jour
          final showDate = prev == null ||
              !_isSameDay(prev.createdAt, msg.createdAt);

          return Column(
            children: [
              if (showDate)
                _DateSeparator(date: msg.createdAt),
              _MessageBubble(
                message:    msg,
                isMe:       isMe,
                showAvatar: showAvatar,
                isFirst:    isFirst,
                isLast:     isLast,
                onReply: () =>
                    setState(() => _replyTo = msg),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── REPLY PREVIEW ───────────────────────────────────────────────
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.darkGray,
        border: Border(
          top: BorderSide(
              color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 36,
            color: AppColors.crimsonRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _replyTo!.senderName,
                  style: GoogleFonts.inter(
                    color:      AppColors.crimsonRed,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyTo!.text ??
                      '📷 Image',
                  style: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 12,
                  ),
                  maxLines:  1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _replyTo = null),
            child: const Icon(
              Icons.close,
              color: AppColors.mediumGray,
              size:  18,
            ),
          ),
        ],
      ),
    );
  }

  // ─── INPUT ───────────────────────────────────────────────────────
  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left:   12, right: 12,
        top:    8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deepBlack,
        border: Border(
          top: BorderSide(
              color: Color(0xFF1A1A1A), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ─ Image ─────────────────────────────────────────
          GestureDetector(
            onTap: _sendImage,
            child: Container(
              width: 38, height: 38,
              margin: const EdgeInsets.only(
                  right: 8, bottom: 1),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.mediumGray,
                size:  20,
              ),
            ),
          ),

          // ─ Texte ─────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                  maxHeight: 120),
              decoration: BoxDecoration(
                color:        AppColors.darkGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller:  _textCtrl,
                focusNode:   _focusNode,
                maxLines:    null,
                style: GoogleFonts.inter(
                  color:    AppColors.pureWhite,
                  fontSize: 15,
                ),
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText:  'Message...',
                  hintStyle: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 15,
                  ),
                  border:         InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical:   10,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ─ Envoyer ───────────────────────────────────────
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _textCtrl.text.trim().isNotEmpty
                    ? AppColors.crimsonRed
                    : AppColors.darkGray,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _textCtrl.text
                              .trim().isNotEmpty
                          ? Colors.white
                          : AppColors.mediumGray,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

// ─── BULLE MESSAGE ───────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool         isMe;
  final bool         showAvatar;
  final bool         isFirst;
  final bool         isLast;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.isFirst,
    required this.isLast,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top:    isFirst ? 6 : 2,
        bottom: isLast  ? 6 : 2,
        left:   isMe ? 60 : 0,
        right:  isMe ? 0  : 60,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          // ─ Avatar (autres) ─────────────────────────────
          if (!isMe) ...[
            if (showAvatar)
              CachedAvatar(
                url:           message.senderAvatarUrl,
                radius:        16,
                fallbackLetter: message.senderName,
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 6),
          ],

          // ─ Bulle ───────────────────────────────────────
          GestureDetector(
            onHorizontalDragEnd: (_) => onReply(),
            onLongPress: onReply,
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width *
                    0.68,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.crimsonRed
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(
                      !isMe && !isFirst ? 4 : 16),
                  topRight:    Radius.circular(
                      isMe  && !isFirst ? 4 : 16),
                  bottomLeft:  Radius.circular(
                      !isMe && !isLast  ? 4 : 16),
                  bottomRight: Radius.circular(
                      isMe  && !isLast  ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ─ Image ─────────────────────────────
                  if (message.imageUrl != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8),
                      child: Image.network(
                        message.imageUrl!,
                        width:  200,
                        fit:    BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    ),

                  // ─ Texte ─────────────────────────────
                  if (message.text != null)
                    Text(
                      message.text!,
                      style: GoogleFonts.inter(
                        color:    Colors.white,
                        fontSize: 14,
                        height:   1.4,
                      ),
                    ),

                  // ─ Heure + Lu ────────────────────────
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      Text(
                        _fmtTime(message.createdAt),
                        style: GoogleFonts.inter(
                          color: Colors.white
                              .withValues(alpha: 0.55),
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          color: message.isRead
                              ? Colors.white
                              : Colors.white
                                  .withValues(alpha: 0.55),
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── SÉPARATEUR DATE ─────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now  = DateTime.now();
    final diff = now.difference(date).inDays;

    String label;
    if (diff == 0)      label = 'Aujourd\'hui';
    else if (diff == 1) label = 'Hier';
    else if (diff < 7) {
      const j = ['Lun','Mar','Mer','Jeu',
                  'Ven','Sam','Dim'];
      label = j[date.weekday - 1];
    } else {
      label = '${date.day}/${date.month}/'
          '${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColors.mediumGray
                      .withValues(alpha: 0.2))),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color:    AppColors.mediumGray,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
              child: Divider(
                  color: AppColors.mediumGray
                      .withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}