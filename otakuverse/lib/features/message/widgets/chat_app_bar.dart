import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import '../models/conversation_model.dart';

class ChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final ConversationModel conv;
  const ChatAppBar({super.key, required this.conv});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation:       0,
      leadingWidth:    40,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.textPrimary,
          size:  20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        CachedAvatar(
          url:            conv.displayAvatar,
          radius:         18,
          fallbackLetter: conv.displayName,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conv.displayName,
                style: GoogleFonts.inter(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '@${conv.otherUsername ?? ''}',
                style: GoogleFonts.inter(
                  color:    AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined,
              color: AppColors.textPrimary, size: 22),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert,
              color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }
}