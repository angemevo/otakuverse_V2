import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';

/// Affiche le bottom-sheet de paramètres du profil.
void showSettingsSheet({
  required BuildContext  context,
  required ProfileModel  profile,
  required VoidCallback  onProfileUpdated,
  required VoidCallback  onLogoutRequested,
}) {
  showModalBottomSheet(
    context:         context,
    backgroundColor: AppColors.darkGray,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color:        AppColors.mediumGray,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        _settingsItem(
          context: sheetCtx,
          icon:  Icons.edit_outlined,
          label: 'Modifier le profil',
          onTap: () {
            Navigator.pop(sheetCtx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(profile: profile),
              ),
            ).then((_) => onProfileUpdated());
          },
        ),

        _settingsItem(
          context: sheetCtx,
          icon:  Icons.lock_outline,
          label: 'Changer le mot de passe',
          onTap: () => Navigator.pop(sheetCtx),
        ),

        _settingsItem(
          context: sheetCtx,
          icon:  Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => Navigator.pop(sheetCtx),
        ),

        _settingsItem(
          context: sheetCtx,
          icon:  Icons.privacy_tip_outlined,
          label: 'Confidentialité',
          onTap: () => Navigator.pop(sheetCtx),
        ),

        const Divider(color: AppColors.mediumGray, height: 1),

        _settingsItem(
          context: sheetCtx,
          icon:  Icons.logout,
          label: 'Se déconnecter',
          onTap: () {
            Navigator.pop(sheetCtx);
            onLogoutRequested();
          },
          color: AppColors.crimsonRed,
        ),

        const SizedBox(height: 16),
      ],
    ),
  );
}

Widget _settingsItem({
  required BuildContext context,
  required IconData     icon,
  required String       label,
  required VoidCallback onTap,
  Color?                color,
}) {
  return ListTile(
    leading: Icon(icon,
        color: color ?? AppColors.pureWhite, size: 22),
    title: Text(
      label,
      style: GoogleFonts.inter(
          color: color ?? AppColors.pureWhite, fontSize: 15),
    ),
    trailing: color == null
        ? const Icon(Icons.arrow_forward_ios,
            color: AppColors.mediumGray, size: 14)
        : null,
    onTap: onTap,
  );
}