import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

/// Barre fixe en bas de l'écran d'édition.
/// Contient le bouton "Annuler" et le bouton "Sauvegarder" avec gradient.
class EditProfileSaveBar extends StatelessWidget {
  final bool         isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const EditProfileSaveBar({
    super.key,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(children: [
        Expanded(child: _buildCancelBtn()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildSaveBtn()),
      ]),
    );
  }

  // ─── Bouton Annuler ──────────────────────────────────────────────

  Widget _buildCancelBtn() {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(
            'Annuler',
            style: GoogleFonts.inter(
              color:      AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize:   15,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bouton Sauvegarder ──────────────────────────────────────────

  Widget _buildSaveBtn() {
    return GestureDetector(
      onTap: isSaving ? null : onSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height:   52,
        decoration: BoxDecoration(
          gradient: isSaving
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFE01A3C), Color(0xFFFF4F6E)],
                  begin:  Alignment.centerLeft,
                  end:    Alignment.centerRight,
                ),
          color: isSaving
              ? AppColors.primary.withValues(alpha: 0.4)
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSaving
              ? null
              : [
                  BoxShadow(
                    color:      AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset:     const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sauvegarder',
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
                    ),
                  ),
                ]),
        ),
      ),
    );
  }
}
