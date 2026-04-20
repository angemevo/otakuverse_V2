import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';
import 'story_progress_bar.dart';

/// Header superposé sur le viewer de story.
/// Contient les barres de progression + info auteur + boutons action.
class StoryViewerHeader extends StatelessWidget {
  final StoryGroup           group;
  final StoryModel           story;
  final int                  storyIndex;
  final AnimationController  progressController;
  final VoidCallback         onClose;
  final VoidCallback?        onDelete;

  const StoryViewerHeader({
    super.key,
    required this.group,
    required this.story,
    required this.storyIndex,
    required this.progressController,
    required this.onClose,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          _buildProgressBars(),
          _buildAuthorRow(),
        ]),
      ),
    );
  }

  // ─── Barres de progression ────────────────────────────────────────

  Widget _buildProgressBars() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(group.stories.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: StoryProgressBar(
                state: i < storyIndex
                    ? StoryProgressState.completed
                    : i == storyIndex
                        ? StoryProgressState.active
                        : StoryProgressState.pending,
                controller: i == storyIndex ? progressController : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Ligne auteur ────────────────────────────────────────────────

  Widget _buildAuthorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        CachedAvatar(
          url:            group.avatarUrl,
          radius:         18,
          fallbackLetter: group.displayNameOrUsername,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.displayNameOrUsername,
                style: GoogleFonts.inter(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   14,
                ),
              ),
              Text(
                _formatTime(story.createdAt),
                style: GoogleFonts.inter(
                  color:    Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (group.isMe && onDelete != null)
          _StoryIconBtn(icon: Icons.more_horiz, onTap: onDelete!),
        _StoryIconBtn(icon: Icons.close, onTap: onClose),
      ]),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    return diff.inMinutes < 60
        ? 'il y a ${diff.inMinutes} min'
        : 'il y a ${diff.inHours} h';
  }
}

// ─── Compteur de vues (mes stories) ──────────────────────────────────

class StoryViewsCounter extends StatelessWidget {
  final int count;

  const StoryViewsCounter({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30, left: 0, right: 0,
      child: SafeArea(
        top: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:        Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.visibility_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                '$count vues',
                style: GoogleFonts.inter(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Bouton icône interne ────────────────────────────────────────────

class _StoryIconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;

  const _StoryIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child:   Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
