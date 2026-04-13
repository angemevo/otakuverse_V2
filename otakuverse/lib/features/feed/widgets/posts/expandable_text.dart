import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class ExpandableText extends StatefulWidget {
  final String username;
  final String caption;

  const ExpandableText({
    super.key,
    required this.username,
    required this.caption,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  static const int _maxLines = 3;

  // ✅ Détecte si le texte dépasse la limite
  bool _needsExpansion(String text) {
    return text.split('\n').length > _maxLines ||
        text.length > 150;
  }

  @override
  Widget build(BuildContext context) {
    final fullText = widget.caption;
    final needsExp = _needsExpansion(fullText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─ Markdown avec username en préfixe ──────────────
        _buildContent(fullText, needsExp),

        // ─ Bouton voir plus / moins ───────────────────────
        if (needsExp)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _expanded ? 'voir moins' : 'voir plus',
                style: GoogleFonts.inter(
                  color:      AppColors.textMuted,
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(String text, bool needsExp) {
    // ✅ Tronquer si non expandé
    String displayText = text;
    if (needsExp && !_expanded) {
      final lines = text.split('\n');
      if (lines.length > _maxLines) {
        displayText = lines.take(_maxLines).join('\n');
      } else if (text.length > 150) {
        displayText = '${text.substring(0, 150)}...';
      }
    }

    // ✅ Contenu markdown avec username en gras au début
    final markdownContent =
        '**${widget.username}** $displayText';

    return MarkdownBody(
      data:              markdownContent,
      shrinkWrap:        true,
      softLineBreak:     true,
      styleSheet: MarkdownStyleSheet(
        // ─ Texte normal ──────────────────────────────────
        p: GoogleFonts.inter(
          color:    AppColors.textPrimary,
          fontSize: 14,
          height:   1.4,
        ),
        // ─ Gras ──────────────────────────────────────────
        strong: GoogleFonts.inter(
          color:      AppColors.textPrimary,
          fontSize:   14,
          fontWeight: FontWeight.w700,
          height:     1.4,
        ),
        // ─ Italique ──────────────────────────────────────
        em: GoogleFonts.inter(
          color:      AppColors.textPrimary,
          fontSize:   14,
          fontStyle:  FontStyle.italic,
          height:     1.4,
        ),
        // ─ Souligné via del ──────────────────────────────
        del: GoogleFonts.inter(
          color:      AppColors.textPrimary,
          fontSize:   14,
          decoration: TextDecoration.underline,
          height:     1.4,
        ),
        // ─ Code inline ───────────────────────────────────
        code: GoogleFonts.inter(
          color:           AppColors.primaryLight,
          fontSize:        13,
          backgroundColor: AppColors.bgCard,
        ),
        blockSpacing:        0,
        pPadding:            EdgeInsets.zero,
        blockquotePadding:   EdgeInsets.zero,
        blockquoteDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
      ),
      // ✅ Hashtags en rouge
      onTapText: () {},
    );
  }
}