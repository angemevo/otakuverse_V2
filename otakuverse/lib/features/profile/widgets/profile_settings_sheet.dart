import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';

/// Affiche le bottom-sheet de paramètres du profil.
void showSettingsSheet({
  required BuildContext context,
  required ProfileModel profile,
  required VoidCallback onProfileUpdated,
  required VoidCallback onLogoutRequested,
}) {
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
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color:        AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        _SettingsItem(
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

        _SettingsItem(
          icon:  Icons.lock_outline,
          label: 'Changer le mot de passe',
          onTap: () => Navigator.pop(sheetCtx),
        ),

        _SettingsItem(
          icon:  Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => Navigator.pop(sheetCtx),
        ),

        _SettingsItem(
          icon:  Icons.privacy_tip_outlined,
          label: 'Confidentialité',
          onTap: () => Navigator.pop(sheetCtx),
        ),

        Divider(
          color:  AppColors.textMuted.withValues(alpha: 0.2),
          height: 1,
        ),

        _SettingsItem(
          key:   AppKeys.logoutButton,
          icon:  Icons.logout,
          label: 'Se déconnecter',
          color: AppColors.primary,
          onTap: () {
            Navigator.pop(sheetCtx);
            onLogoutRequested();
          },
        ),

        const SizedBox(height: 16),
      ],
    ),
  );
}

// ─── Item interne ─────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final Color?       color;

  const _SettingsItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title:   Text(label,
          style: GoogleFonts.inter(color: c, fontSize: 15)),
      // ✅ Flèche uniquement sur les items non-destructifs
      trailing: color == null
          ? const Icon(Icons.arrow_forward_ios,
              color: AppColors.textMuted, size: 14)
          : null,
      onTap: onTap,
    );
  }
}
