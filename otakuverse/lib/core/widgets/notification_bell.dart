import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/notification/controller/notification_controller.dart';
import 'package:otakuverse/features/notification/screens/notification_screen.dart';

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
