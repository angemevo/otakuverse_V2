import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/message/models/message_model.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool         isMe;
  final bool         showAvatar;
  final bool         isFirst;
  final bool         isLast;
  final VoidCallback onReply;

  const MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.isFirst,
    required this.isLast,
    required this.onReply,
  });

  @override
  State<MessageBubble> createState() =>
      MessageBubbleState();
}

class MessageBubbleState
    extends State<MessageBubble>
    with SingleTickerProviderStateMixin {

  // ─── Animation reply ─────────────────────────────────────────────
  late final AnimationController _replyCtrl;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _iconFade;

  double _dragOffset = 0;
  bool   _triggered  = false;

  static const _triggerThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _replyCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end:   widget.isMe
          ? const Offset(-0.15, 0)
          : const Offset(0.15, 0),
    ).animate(CurvedAnimation(
        parent: _replyCtrl,
        curve:  Curves.easeOutBack));

    _iconFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
            parent: _replyCtrl,
            curve:  Curves.easeOut));
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  // ─── Gestion du swipe ────────────────────────────────────────────
  void _onHorizontalDragUpdate(
      DragUpdateDetails details) {
    final dx = details.primaryDelta ?? 0;

    // ✅ Swipe gauche si message de moi
    // ✅ Swipe droit si message de l'autre
    final isValid = widget.isMe ? dx < 0 : dx > 0;
    if (!isValid) return;

    setState(() {
      _dragOffset = (_dragOffset + dx.abs())
          .clamp(0.0, _triggerThreshold);
    });

    // ✅ Animer proportionnellement
    _replyCtrl.value =
        _dragOffset / _triggerThreshold;

    // ✅ Feedback haptique au seuil
    if (_dragOffset >= _triggerThreshold &&
        !_triggered) {
      _triggered = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _onHorizontalDragEnd(
      DragEndDetails details) {
    if (_triggered) {
      widget.onReply();
    }

    // ✅ Retour en position avec rebond
    _replyCtrl.animateBack(
      0,
      duration: const Duration(milliseconds: 300),
      curve:    Curves.easeOutBack,
    );

    setState(() {
      _dragOffset = 0;
      _triggered  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top:    widget.isFirst ? 6 : 2,
        bottom: widget.isLast  ? 6 : 2,
        left:   widget.isMe ? 60 : 0,
        right:  widget.isMe ? 0  : 60,
      ),
      child: GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd:    _onHorizontalDragEnd,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ─ Icône reply (apparaît pendant le swipe) ───────────
            Positioned(
              top:   0, bottom: 0,
              left:  widget.isMe ? null : -32,
              right: widget.isMe ? -32  : null,
              child: Center(
                child: FadeTransition(
                  opacity: _iconFade,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.mediumGray
                          .withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: AppColors.pureWhite,
                      size:  16,
                    ),
                  ),
                ),
              ),
            ),

            // ─ Bulle avec slide ──────────────────────────────────
            Row(
              mainAxisAlignment: widget.isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                // ─ Avatar ──────────────────────────────────────
                if (!widget.isMe) ...[
                  if (widget.showAvatar)
                    CachedAvatar(
                      url:            widget.message
                          .senderAvatarUrl,
                      radius:         16,
                      fallbackLetter: widget.message
                          .senderName,
                    )
                  else
                    const SizedBox(width: 32),
                  const SizedBox(width: 6),
                ],

                // ─ Bulle ────────────────────────────────────────
                SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context)
                              .size.width *
                          0.68,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical:   8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? AppColors.crimsonRed
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            !widget.isMe &&
                                    !widget.isFirst
                                ? 4
                                : 16),
                        topRight: Radius.circular(
                            widget.isMe &&
                                    !widget.isFirst
                                ? 4
                                : 16),
                        bottomLeft: Radius.circular(
                            !widget.isMe &&
                                    !widget.isLast
                                ? 4
                                : 16),
                        bottomRight: Radius.circular(
                            widget.isMe &&
                                    !widget.isLast
                                ? 4
                                : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ─ Image ───────────────────────────────
                        if (widget.message.imageUrl !=
                            null)
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: Image.network(
                              widget.message.imageUrl!,
                              width:  200,
                              fit:    BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                              ),
                            ),
                          ),

                        // ─ Texte ───────────────────────────────
                        if (widget.message.text != null)
                          Text(
                            widget.message.text!,
                            style: GoogleFonts.inter(
                              color:    Colors.white,
                              fontSize: 14,
                              height:   1.4,
                            ),
                          ),

                        // ─ Heure + Ticks ───────────────────────
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            Text(
                              _fmtTime(widget.message
                                  .createdAt),
                              style: GoogleFonts.inter(
                                color: Colors.white
                                    .withValues(
                                        alpha: 0.55),
                                fontSize: 10,
                              ),
                            ),

                            // ✅ Ticks style WhatsApp
                            if (widget.isMe) ...[
                              const SizedBox(width: 4),
                              _buildTicks(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TICKS STYLE WHATSAPP ────────────────────────────────────────
  Widget _buildTicks() {
    // ✅ Lu = double tick bleu
    // ✅ Envoyé = simple tick gris
    // ✅ Reçu (côté destinataire) = double tick gris
    //    → pour nous (isMe=true) on gère seulement
    //      simple tick = envoyé, double = lu

    if (widget.message.isRead) {
      // ─ Double tick bleu ──────────────────────────────
      return const _DoubleTick(color: Color(0xFF34B7F1));
    }

    // ─ Simple tick gris = envoyé, pas encore lu ────────
    return _SingleTick(
      color: Colors.white.withValues(alpha: 0.55),
    );
  }

  String _fmtTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── TICK SIMPLE ─────────────────────────────────────────────────────
class _SingleTick extends StatelessWidget {
  final Color color;
  const _SingleTick({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.done,
      color: color,
      size:  14,
    );
  }
}

// ─── DOUBLE TICK ─────────────────────────────────────────────────────
class _DoubleTick extends StatelessWidget {
  final Color color;
  const _DoubleTick({required this.color});

  @override
  Widget build(BuildContext context) {
    // ✅ Superposer 2 icônes décalées
    return SizedBox(
      width:  20,
      height: 14,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Icon(
              Icons.done,
              color: color,
              size:  14,
            ),
          ),
          Positioned(
            left: 6,
            child: Icon(
              Icons.done,
              color: color,
              size:  14,
            ),
          ),
        ],
      ),
    );
  }
}