import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

/// Champ de saisie animé pour l'édition de profil.
/// Affiche une bordure et une icône colorées quand le champ est focus.
class EditProfileField extends StatelessWidget {
  final String                      label;
  final TextEditingController       controller;
  final FocusNode                   focusNode;
  final String                      hint;
  final IconData                    icon;
  final FocusNode?                  nextFocus;
  final List<TextInputFormatter>?   formatters;

  const EditProfileField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.nextFocus,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (_, __) {
        final focused = focusNode.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(focused),
            const SizedBox(height: 6),
            _buildInput(focused),
          ],
        );
      },
    );
  }

  Widget _buildLabel(bool focused) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: GoogleFonts.inter(
        color:         focused ? AppColors.primary : AppColors.textMuted,
        fontSize:      11,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0.5,
      ),
      child: Text(label.toUpperCase()),
    );
  }

  Widget _buildInput(bool focused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? AppColors.primary.withValues(alpha: 0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Icon(icon,
              size:  18,
              color: focused ? AppColors.primary : AppColors.textMuted),
        ),
        Expanded(
          child: TextField(
            controller:      controller,
            focusNode:       focusNode,
            inputFormatters: formatters,
            textInputAction: nextFocus != null
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: (_) => nextFocus?.requestFocus(),
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText:  hint,
              hintStyle: GoogleFonts.inter(
                color:    AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 14),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Champ bio (multilignes + compteur) ──────────────────────────────

/// Champ bio avec compteur de caractères animé.
/// Passe en rouge quand le texte dépasse 120 caractères (limite : 150).
class EditProfileBioField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final VoidCallback          onChanged;

  const EditProfileBioField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (_, __) {
        final focused    = focusNode.hasFocus;
        final charCount  = controller.text.length;
        final nearLimit  = charCount > 120;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabelRow(focused, charCount, nearLimit),
            const SizedBox(height: 6),
            _buildTextArea(focused),
          ],
        );
      },
    );
  }

  Widget _buildLabelRow(bool focused, int count, bool nearLimit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: GoogleFonts.inter(
            color:         focused ? AppColors.primary : AppColors.textMuted,
            fontSize:      11,
            fontWeight:    FontWeight.w600,
            letterSpacing: 0.5,
          ),
          child: const Text('BIO'),
        ),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: GoogleFonts.inter(
            color:    nearLimit ? AppColors.primary : AppColors.textMuted,
            fontSize: 11,
          ),
          child: Text('$count / 150'),
        ),
      ],
    );
  }

  Widget _buildTextArea(bool focused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? AppColors.primary.withValues(alpha: 0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode:  focusNode,
        maxLines:   4,
        maxLength:  150,
        onChanged:  (_) => onChanged(),
        style: GoogleFonts.inter(
          color:    AppColors.textPrimary,
          fontSize: 15,
          height:   1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Parle de toi, de tes animés préférés...',
          hintStyle: GoogleFonts.inter(
            color:    AppColors.textMuted.withValues(alpha: 0.5),
            fontSize: 14,
            height:   1.5,
          ),
          border:         InputBorder.none,
          counterText:    '',        // ✅ masquer le counter natif Flutter
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}
