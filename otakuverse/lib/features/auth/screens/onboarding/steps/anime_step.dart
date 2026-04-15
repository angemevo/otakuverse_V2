import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import '../widgets/anime_card.dart';

class AnimeStep extends StatelessWidget {
  final OnboardingController ctrl;
  const AnimeStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ✅ Extraction locale — règle GetX obligatoire
      final selectedAnimes = ctrl.selectedAnimes.toList();
      

      return GridView.builder(
        padding:     const EdgeInsets.all(4),
        itemCount:   OnboardingController.animes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing:  8,
        ),
        itemBuilder: (_, index) {
          final anime      = OnboardingController.animes[index];
          final isSelected = selectedAnimes.contains(anime.$1);

          return AnimeCard(
            name:     anime.$1,
            imageUrl: anime.$2,
            // ✅ FIX — 'selected' (pas 'isSelected'), 'genre' retiré
            selected: isSelected,
            onTap:    () => ctrl.toggleAnime(anime.$1),
          );
        },
      );
    });
  }
}