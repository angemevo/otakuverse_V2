import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/notification_bell.dart';

class OtakuverseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearch;
  final VoidCallback? onMessages;

  const OtakuverseAppBar({
    super.key,
    this.onSearch,
    this.onMessages,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:        AppColors.bgPrimary,
      elevation:              0,
      scrolledUnderElevation: 0,
      title: Text('OTAKUVERSE', style: AppTextStyles.appBarTitle),
      actions: [
        // ─ Recherche ─────────────────────────────────────────────
        IconButton(
          tooltip:   'Rechercher',
          onPressed: onSearch ?? () {},
          icon: const Icon(
            HeroiconsOutline.magnifyingGlass,
            color: AppColors.textPrimary,
            size:  24,
          ),
        ),

        // ─ Messages ──────────────────────────────────────────────
        IconButton(
          tooltip:   'Messages',
          onPressed: onMessages ?? () {},
          icon: const Icon(
            HeroiconsOutline.chatBubbleLeftRight,
            color: AppColors.textPrimary,
            size:  24,
          ),
        ),

        // ─ Notifications (badge réactif via NotificationController) ─
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child:   NotificationBell(),
        ),
      ],
    );
  }
}
