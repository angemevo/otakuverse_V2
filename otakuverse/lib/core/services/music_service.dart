import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ─── Modèle ───────────────────────────────────────────────────────────
// ⚠️ Renommé SpotifyTrack → MusicTrack
// Mettre à jour les imports dans : create_post_screen.dart, music_section.dart

class MusicTrack {
  final String  id;
  final String  title;
  final String  artist;
  final String? previewUrl;
  final String? imageUrl;
  final int     durationMs;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.previewUrl,
    this.imageUrl,
    required this.durationMs,
  });

  String get durationFormatted {
    final d = Duration(milliseconds: durationMs);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Service ─────────────────────────────────────────────────────────

class MusicService {
  MusicService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ✅ Cache en mémoire pour les suggestions (évite un appel API à chaque ouverture)
  static List<MusicTrack>? _cachedSuggestions;

  // ─── Recherche ───────────────────────────────────────────────────────

  static Future<List<MusicTrack>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('🔍 Deezer search: "$query"');

      final response = await _dio.get(
        'https://api.deezer.com/search',
        queryParameters: {'q': query, 'limit': 25},
        options: Options(validateStatus: (s) => s != null),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Deezer ${response.statusCode}');
        return [];
      }

      final items = response.data['data'] as List? ?? [];
      debugPrint('✅ Deezer: ${items.length} résultats');

      return items
          .map(_fromDeezer)
          .whereType<MusicTrack>() // ✅ filtre les null silencieusement
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.response?.statusCode} — $e');
      return [];
    } catch (e) {
      debugPrint('❌ Deezer search error: $e');
      return [];
    }
  }

  // ─── Suggestions ─────────────────────────────────────────────────────

  static Future<List<MusicTrack>> getSuggestions() async {
    // ✅ Retourner le cache si disponible
    if (_cachedSuggestions != null) return _cachedSuggestions!;

    debugPrint('🎵 Chargement suggestions Deezer...');

    // ✅ Essai 1 — chart anime
    var results = await search('anime opening');

    // ✅ Essai 2 — fallback générique (sans année codée en dur)
    if (results.isEmpty) {
      results = await search('trending music');
    }

    if (results.isNotEmpty) {
      _cachedSuggestions = results;
    }

    return results;
  }

  /// Vide le cache (à appeler si besoin de forcer un rechargement)
  static void clearCache() => _cachedSuggestions = null;

  // ─── Mapping Deezer ─────────────────────────────────────────────────

  // ✅ Retourne null si les données sont invalides (filtrées par whereType)
  static MusicTrack? _fromDeezer(dynamic t) {
    try {
      final id    = t['id']?.toString();
      final title = t['title'] as String?;
      if (id == null || title == null) return null;

      // Deezer renvoie "" (chaîne vide) quand pas de preview → traiter comme null
      final rawPreview = t['preview'] as String?;
      final previewUrl = (rawPreview != null && rawPreview.isNotEmpty)
          ? rawPreview
          : null;

      return MusicTrack(
        id:         id,
        title:      title,
        artist:     (t['artist']?['name'] as String?) ?? 'Artiste inconnu',
        previewUrl: previewUrl,
        imageUrl:   t['album']?['cover_medium'] as String?,
        // Deezer renvoie la durée en secondes → convertir en ms
        durationMs: ((t['duration'] as int? ?? 30) * 1000),
      );
    } catch (e) {
      debugPrint('⚠️ _fromDeezer parsing error: $e');
      return null;
    }
  }
}
