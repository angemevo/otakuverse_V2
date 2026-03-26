import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ✅ Modèle identique — rien à changer dans le reste du code
class SpotifyTrack {
  final String  id;
  final String  title;
  final String  artist;
  final String? previewUrl;
  final String? imageUrl;
  final int     durationMs;

  const SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.previewUrl,
    this.imageUrl,
    required this.durationMs,
  });

  String get durationFormatted {
    final d = Duration(milliseconds: durationMs);
    final m = d.inMinutes.remainder(60)
        .toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60)
        .toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ✅ Renommé MusicService — Deezer API
class SpotifyService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ─── RECHERCHE ─────────────────────────────────────────────────────
  static Future<List<SpotifyTrack>> search(
      String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('🔍 Deezer search: "$query"');

      final response = await _dio.get(
        'https://api.deezer.com/search',
        queryParameters: {
          'q':     query,
          'limit': 25,
        },
        options: Options(
          validateStatus: (s) => s != null,
        ),
      );

      if (response.statusCode != 200) {
        debugPrint(
            '❌ Deezer ${response.statusCode}');
        return [];
      }

      final items =
          response.data['data'] as List? ?? [];

      debugPrint(
          '✅ Deezer: ${items.length} résultats');

      return items
          .map((t) => _fromDeezer(t))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ Deezer DioException: '
          '${e.response?.statusCode} — $e');
      return [];
    } catch (e) {
      debugPrint('❌ Deezer error: $e');
      return [];
    }
  }

  // ─── SUGGESTIONS ───────────────────────────────────────────────────
  static Future<List<SpotifyTrack>>
      getSuggestions() async {
    // ✅ Chart Deezer Anime — gratuit sans clé
    try {
      debugPrint('🎵 Deezer suggestions...');

      // ✅ Essai 1 — chart anime
      final chart = await _dio.get(
        'https://api.deezer.com/search',
        queryParameters: {
          'q':     'anime opening',
          'limit': 25,
        },
        options: Options(
          validateStatus: (s) => s != null,
        ),
      );

      if (chart.statusCode == 200) {
        final items =
            chart.data['data'] as List? ?? [];
        if (items.isNotEmpty) {
          return items
              .map((t) => _fromDeezer(t))
              .toList();
        }
      }

      // ✅ Essai 2 — trending
      return search('trending 2024');
    } catch (e) {
      debugPrint(
          '❌ Deezer suggestions error: $e');
      return [];
    }
  }

  // ─── CONVERTIR UN ITEM DEEZER ──────────────────────────────────────
  static SpotifyTrack _fromDeezer(
      dynamic t) {
    return SpotifyTrack(
      id:    t['id'].toString(),
      title: t['title']            as String,
      artist: (t['artist']?['name']
              as String?) ??
          'Artiste inconnu',
      // ✅ Deezer fournit TOUJOURS un preview 30s
      previewUrl: t['preview']     as String?,
      imageUrl:   t['album']
              ?['cover_medium']    as String?,
      durationMs:
          ((t['duration'] as int? ?? 30) *
              1000),
    );
  }
}