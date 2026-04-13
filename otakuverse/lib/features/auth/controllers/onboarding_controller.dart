import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class OnboardingController extends GetxController {
  final _supabase = Supabase.instance.client;

  // ─── État ────────────────────────────────────────────────────────
  final currentStep   = 0.obs;
  final isLoading     = false.obs;
  final selectedGenres = <String>[].obs;
  final selectedAnimes = <String>[].obs;

  static const int totalSteps = 3;

  // ─── Genres disponibles ──────────────────────────────────────────
  static const genres = [
    ('Shonen',       '⚔️'),
    ('Shojo',        '💕'),
    ('Seinen',       '🔞'),
    ('Josei',        '🌸'),
    ('Isekai',       '🌀'),
    ('Mecha',        '🤖'),
    ('Slice of Life','☕'),
    ('Romance',      '💞'),
    ('Horreur',      '👻'),
    ('Thriller',     '🔪'),
    ('Sci-Fi',       '🚀'),
    ('Fantasy',      '🧙'),
    ('Sports',       '🏆'),
    ('Psychological','🧠'),
    ('Musical',      '🎵'),
    ('Comédie',      '😂'),
  ];

  // ─── Animes populaires ───────────────────────────────────────────
  static const animes = [
    ('One Piece',          'https://cdn.myanimelist.net/images/anime/6/73245.jpg',          'Shonen'),
    ('Naruto',             'https://cdn.myanimelist.net/images/anime/13/17405.jpg',         'Shonen'),
    ('Attack on Titan',    'https://cdn.myanimelist.net/images/anime/10/47347.jpg',         'Action'),
    ('Demon Slayer',       'https://cdn.myanimelist.net/images/anime/1286/99889.jpg',       'Shonen'),
    ('My Hero Academia',   'https://cdn.myanimelist.net/images/anime/10/78745.jpg',         'Shonen'),
    ('Jujutsu Kaisen',     'https://cdn.myanimelist.net/images/anime/1171/109222.jpg',      'Shonen'),
    ('Death Note',         'https://cdn.myanimelist.net/images/anime/9/9453.jpg',           'Thriller'),
    ('Fullmetal Alchemist','https://cdn.myanimelist.net/images/anime/1208/94745.jpg',       'Shonen'),
    ('Hunter x Hunter',    'https://cdn.myanimelist.net/images/anime/11/33657.jpg',         'Shonen'),
    ('Steins;Gate',        'https://cdn.myanimelist.net/images/anime/5/73199.jpg',          'Sci-Fi'),
    ('One Punch Man',      'https://cdn.myanimelist.net/images/anime/12/76049.jpg',         'Action'),
    ('Dragon Ball Z',      'https://cdn.myanimelist.net/images/anime/1277/142022.jpg',      'Shonen'),
    ('Sword Art Online',   'https://cdn.myanimelist.net/images/anime/11/39717.jpg',         'Isekai'),
    ('Tokyo Ghoul',        'https://cdn.myanimelist.net/images/anime/5/64449.jpg',          'Seinen'),
    ('Bleach',             'https://cdn.myanimelist.net/images/anime/3/40451.jpg',          'Shonen'),
    ('Code Geass',         'https://cdn.myanimelist.net/images/anime/5/50331.jpg',          'Mecha'),
    ('Cowboy Bebop',       'https://cdn.myanimelist.net/images/anime/4/19644.jpg',          'Sci-Fi'),
    ('Evangelion',         'https://cdn.myanimelist.net/images/anime/1314/108941.jpg',      'Mecha'),
    ('Your Name',          'https://cdn.myanimelist.net/images/anime/5/87048.jpg',          'Romance'),
    ('Violet Evergarden',  'https://cdn.myanimelist.net/images/anime/1795/95088.jpg',       'Drama'),
  ];

  // ─── Navigation étapes ───────────────────────────────────────────
  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  // ─── Toggle genre ────────────────────────────────────────────────
  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else {
      selectedGenres.add(genre);
    }
  }

  // ─── Toggle anime ────────────────────────────────────────────────
  void toggleAnime(String anime) {
    if (selectedAnimes.contains(anime)) {
      selectedAnimes.remove(anime);
    } else {
      selectedAnimes.add(anime);
    }
  }

  // ─── Sauvegarder dans Supabase ───────────────────────────────────
  Future<bool> saveAndFinish() async {
    isLoading.value = true;
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return false;

      await _supabase.from('profiles').upsert({
        'user_id':        uid,
        'favorite_genres': selectedGenres.toList(),
        'favorite_anime':  selectedAnimes.toList(),
        'updated_at':      DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Onboarding sauvegardé');
      return true;
    } catch (e) {
      debugPrint('❌ saveOnboarding: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder tes préférences',
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText:       AppColors.white,
        snackPosition:   SnackPosition.BOTTOM,
        margin:          const EdgeInsets.all(16),
        borderRadius:    12,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}