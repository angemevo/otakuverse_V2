import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/notification/controller/notification_controller.dart';
import 'package:otakuverse/features/notification/screens/notification_screen.dart';

// ─── Cloche notifications ─────────────────────────────────────────────

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : null;

    final iconBtn = IconButton(
      icon: const Icon(HeroiconsOutline.bell,
          color: AppColors.textPrimary, size: 24),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
    );

    if (notifCtrl == null) return iconBtn;

    return Obx(() {
      final count = notifCtrl.unreadCount.value;
      if (count == 0) return iconBtn;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconBtn,
          Positioned(
            top: 6, right: 6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.bgPrimary, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontSize:   9,
                    fontWeight: FontWeight.w700,
                    height:     1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Badge "Nouveaux posts" ───────────────────────────────────────────

class NewContentBadge extends StatelessWidget {
  final VoidCallback onTap;
  const NewContentBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8, left: 0, right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve:    Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:        AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:      AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Nouveaux posts',
                style: GoogleFonts.inter(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   13,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Bandeau découverte ───────────────────────────────────────────────

class DiscoveryBanner extends StatelessWidget {
  const DiscoveryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:   const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.explore_outlined,
            color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Feed de découverte',
                  style: GoogleFonts.poppins(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  )),
              Text(
                'Suis des utilisateurs pour personnaliser ton feed',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Feed vide ───────────────────────────────────────────────────────

class EmptyFeed extends StatelessWidget {
  const EmptyFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.dynamic_feed_outlined,
            color: AppColors.textMuted, size: 48),
        const SizedBox(height: 12),
        Text('Aucun post pour le moment',
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize:   16,
            )),
        const SizedBox(height: 8),
        Text('Sois le premier à publier quelque chose !',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 12)),
      ]),
    );
  }
}
