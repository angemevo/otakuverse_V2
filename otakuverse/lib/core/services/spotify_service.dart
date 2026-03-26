// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class SpotifyTrack {
//   final String  id;
//   final String  title;
//   final String  artist;
//   final String? previewUrl;
//   final String? imageUrl;
//   final int     durationMs;

//   const SpotifyTrack({
//     required this.id,
//     required this.title,
//     required this.artist,
//     this.previewUrl,
//     this.imageUrl,
//     required this.durationMs,
//   });

//   factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
//     final artists = (json['artists'] as List? ?? [])
//         .map((a) => a['name'] as String)
//         .join(', ');

//     final images =
//         json['album']?['images'] as List?;
//     final imageUrl =
//         images != null && images.isNotEmpty
//             ? images.first['url'] as String?
//             : null;

//     return SpotifyTrack(
//       id:         json['id']   as String,
//       title:      json['name'] as String,
//       artist:     artists.isEmpty
//           ? 'Artiste inconnu'
//           : artists,
//       previewUrl: json['preview_url'] as String?,
//       imageUrl:   imageUrl,
//       durationMs: json['duration_ms'] as int? ?? 0,
//     );
//   }

//   String get durationFormatted {
//     final d = Duration(milliseconds: durationMs);
//     final m = d.inMinutes.remainder(60)
//         .toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60)
//         .toString().padLeft(2, '0');
//     return '$m:$s';
//   }
// }

// class SpotifyService {
//   static final _dio = Dio(BaseOptions(
//     connectTimeout: const Duration(seconds: 15),
//     receiveTimeout: const Duration(seconds: 15),
//   ));

//   static String?   _accessToken;
//   static DateTime? _tokenExpiry;

//   // ─── OBTENIR UN TOKEN ─────────────────────────────────────────────
//   static Future<String?> _getToken() async {
//     // ✅ Token encore valide
//     if (_accessToken != null &&
//         _tokenExpiry  != null &&
//         DateTime.now().isBefore(
//             _tokenExpiry!.subtract(
//                 const Duration(seconds: 30)))) {
//       return _accessToken;
//     }

//     final clientId =
//         dotenv.env['SPOTIFY_CLIENT_ID']     ?? '';
//     final clientSecret =
//         dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

//     if (kDebugMode) {
//       debugPrint('🎵 ClientId     : '
//           '${clientId.isEmpty ? "❌ VIDE" : "✅ ${clientId.substring(0, 6)}..."}');
//       debugPrint('🎵 ClientSecret : '
//           '${clientSecret.isEmpty ? "❌ VIDE" : "✅ présent"}');
//     }

//     if (clientId.isEmpty || clientSecret.isEmpty) {
//       debugPrint('❌ Clés Spotify manquantes dans .env');
//       return null;
//     }

//     try {
//       final credentials = base64Encode(
//           utf8.encode('$clientId:$clientSecret'));

//       final response = await _dio.post(
//         'https://accounts.spotify.com/api/token',
//         data: 'grant_type=client_credentials',
//         options: Options(
//           headers: {
//             'Authorization': 'Basic $credentials',
//             'Content-Type':
//                 'application/x-www-form-urlencoded',
//           },
//           // ✅ Ne pas throw sur les erreurs HTTP
//           validateStatus: (status) => status != null,
//         ),
//       );

//       if (kDebugMode) {
//         debugPrint('🎵 Token response: '
//             '${response.statusCode}');
//       }

//       if (response.statusCode == 200) {
//         _accessToken =
//             response.data['access_token'] as String;
//         _tokenExpiry = DateTime.now().add(
//           Duration(
//             seconds:
//                 response.data['expires_in'] as int,
//           ),
//         );
//         debugPrint('✅ Token Spotify obtenu');
//         return _accessToken;
//       }

//       // ✅ Log précis selon le code d'erreur
//       _logTokenError(
//           response.statusCode, response.data);
//       return null;
//     } catch (e) {
//       debugPrint('❌ Token exception: $e');
//       return null;
//     }
//   }

//   static void _logTokenError(
//       int? status, dynamic data) {
//     switch (status) {
//       case 400:
//         debugPrint('❌ 400 Bad Request — '
//             'Vérifie le format des clés');
//         break;
//       case 401:
//         debugPrint('❌ 401 Unauthorized — '
//             'Client ID ou Secret incorrect');
//         break;
//       case 403:
//         debugPrint('❌ 403 Forbidden — '
//             'App non autorisée. '
//             'Accepte les ToS sur le dashboard Spotify');
//         break;
//       default:
//         debugPrint(
//             '❌ Erreur $status — $data');
//     }
//   }

//   // ─── RECHERCHE ────────────────────────────────────────────────────
//   static Future<List<SpotifyTrack>> search(
//       String query) async {
//     if (query.trim().isEmpty) return [];

//     final token = await _getToken();
//     if (token == null) {
//       debugPrint('❌ Search annulé — pas de token');
//       return [];
//     }

//     try {
//       debugPrint('🔍 Recherche: "$query"');

//       final response = await _dio.get(
//         'https://api.spotify.com/v1/search',
//         queryParameters: {
//           'q':     query,
//           'type':  'track',
//           'limit': 20,
//           // ✅ market retiré — cause de 403 dans certaines régions
//         },
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $token',
//           },
//           validateStatus: (status) => status != null,
//         ),
//       );

//       if (kDebugMode) {
//         debugPrint('🎵 Search status: '
//             '${response.statusCode}');
//       }

//       if (response.statusCode == 200) {
//         final items = response
//                 .data['tracks']['items'] as List? ??
//             [];
//         debugPrint(
//             '✅ ${items.length} résultats');
//         return items
//             .map((t) => SpotifyTrack.fromJson(
//                 t as Map<String, dynamic>))
//             .toList();
//       }

//       // ✅ Token expiré → reset et réessayer
//       if (response.statusCode == 401) {
//         debugPrint(
//             '🔄 Token expiré → reset');
//         _resetToken();
//         return search(query); // ✅ Réessayer
//       }

//       if (response.statusCode == 403) {
//         debugPrint(
//             '❌ 403 — Vérifie le dashboard Spotify:\n'
//             '  1. developer.spotify.com/dashboard\n'
//             '  2. Accepte les Terms of Service\n'
//             '  3. Ajoute ton email dans "Users and Access"');
//       }

//       return [];
//     } catch (e) {
//       debugPrint('❌ Search exception: $e');
//       return [];
//     }
//   }

//   // ─── SUGGESTIONS ─────────────────────────────────────────────────
//   static Future<List<SpotifyTrack>>
//       getSuggestions() async {
//     // ✅ Essayer plusieurs requêtes
//     final queries = [
//       'anime ost',
//       'demon slayer',
//       'one piece ost',
//       'attack on titan',
//     ];

//     for (final q in queries) {
//       final results = await search(q);
//       if (results.isNotEmpty) return results;
//     }
//     return [];
//   }

//   // ─── RESET ───────────────────────────────────────────────────────
//   static void _resetToken() {
//     _accessToken = null;
//     _tokenExpiry = null;
//   }
// }
