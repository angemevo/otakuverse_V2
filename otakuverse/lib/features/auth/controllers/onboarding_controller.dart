import 'package:get/get.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class OnboardingController extends GetxController {
  final _supabase = Supabase.instance.client;

  final currentStep    = 0.obs;
  final isLoading      = false.obs;
  final selectedGenres = <String>[].obs;
  final selectedAnimes = <String>[].obs;

  static const int totalSteps = 3;

  // ─── Genres ──────────────────────────────────────────────────────

  static const genres = [
    ('Shonen',        '⚔️'),
    ('Shojo',         '💕'),
    ('Seinen',        '🔞'),
    ('Josei',         '🌸'),
    ('Isekai',        '🌀'),
    ('Mecha',         '🤖'),
    ('Slice of Life', '☕'),
    ('Romance',       '💞'),
    ('Horreur',       '👻'),
    ('Thriller',      '🔪'),
    ('Sci-Fi',        '🚀'),
    ('Fantasy',       '🧙'),
    ('Sports',        '🏆'),
    ('Psychological', '🧠'),
    ('Musical',       '🎵'),
    ('Comédie',       '😂'),
  ];

  // ─── Animés — 5+ par genre, 0 doublon ────────────────────────────
  // Format : (titre, url_cover_MAL, genre)

  static const animes = [

    // ── Shonen (8) ───────────────────────────────────────────────
    ('One Piece',            'https://cdn.myanimelist.net/images/anime/6/73245.jpg',      'Shonen'),
    ('Naruto',               'https://cdn.myanimelist.net/images/anime/13/17405.jpg',     'Shonen'),
    ('Demon Slayer',         'https://cdn.myanimelist.net/images/anime/1286/99889.jpg',   'Shonen'),
    ('My Hero Academia',     'https://cdn.myanimelist.net/images/anime/10/78745.jpg',     'Shonen'),
    ('Jujutsu Kaisen',       'https://cdn.myanimelist.net/images/anime/1171/109222.jpg',  'Shonen'),
    ('Dragon Ball Z',        'https://cdn.myanimelist.net/images/anime/1277/142022.jpg',  'Shonen'),
    ('Bleach',               'https://cdn.myanimelist.net/images/anime/3/40451.jpg',      'Shonen'),
    ('Fullmetal Alchemist',  'https://cdn.myanimelist.net/images/anime/1208/94745.jpg',   'Shonen'),

    // ── Shojo (5) ─────────────────────────────────────────────────
    ('Fruits Basket',        'https://cdn.myanimelist.net/images/anime/1904/102352.jpg',  'Shojo'),
    ('Cardcaptor Sakura',    'https://cdn.myanimelist.net/images/anime/1/35586.jpg',      'Shojo'),
    ('Sailor Moon',          'https://cdn.myanimelist.net/images/anime/3/88528.jpg',      'Shojo'),
    ('Ouran Host Club',      'https://cdn.myanimelist.net/images/anime/10/73274.jpg',     'Shojo'),
    ('Kimi ni Todoke',       'https://cdn.myanimelist.net/images/anime/7/21001.jpg',      'Shojo'),

    // ── Seinen (5) ────────────────────────────────────────────────
    ('Tokyo Ghoul',          'https://cdn.myanimelist.net/images/anime/5/64449.jpg',      'Seinen'),
    ('Berserk',              'https://cdn.myanimelist.net/images/anime/1388/101146.jpg',  'Seinen'),
    ('Vinland Saga',         'https://cdn.myanimelist.net/images/anime/1500/103005.jpg',  'Seinen'),
    ('Chainsaw Man',         'https://cdn.myanimelist.net/images/anime/1806/126216.jpg',  'Seinen'),
    ('Parasyte',             'https://cdn.myanimelist.net/images/anime/3/73248.jpg',      'Seinen'),

    // ── Josei (5) ─────────────────────────────────────────────────
    ('Nana',                 'https://cdn.myanimelist.net/images/anime/3/22534.jpg',      'Josei'),
    ('Chihayafuru',          'https://cdn.myanimelist.net/images/anime/7/67839.jpg',      'Josei'),
    ('Nodame Cantabile',     'https://cdn.myanimelist.net/images/anime/11/23265.jpg',     'Josei'),
    ('Honey and Clover',     'https://cdn.myanimelist.net/images/anime/4/7229.jpg',       'Josei'),
    ('Paradise Kiss',        'https://cdn.myanimelist.net/images/anime/1/11727.jpg',      'Josei'),

    // ── Isekai (6) ────────────────────────────────────────────────
    ('Sword Art Online',     'https://cdn.myanimelist.net/images/anime/11/39717.jpg',     'Isekai'),
    ('Re:Zero',              'https://cdn.myanimelist.net/images/anime/11/78914.jpg',     'Isekai'),
    ('Reincarnated as Slime','https://cdn.myanimelist.net/images/anime/1271/98922.jpg',   'Isekai'),
    ('Overlord',             'https://cdn.myanimelist.net/images/anime/7/88019.jpg',      'Isekai'),
    ('No Game No Life',      'https://cdn.myanimelist.net/images/anime/1/62462.jpg',      'Isekai'),
    ('KonoSuba',             'https://cdn.myanimelist.net/images/anime/4/81262.jpg',      'Isekai'),

    // ── Mecha (5) ─────────────────────────────────────────────────
    ('Code Geass',           'https://cdn.myanimelist.net/images/anime/5/50331.jpg',      'Mecha'),
    ('Neon Genesis Eva',     'https://cdn.myanimelist.net/images/anime/1314/108941.jpg',  'Mecha'),
    ('Gurren Lagann',        'https://cdn.myanimelist.net/images/anime/4/9983.jpg',       'Mecha'),
    ('Darling in FranXX',    'https://cdn.myanimelist.net/images/anime/8/88700.jpg',      'Mecha'),
    ('Gundam Wing',          'https://cdn.myanimelist.net/images/anime/2/5841.jpg',       'Mecha'),

    // ── Slice of Life (5) ─────────────────────────────────────────
    ('K-On!',                'https://cdn.myanimelist.net/images/anime/10/26889.jpg',     'Slice of Life'),
    ('Anohana',              'https://cdn.myanimelist.net/images/anime/1369/93799.jpg',   'Slice of Life'),
    ('Hyouka',               'https://cdn.myanimelist.net/images/anime/13/50521.jpg',     'Slice of Life'),
    ('Barakamon',            'https://cdn.myanimelist.net/images/anime/1791/94271.jpg',   'Slice of Life'),
    ('March Comes Like Lion','https://cdn.myanimelist.net/images/anime/12/86572.jpg',     'Slice of Life'),

    // ── Romance (5) ───────────────────────────────────────────────
    ('Your Name',            'https://cdn.myanimelist.net/images/anime/5/87048.jpg',      'Romance'),
    ('Toradora',             'https://cdn.myanimelist.net/images/anime/13/22128.jpg',     'Romance'),
    ('Kaguya-sama',          'https://cdn.myanimelist.net/images/anime/1795/100476.jpg',  'Romance'),
    ('Clannad',              'https://cdn.myanimelist.net/images/anime/1079/111269.jpg',  'Romance'),
    ('Ore Monogatari',       'https://cdn.myanimelist.net/images/anime/9/67923.jpg',      'Romance'),

    // ── Horreur (5) ───────────────────────────────────────────────
    ('Another',              'https://cdn.myanimelist.net/images/anime/1/24547.jpg',      'Horreur'),
    ('Higurashi',            'https://cdn.myanimelist.net/images/anime/3/22005.jpg',      'Horreur'),
    ('Shiki',                'https://cdn.myanimelist.net/images/anime/12/24023.jpg',     'Horreur'),
    ('Junji Ito Collection', 'https://cdn.myanimelist.net/images/anime/3/87523.jpg',      'Horreur'),
    ('Hell Girl',            'https://cdn.myanimelist.net/images/anime/8/26024.jpg',      'Horreur'),

    // ── Thriller (5) ──────────────────────────────────────────────
    ('Death Note',           'https://cdn.myanimelist.net/images/anime/9/9453.jpg',       'Thriller'),
    ('Monster',              'https://cdn.myanimelist.net/images/anime/11/15539.jpg',     'Thriller'),
    ('91 Days',              'https://cdn.myanimelist.net/images/anime/1782/90955.jpg',   'Thriller'),
    ('Terror in Resonance',  'https://cdn.myanimelist.net/images/anime/12/68981.jpg',     'Thriller'),
    ('Erased',               'https://cdn.myanimelist.net/images/anime/10/76842.jpg',     'Thriller'),

    // ── Sci-Fi (5) ────────────────────────────────────────────────
    ('Steins;Gate',          'https://cdn.myanimelist.net/images/anime/5/73199.jpg',      'Sci-Fi'),
    ('Cowboy Bebop',         'https://cdn.myanimelist.net/images/anime/4/19644.jpg',      'Sci-Fi'),
    ('Ghost in the Shell',   'https://cdn.myanimelist.net/images/anime/3/21000.jpg',      'Sci-Fi'),
    ('Psycho-Pass',          'https://cdn.myanimelist.net/images/anime/13/46285.jpg',     'Sci-Fi'),
    ('Attack on Titan',      'https://cdn.myanimelist.net/images/anime/10/47347.jpg',     'Sci-Fi'),

    // ── Fantasy (5) ───────────────────────────────────────────────
    ('Made in Abyss',        'https://cdn.myanimelist.net/images/anime/6/86733.jpg',      'Fantasy'),
    ('Mushishi',             'https://cdn.myanimelist.net/images/anime/3/4665.jpg',       'Fantasy'),
    ('Spice and Wolf',       'https://cdn.myanimelist.net/images/anime/9/23988.jpg',      'Fantasy'),
    ('Fate/Zero',            'https://cdn.myanimelist.net/images/anime/10/83981.jpg',     'Fantasy'),
    ('Hunter x Hunter',      'https://cdn.myanimelist.net/images/anime/11/33657.jpg',     'Fantasy'),

    // ── Sports (5) ────────────────────────────────────────────────
    ('Haikyuu!!',            'https://cdn.myanimelist.net/images/anime/7/76014.jpg',      'Sports'),
    ('Kuroko no Basket',     'https://cdn.myanimelist.net/images/anime/3/55725.jpg',      'Sports'),
    ('Slam Dunk',            'https://cdn.myanimelist.net/images/anime/3/22817.jpg',      'Sports'),
    ('Free!',                'https://cdn.myanimelist.net/images/anime/7/64028.jpg',      'Sports'),
    ('Hajime no Ippo',       'https://cdn.myanimelist.net/images/anime/8/23092.jpg',      'Sports'),

    // ── Psychological (5) ─────────────────────────────────────────
    ('Promised Neverland',   'https://cdn.myanimelist.net/images/anime/1176/93083.jpg',   'Psychological'),
    ('Kakegurui',            'https://cdn.myanimelist.net/images/anime/1051/88726.jpg',   'Psychological'),
    ('Classroom of the Elite','https://cdn.myanimelist.net/images/anime/4/85729.jpg',     'Psychological'),
    ('Serial Experiments Lain','https://cdn.myanimelist.net/images/anime/7/5561.jpg',     'Psychological'),
    ('Paranoia Agent',       'https://cdn.myanimelist.net/images/anime/1/13269.jpg',      'Psychological'),

    // ── Musical (5) ───────────────────────────────────────────────
    ('Your Lie in April',    'https://cdn.myanimelist.net/images/anime/3/67177.jpg',      'Musical'),
    ('Hibike! Euphonium',    'https://cdn.myanimelist.net/images/anime/12/79592.jpg',     'Musical'),
    ('Bocchi the Rock!',     'https://cdn.myanimelist.net/images/anime/1448/127956.jpg',  'Musical'),
    ('Beck',                 'https://cdn.myanimelist.net/images/anime/2/6979.jpg',       'Musical'),
    ('Carole & Tuesday',     'https://cdn.myanimelist.net/images/anime/1843/103616.jpg',  'Musical'),

    // ── Comédie (5) ───────────────────────────────────────────────
    ('Gintama',              'https://cdn.myanimelist.net/images/anime/3/72078.jpg',      'Comédie'),
    ('Daily Lives HS Boys',  'https://cdn.myanimelist.net/images/anime/6/35271.jpg',      'Comédie'),
    ('Grand Blue',           'https://cdn.myanimelist.net/images/anime/1304/92289.jpg',   'Comédie'),
    ('Nichijou',             'https://cdn.myanimelist.net/images/anime/4/55126.jpg',      'Comédie'),
    ('Saiki K',              'https://cdn.myanimelist.net/images/anime/4/81962.jpg',      'Comédie'),
  ];

  // ─── Navigation ──────────────────────────────────────────────────

  void nextStep() {
    if (currentStep.value < totalSteps - 1) currentStep.value++;
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) selectedGenres.remove(genre);
    else selectedGenres.add(genre);
  }

  void toggleAnime(String anime) {
    if (selectedAnimes.contains(anime)) selectedAnimes.remove(anime);
    else selectedAnimes.add(anime);
  }

  // ─── Filtrage par genres sélectionnés ────────────────────────────
  /// Utilisé dans anime_step pour n'afficher que les animés
  /// correspondant aux genres choisis à l'étape précédente.
  /// Si aucun genre → tous les animés.
  List<(String, String, String)> get filteredAnimes {
    if (selectedGenres.isEmpty) return animes.toList();
    return animes
        .where((a) => selectedGenres.contains(a.$3))
        .toList();
  }

  // ─── Validation ──────────────────────────────────────────────────

  bool get canFinish =>
      selectedGenres.isNotEmpty && selectedAnimes.isNotEmpty;

  // ─── Sauvegarder ─────────────────────────────────────────────────

  Future<bool> saveAndFinish() async {
    if (!canFinish) {
      Helpers.showWarningSnackbar(
          'Sélectionne au moins 1 genre et 1 anime pour continuer');
      return false;
    }
    isLoading.value = true;
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) {
        Helpers.showErrorSnackbar('Session introuvable, reconnecte-toi');
        return false;
      }
      await _supabase.from('profiles').update({
        'favorite_genres': selectedGenres.toList(),
        'favorite_anime':  selectedAnimes.toList(),
        'updated_at':      DateTime.now().toIso8601String(),
      }).eq('user_id', uid);

      debugPrint('✅ Onboarding — '
          '${selectedGenres.length} genres, ${selectedAnimes.length} animes');
      return true;
    } catch (e) {
      debugPrint('❌ saveOnboarding: $e');
      Helpers.showErrorSnackbar('Impossible de sauvegarder tes préférences');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}