import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/controllers/bookmark_controller.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

/// Affiche le bottom-sheet contextuel d'un post.
void showPostMenu({
  required BuildContext context,
  required PostModel    post,
  required bool         isMe,
  required VoidCallback onProfile,
  VoidCallback?         onDelete,
}) {
  final bookmarkCtrl = Get.isRegistered<BookmarkController>()
      ? Get.find<BookmarkController>()
      : null;

  showModalBottomSheet(
    context:         context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // ─ Handle ──────────────────────────────────────────────
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color:        AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        // ─ Sauvegarder ─────────────────────────────────────────
        if (bookmarkCtrl != null)
          Obx(() {
            final saved = bookmarkCtrl.isBookmarked(post.id);
            return _menuItem(
              context: sheetCtx,
              icon:    saved
                  ? HeroiconsSolid.bookmark
                  : HeroiconsOutline.bookmark,
              label:   saved ? 'Retirer la sauvegarde' : 'Sauvegarder',
              onTap:   () => bookmarkCtrl.toggleBookmark(post.id),
              color:   saved ? AppColors.primary : null,
            );
          })
        else
          _menuItem(
            context: sheetCtx,
            icon:    HeroiconsOutline.bookmark,
            label:   'Sauvegarder',
            onTap:   () {},
          ),

        // ─ Voir le profil ──────────────────────────────────────
        _menuItem(
          context: sheetCtx,
          icon:    HeroiconsOutline.user,
          label:   'Voir le profil',
          onTap:   onProfile,
        ),

        // ─ Copier le lien ──────────────────────────────────────
        _menuItem(
          context: sheetCtx,
          icon:    HeroiconsOutline.link,
          label:   'Copier le lien',
          onTap:   () {},
        ),

        const Divider(color: AppColors.textMuted, height: 1),

        // ─ Signaler ────────────────────────────────────────────
        _menuItem(
          context: sheetCtx,
          icon:    HeroiconsOutline.flag,
          label:   'Signaler',
          onTap:   () {},
          color:   AppColors.primary,
        ),

        // ─ Supprimer (propriétaire uniquement) ─────────────────
        // FIX : était onTap: () {} — maintenant câblé sur onDelete
        if (isMe)
          _menuItem(
            context: sheetCtx,
            icon:    HeroiconsOutline.trash,
            label:   'Supprimer',
            onTap:   onDelete ?? () {},
            color:   AppColors.primary,
          ),

        const SizedBox(height: 16),
      ],
    ),
  );
}

Widget _menuItem({
  required BuildContext context,
  required IconData     icon,
  required String       label,
  required VoidCallback onTap,
  Color?                color,
}) {
  return ListTile(
    leading: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
    title: Text(
      label,
      style: GoogleFonts.inter(
          color: color ?? AppColors.textPrimary, fontSize: 15),
    ),
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
  );
}