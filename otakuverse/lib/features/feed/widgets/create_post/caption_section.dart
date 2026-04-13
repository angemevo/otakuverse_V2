import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaptionSection extends StatefulWidget {
  final TextEditingController controller;
  const CaptionSection({super.key, required this.controller});

  @override
  State<CaptionSection> createState() => _CaptionSectionState();
}

class _CaptionSectionState extends State<CaptionSection> {
  bool       _showEmoji = false;
  final      _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _insertHashtag() {
    final ctrl   = widget.controller;
    final offset = ctrl.selection.baseOffset < 0
        ? ctrl.text.length
        : ctrl.selection.baseOffset;
    final newText = '${ctrl.text.substring(0, offset)} #'
        '${ctrl.text.substring(offset)}';
    ctrl.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(offset: offset + 2),
    );
    _focusNode.requestFocus();
  }

  void _toggleEmoji() {
    setState(() => _showEmoji = !_showEmoji);
    if (_showEmoji) _focusNode.unfocus();
    else            _focusNode.requestFocus();
  }

  void _onEmojiSelected(Category? cat, Emoji emoji) {
    final ctrl   = widget.controller;
    final offset = ctrl.selection.baseOffset < 0
        ? ctrl.text.length
        : ctrl.selection.baseOffset;
    final newText = '${ctrl.text.substring(0, offset)}'
        '${emoji.emoji}'
        '${ctrl.text.substring(offset)}';
    ctrl.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(
          offset: offset + emoji.emoji.length),
    );
  }

  void _showEffects() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TextEffectsSheet(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user      = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final username  = user?.userMetadata?['username'] as String? ?? 'Moi';

    return Column(children: [
      Container(
        color:   AppColors.bgPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedAvatar(
              url: avatarUrl, radius: 20, fallbackLetter: username),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode:  _focusNode,
                maxLines:   null,
                maxLength:  2200,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 15),
                onTap: () {
                  if (_showEmoji) setState(() => _showEmoji = false);
                },
                decoration: InputDecoration(
                  hintText:  'Ajouter une légende...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 15),
                  border:         InputBorder.none,
                  isDense:        true,
                  contentPadding: EdgeInsets.zero,
                  counterStyle: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(children: [
              _IconBtn(
                  icon: Icons.auto_fix_high_outlined, onTap: _showEffects),
              const SizedBox(height: 18),
              _IconBtn(icon: Icons.tag_outlined, onTap: _insertHashtag),
              const SizedBox(height: 18),
              _IconBtn(
                icon:  _showEmoji
                    ? Icons.keyboard_outlined
                    : Icons.emoji_emotions_outlined,
                color: _showEmoji ? AppColors.primary : AppColors.textPrimary,
                onTap: _toggleEmoji,
              ),
            ]),
          ],
        ),
      ),
      if (_showEmoji)
        SizedBox(
          height: 280,
          child: EmojiPicker(
            onEmojiSelected: _onEmojiSelected,
            config: Config(
              height: 280,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: AppColors.bgPrimary,
                columns:         8,
                emojiSizeMax:    28,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor:   AppColors.bgPrimary,
                indicatorColor:    AppColors.primary,
                iconColorSelected: AppColors.primary,
                iconColor:         AppColors.textMuted,
                dividerColor:      const Color(0xFF1F1F1F),
              ),
              bottomActionBarConfig: BottomActionBarConfig(
                backgroundColor: AppColors.bgPrimary,
                buttonIconColor: AppColors.textMuted,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: AppColors.bgPrimary,
                buttonIconColor: AppColors.textMuted,
                hintText:        'Rechercher...',
                hintTextStyle:   GoogleFonts.inter(color: AppColors.textMuted),
                inputTextStyle:  GoogleFonts.inter(color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
    ]);
  }
}

// ─── Icon button ─────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final Color?       color;
  const _IconBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
  );
}

// ─── Text effects sheet ──────────────────────────────────────────────

class _TextEffectsSheet extends StatelessWidget {
  final TextEditingController controller;
  const _TextEffectsSheet({required this.controller});

  void _apply(String prefix, String suffix) {
    final sel   = controller.selection;
    final text  = controller.text;
    final start = sel.start < 0 ? 0 : sel.start;
    final end   = sel.end   < 0 ? text.length : sel.end;
    final selected = text.substring(start, end);
    if (selected.isEmpty) return;

    final newText = '${text.substring(0, start)}'
        '$prefix$selected$suffix'
        '${text.substring(end)}';
    controller.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(
          offset: start + prefix.length + selected.length + suffix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Effets de texte',
              style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize:   17,
              )),
          const SizedBox(height: 6),
          Text(
            'Sélectionne du texte dans la légende\npuis applique un effet',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _EffectChip(label: 'Gras',      preview: '**Texte**',
                  onTap: () { _apply('**', '**'); Navigator.pop(context); }),
              _EffectChip(label: 'Italique',  preview: '_Texte_',
                  onTap: () { _apply('_', '_'); Navigator.pop(context); }),
              _EffectChip(label: 'Souligné',  preview: '__Texte__',
                  onTap: () { _apply('__', '__'); Navigator.pop(context); }),
              _EffectChip(label: '🔥 Feu',     preview: '🔥 Texte 🔥',
                  onTap: () { _apply('🔥 ', ' 🔥'); Navigator.pop(context); }),
              _EffectChip(label: '✨ Brillant', preview: '✨Texte✨',
                  onTap: () { _apply('✨', '✨'); Navigator.pop(context); }),
              _EffectChip(label: '💥 Impact',  preview: '💥Texte💥',
                  onTap: () { _apply('💥', '💥'); Navigator.pop(context); }),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EffectChip extends StatelessWidget {
  final String       label;
  final String       preview;
  final VoidCallback onTap;
  const _EffectChip({required this.label, required this.preview, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(preview,
            style: const TextStyle(
              color:           Colors.white,
              fontSize:        13,
              decoration:      TextDecoration.none,
              decorationColor: Colors.transparent,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 10)),
      ]),
    ),
  );
}