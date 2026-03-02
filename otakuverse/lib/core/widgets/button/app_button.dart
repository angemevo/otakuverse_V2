import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

enum AppButtonType { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;  // ✅ OPTIONNEL maintenant
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;

  const AppButton({
    super.key,
    required this.label,
    required this.type,
    this.onPressed,
    this.isLoading = false,
    this.labelStyle,  // ✅ OPTIONNEL
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoaderColor(),  // ✅ CORRECTION : Couleur dynamique
              ),
            ),
          )
        : Text(
            label,
            style: labelStyle ??  // ✅ CORRECTION : Utilise labelStyle si fourni
                GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: _getTextColor(),  // ✅ CORRECTION : Couleur adaptée
                ),
          );

    switch (type) {
      case AppButtonType.primary:
        return _primary(child);
      case AppButtonType.secondary:
        return _secondary(child);
      case AppButtonType.ghost:
        return _ghost(child);
    }
  }

  // ✅ NOUVEAU : Couleur du loader selon le type de bouton
  Color _getLoaderColor() {
    switch (type) {
      case AppButtonType.primary:
        return Colors.white;  // Blanc sur fond rouge
      case AppButtonType.secondary:
      case AppButtonType.ghost:
        return AppColors.crimsonRed;  // Rouge sur fond clair
    }
  }

  // ✅ NOUVEAU : Couleur du texte selon le type de bouton
  Color _getTextColor() {
    switch (type) {
      case AppButtonType.primary:
        return AppColors.pureWhite;  // Texte blanc sur fond rouge
      case AppButtonType.secondary:
      case AppButtonType.ghost:
        return AppColors.crimsonRed;  // Texte rouge
    }
  }

  Widget _primary(Widget child) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimsonRed,
          foregroundColor: Colors.white,  // ✅ CORRECTION : Couleur texte définie
          disabledBackgroundColor: AppColors.crimsonRed.withOpacity(0.4),
          elevation: 4,
          shadowColor: const Color(0x4DDC143C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _secondary(Widget child) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.crimsonRed,
          disabledForegroundColor: AppColors.crimsonRed.withOpacity(0.4),  // ✅ AMÉLIORATION
          side: BorderSide(
            color: isLoading  // ✅ AMÉLIORATION : Bordure disabled
                ? AppColors.crimsonRed.withOpacity(0.4)
                : AppColors.crimsonRed,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _ghost(Widget child) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.crimsonRed,
        disabledForegroundColor: AppColors.crimsonRed.withOpacity(0.4),  // ✅ AMÉLIORATION
      ),
      child: child,
    );
  }
}