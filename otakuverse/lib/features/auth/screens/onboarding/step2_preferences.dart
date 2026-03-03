import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';

class Step2Preferences extends StatelessWidget {
  const Step2Preferences({super.key});

  // ─── Données de référence ────────────────────────────────────────
  static const _genres = [
    'Action', 'Romance', 'Shonen', 'Shojo', 'Isekai',
    'Horreur', 'Comédie', 'Drame', 'Fantaisie', 'Sci-Fi',
    'Slice of Life', 'Sport', 'Mystère', 'Mecha', 'Psychologique',
  ];

  static const _topAnimes = [
    'Naruto', 'One Piece', 'Dragon Ball Z', 'Attack on Titan',
    'Demon Slayer', 'Jujutsu Kaisen', 'My Hero Academia',
    'Fullmetal Alchemist', 'Death Note', 'Hunter x Hunter',
    'Sword Art Online', 'Re:Zero', 'Tokyo Ghoul', 'Bleach',
    'One Punch Man', 'Steins;Gate', 'Code Geass', 'Vinland Saga',
  ];

  static const _topMangas = [
    'Berserk', 'Vagabond', 'One Piece', 'Naruto', 'Chainsaw Man',
    'Jujutsu Kaisen', 'Attack on Titan', 'Demon Slayer',
    'Dorohedoro', 'Oyasumi Punpun', 'Monster', 'Vinland Saga',
    'Homunculus', 'Gantz', 'Tokyo Ghoul', 'Blue Period',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ─── Titre ─────────────────────────────────────────
          Text(
            'Tes préférences 🎌',
            style: GoogleFonts.poppins(
              color: AppColors.pureWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionne ce que tu aimes — tu pourras modifier ça plus tard',
            style: GoogleFonts.inter(
                color: AppColors.mediumGray, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // ─── Genres ────────────────────────────────────────
          _buildSectionTitle('Genres favoris'),
          const SizedBox(height: 12),
          Obx(() => _buildChipSelector(
            items: _genres,
            selected: controller.selectedGenres,
            onTap: controller.toggleGenre,
          )),
          const SizedBox(height: 28),

          // ─── Animés ────────────────────────────────────────
          _buildSectionTitle('Animés favoris'),
          const SizedBox(height: 12),
          Obx(() => _buildChipSelector(
            items: _topAnimes,
            selected: controller.selectedAnimes,
            onTap: controller.toggleAnime,
          )),
          const SizedBox(height: 28),

          // ─── Mangas ────────────────────────────────────────
          _buildSectionTitle('Mangas favoris'),
          const SizedBox(height: 12),
          Obx(() => _buildChipSelector(
            items: _topMangas,
            selected: controller.selectedMangas,
            onTap: controller.toggleManga,
          )),
          const SizedBox(height: 40),

          // ─── Boutons nav ───────────────────────────────────
          Row(
            children: [
              // Retour
              OutlinedButton(
                onPressed: controller.previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.mediumGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 52),
                ),
                child: Text(
                  '← Retour',
                  style: GoogleFonts.inter(color: AppColors.mediumGray),
                ),
              ),
              const SizedBox(width: 12),

              // Terminer
              Expanded(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimsonRed,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.pureWhite,
                          ),
                        )
                      : Text(
                          'Terminer 🎉',
                          style: GoogleFonts.inter(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: AppColors.pureWhite,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> items,
    required RxList<String> selected,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () => onTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimsonWithOpacity(0.15)
                  : AppColors.darkGray,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimsonRed
                    : AppColors.mediumGray.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              item,
              style: GoogleFonts.inter(
                color: isSelected
                    ? AppColors.crimsonRed
                    : AppColors.mediumGray,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}