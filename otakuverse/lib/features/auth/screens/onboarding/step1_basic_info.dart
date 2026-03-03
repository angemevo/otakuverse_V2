import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';

class Step1BasicInfo extends StatelessWidget {
  const Step1BasicInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ─── Titre ────────────────────────────────────────────
          Text(
            'Parle-nous de toi 👤',
            style: GoogleFonts.poppins(
              color: AppColors.pureWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ces infos seront visibles sur ton profil',
            style: GoogleFonts.inter(
              color: AppColors.mediumGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // ─── Nom d'affichage ──────────────────────────────────
          _buildLabel('Nom d\'affichage'),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Comment veux-tu être appelé ?',
            icon: Icons.badge_outlined,
            onChanged: (v) => controller.displayName.value = v,
          ),
          const SizedBox(height: 20),

          // ─── Genre ────────────────────────────────────────────
          _buildLabel('Genre'),
          const SizedBox(height: 8),
          Obx(() => _buildGenderSelector(controller)),
          const SizedBox(height: 20),

          // ─── Date de naissance ────────────────────────────────
          _buildLabel('Date de naissance'),
          const SizedBox(height: 8),
          Obx(() => _buildDatePicker(context, controller)),
          const SizedBox(height: 20),

          // ─── Localisation ────────────────────────────────────
          _buildLabel('Ville / Pays (optionnel)'),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Ex: Abidjan, Côte d\'Ivoire',
            icon: Icons.location_on_outlined,
            onChanged: (v) => controller.location.value = v,
          ),
          const SizedBox(height: 40),

          // ─── Bouton suivant ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimsonRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continuer →',
                style: GoogleFonts.inter(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gender selector ─────────────────────────────────────────────
  Widget _buildGenderSelector(OnboardingController controller) {
    final genders = [
      ('male', 'Homme', Icons.male),
      ('female', 'Femme', Icons.female),
      ('other', 'Autre', Icons.transgender),
      ('prefer_not_to_say', 'Non précisé', Icons.remove_circle_outline),
    ];

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: genders.map(((String value, String label, IconData icon) gender) {
        final isSelected = controller.gender.value == gender.$1;
        return GestureDetector(
          onTap: () => controller.gender.value = gender.$1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimsonWithOpacity(0.15)
                  : AppColors.darkGray,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimsonRed
                    : AppColors.mediumGray.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(gender.$3,
                    size: 16,
                    color: isSelected
                        ? AppColors.crimsonRed
                        : AppColors.mediumGray),
                const SizedBox(width: 6),
                Text(
                  gender.$2,
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
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Date picker ─────────────────────────────────────────────────
  Widget _buildDatePicker(
      BuildContext context, OnboardingController controller) {
    final date = controller.birthDate.value;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.crimsonRed,
                surface: AppColors.darkGray,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) controller.birthDate.value = picked;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? AppColors.crimsonRed
                : AppColors.mediumGray.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined,
                color: AppColors.crimsonRed, size: 20),
            const SizedBox(width: 12),
            Text(
              date != null
                  ? DateFormat('dd MMMM yyyy', 'fr').format(date)
                  : 'Sélectionner ta date de naissance',
              style: GoogleFonts.inter(
                color: date != null
                    ? AppColors.pureWhite
                    : AppColors.mediumGray,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.mediumGray,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.inter(color: AppColors.pureWhite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.mediumGray),
        prefixIcon: Icon(icon, color: AppColors.crimsonRed, size: 20),
        filled: true,
        fillColor: AppColors.darkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.crimsonRed, width: 1.5),
        ),
      ),
    );
  }
}