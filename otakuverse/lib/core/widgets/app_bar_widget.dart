import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class OtakuverseAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  final bool showActions;
  final int  unreadCount;
  final VoidCallback? onSearch;
  final VoidCallback? onNotification;

  const OtakuverseAppBar({
    super.key,
    this.showActions      = true,
    this.unreadCount      = 0,
    this.onSearch,
    this.onNotification,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:      AppColors.bgPrimary,
      elevation:            0,
      scrolledUnderElevation: 0,
      title: Text(
        'OTAKUVERSE',
        style: AppTextStyles.appBarTitle,
      ),
      actions: showActions
          ? [
              // ─ Recherche ─────────────────────────────────────
              IconButton(
                onPressed: onSearch ?? () {},
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size:  24,
                ),
              ),

              // ─ Notifications avec badge ───────────────────────
              Padding(
                padding:
                    const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed:
                          onNotification ?? () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textSecondary,
                        size:  24,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 6, right: 6,
                        child: IgnorePointer(
                          child: Container(
                            constraints:
                                const BoxConstraints(
                              minWidth:  16,
                              minHeight: 16,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.bgPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : '$unreadCount',
                              style:
                                  AppTextStyles.badge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]
          : null,
    );
  }
}