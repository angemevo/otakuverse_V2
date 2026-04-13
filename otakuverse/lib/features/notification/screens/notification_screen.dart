import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/notification/controller/notification_controller.dart';
import 'package:otakuverse/features/notification/models/notification_model.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/profile/screens/profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<NotificationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.notifications.isEmpty) {
        _controller.loadNotifications();
      }
    });

    _scrollController.addListener(() {
      final position  = _scrollController.position;
      final threshold = position.maxScrollExtent * 0.85;
      if (position.pixels >= threshold) {
        _controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onRetry: _controller.loadNotifications,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation:       0,
          title: Text('Activité',
              style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
          actions: [
            Obx(() {
              if (_controller.unreadCount.value == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: _controller.markAllAsRead,
                child: Text('Tout lire',
                    style: GoogleFonts.inter(
                        color:      AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize:   13)),
              );
            }),
          ],
        ),
        body: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary),
            );
          }

          if (_controller.notifications.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            color:           AppColors.primary,
            backgroundColor: AppColors.bgPrimary,
            onRefresh:       _controller.loadNotifications,
            child: ListView.builder(
              controller: _scrollController,
              itemCount:
                  _controller.notifications.length + 1,
              itemBuilder: (context, index) {
                if (index ==
                    _controller.notifications.length) {
                  return Obx(() {
                    if (_controller.isLoadingMore.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (!_controller.hasMore.value &&
                        _controller
                            .notifications.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24),
                        child: Center(
                          child: Text('Tu es à jour ! ✅',
                              style: GoogleFonts.inter(
                                  color:    AppColors
                                      .textMuted,
                                  fontSize: 13)),
                        ),
                      );
                    }
                    return const SizedBox(height: 20);
                  });
                }

                final notif =
                    _controller.notifications[index];
                return _NotifTile(
                  notif:      notif,
                  controller: _controller,
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(HeroiconsOutline.bell,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('Aucune activité',
              style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   16)),
          const SizedBox(height: 6),
          Text('Tes notifications apparaîtront ici',
              style: GoogleFonts.inter(
                  color:    AppColors.textMuted,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── NOTIF TILE ──────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final NotificationModel      notif;
  final NotificationController controller;

  const _NotifTile({
    required this.notif,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key:       Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        color:     AppColors.primary,
        child: const Icon(HeroiconsOutline.trash,
            color: Colors.white, size: 22),
      ),
      onDismissed: (_) =>
          controller.deleteNotification(notif.id),
      child: GestureDetector(
        onTap:    () => _handleTap(context),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: notif.isRead
              ? Colors.transparent
              : AppColors.primary
                  .withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─ Avatar ✅ CachedAvatar + badge ───────────
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                        userId: notif.actorId),
                  ),
                ),
                child: Stack(children: [
                  CachedAvatar(
                    url:            notif.actorAvatarUrl,
                    radius:         24,
                    fallbackLetter: notif.actorName,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color:  _badgeColor,
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: AppColors.bgPrimary,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(_badgeIcon,
                          color: Colors.white, size: 10),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),

              // ─ Texte ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: notif.actorName,
                          style: GoogleFonts.inter(
                            color:      AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize:   14,
                          ),
                        ),
                        TextSpan(
                          text: ' ${notif.message}',
                          style: GoogleFonts.inter(
                            color:    AppColors.primaryLight,
                            fontSize: 14,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(notif.createdAt),
                      style: GoogleFonts.inter(
                          color:    AppColors.textMuted,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),

              // ─ Miniature post ✅ CachedImage ─────────
              if (notif.hasPostMedia) ...[
                const SizedBox(width: 12),
                CachedImage(
                  url:          notif.postMediaUrl,
                  width:        48,
                  height:       48,
                  fit:          BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],

              // ─ Point non lu ───────────────────────────
              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    controller.markAsRead(notif.id);

    switch (notif.type) {
      case 'follow':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ProfileScreen(userId: notif.actorId),
        ));
        break;
      case 'like':
      case 'comment':
      case 'reply':
        if (notif.postId != null) {
          showCommentsSheet(
            context,
            postId:     notif.postId!,
            postAuthor: notif.actorName,
          );
        }
        break;
    }
  }

  Color get _badgeColor {
    switch (notif.type) {
      case 'like':    return AppColors.primary;
      case 'comment': return const Color(0xFF7C6FFF);
      case 'reply':   return const Color(0xFF7C6FFF);
      case 'follow':  return const Color(0xFF22C55E);
      default:        return AppColors.textMuted;
    }
  }

  IconData get _badgeIcon {
    switch (notif.type) {
      case 'like':    return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'reply':   return Icons.reply;
      case 'follow':  return Icons.person;
      default:        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours   < 24) return '${diff.inHours} h';
    if (diff.inDays    < 7)  return '${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }
}