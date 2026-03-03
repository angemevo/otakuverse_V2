import 'package:get/get.dart';
import 'package:otakuverse/features/profile/services/profile_service.dart';

class OnboardingController extends GetxController {
  final _profileService = ProfileService();

  final currentStep = 0.obs;
  final isLoading   = false.obs;

  // ─── Step 1 : Infos de base ──────────────────────────────────────
  final displayName = ''.obs;
  final birthDate   = Rxn<DateTime>();
  final gender      = Rxn<String>();
  final location    = ''.obs;

  // ─── Step 2 : Préférences ────────────────────────────────────────
  final selectedGenres = <String>[].obs;
  final selectedAnimes = <String>[].obs;
  final selectedMangas = <String>[].obs;
  final selectedGames  = <String>[].obs;

  // ─── Navigation ──────────────────────────────────────────────────
  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    } else {
      _saveAndFinish();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  // ─── Sauvegarde finale ───────────────────────────────────────────
  Future<void> _saveAndFinish() async {
    isLoading.value = true;
    try {
      await _profileService.updateProfile(
        displayName:     displayName.value.isEmpty ? null : displayName.value,
        gender:          gender.value,
        location:        location.value.isEmpty ? null : location.value,
        birthDate:       birthDate.value,
        favoriteGenres:  selectedGenres,
        favoriteAnimes:  selectedAnimes,
        favoriteMangas:  selectedMangas,
        favoriteGames:   selectedGames,
      );
      Get.offAllNamed('/home');
    } catch (_) {
      // On va quand même à home si ça échoue — pas bloquant
      Get.offAllNamed('/home');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else {
      selectedGenres.add(genre);
    }
  }

  void toggleAnime(String anime) {
    if (selectedAnimes.contains(anime)) {
      selectedAnimes.remove(anime);
    } else {
      selectedAnimes.add(anime);
    }
  }

  void toggleManga(String manga) {
    if (selectedMangas.contains(manga)) {
      selectedMangas.remove(manga);
    } else {
      selectedMangas.add(manga);
    }
  }
}