import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import '../widgets/anime_card.dart';

class AnimeStep extends StatelessWidget {
  final OnboardingController ctrl;
  const AnimeStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          16, 0, 16, 8),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
        childAspectRatio: 0.65,
      ),
      itemCount:
          OnboardingController.animes.length,
      itemBuilder: (_, i) {
        final anime =
            OnboardingController.animes[i];
        return AnimeCard(
          name:     anime.$1,
          imageUrl: anime.$2,
          selected: ctrl.selectedAnimes
              .contains(anime.$1),
          onTap: () {
            HapticFeedback.selectionClick();
            ctrl.toggleAnime(anime.$1);
          },
        );
      },
    ));
  }
}