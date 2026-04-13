import 'package:flutter/material.dart';

enum StoryProgressState { pending, active, completed }

/// Barre de progression d'une story individuelle.
/// Utilisée dans [StoryViewerHeader] pour afficher la progression
/// de chaque story dans un groupe.
class StoryProgressBar extends StatelessWidget {
  final StoryProgressState   state;
  final AnimationController? controller;

  const StoryProgressBar({
    super.key,
    required this.state,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2.5,
        child: state == StoryProgressState.active && controller != null
            ? AnimatedBuilder(
                animation: controller!,
                builder: (_, __) => LinearProgressIndicator(
                  value:           controller!.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight:       2.5,
                ),
              )
            : LinearProgressIndicator(
                value:           state == StoryProgressState.completed ? 1.0 : 0.0,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight:       2.5,
              ),
      ),
    );
  }
}