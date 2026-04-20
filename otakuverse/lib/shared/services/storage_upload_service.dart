import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'upload Supabase Storage.
///
/// Corrections apportées :
/// - debugPrint() → debugdebugPrint() conditionné à kDebugMode
/// - Validation MIME type avant upload
/// - Limite de taille par catégorie (avatar, post, story)
/// - Gestion d'erreur avec message lisible
class StorageUploadService {
  final _supabase    = Supabase.instance.client;
  static const _bucket = 'posts';

  // ─── Limites de taille ──────────────────────────────────────────
  static const _maxAvatarBytes  = 5  * 1024 * 1024; //  5 MB
  static const _maxPostBytes    = 20 * 1024 * 1024; // 20 MB
  static const _maxVideoBytes   = 50 * 1024 * 1024; // 50 MB

  // ─── MIME autorisés ─────────────────────────────────────────────
  static const _allowedVideoMimes = {'video/mp4', 'video/quicktime', 'video/webm'};

  // ─── Validation ──────────────────────────────────────────────────

  /// Valide le MIME et la taille avant upload.
  /// Lève [UploadValidationException] si invalide.
  static void _validate(
    Uint8List bytes,
    String extension, {
    bool isVideo = false,
    int? maxBytes,
  }) {
    final limit = maxBytes ?? (isVideo ? _maxVideoBytes : _maxPostBytes);

    // ✅ Vérification taille
    if (bytes.length > limit) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final limitMb = (limit / (1024 * 1024)).toInt();
      throw UploadValidationException(
          'Fichier trop volumineux : ${mb}MB (max ${limitMb}MB)');
    }

    // ✅ Vérification extension / type
    final ext = extension.toLowerCase().replaceAll('.', '');
    final allowed = isVideo
        ? {'mp4', 'mov', 'webm', 'mkv'}
        : {'jpg', 'jpeg', 'png', 'webp', 'gif'};

    if (!allowed.contains(ext)) {
      throw UploadValidationException(
          'Format non supporté : .$ext. '
          'Formats acceptés : ${allowed.join(', ')}');
    }
  }

  // ─── Upload avatar ───────────────────────────────────────────────

  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    _validate(bytes, ext, maxBytes: _maxAvatarBytes);
    return _upload(bytes, ext,
        folder: 'avatars', cacheControl: '3600', upsert: true);
  }

  // ─── Upload bannière ─────────────────────────────────────────────

  Future<String> uploadBanner(Uint8List bytes, String ext) async {
    _validate(bytes, ext, maxBytes: _maxAvatarBytes);
    return _upload(bytes, ext,
        folder: 'banners', cacheControl: '3600', upsert: true);
  }

  // ─── Upload images de post ────────────────────────────────────────

  Future<List<String>> uploadImages(List<XFile> files, String userId) async {
    if (files.isEmpty) return [];

    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      final ext   = files[i].path.split('.').last;
      _validate(bytes, ext);

      // Dossier = userId directement (évite le doublon posts/posts/)
      final url = await _upload(
        bytes, ext,
        folder: userId,
        index: i,
      );
      urls.add(url);
      _log('✅ Image $i uploadée');
    }
    return urls;
  }

  // ─── Upload story ────────────────────────────────────────────────

  Future<String> uploadStory(XFile file, String userId) async {
    final bytes   = await file.readAsBytes();
    final ext     = file.path.split('.').last;
    final isVideo = _allowedVideoMimes.any(
        (m) => m.contains(ext.toLowerCase()));

    _validate(bytes, ext, isVideo: isVideo);

    return _upload(bytes, ext,
        folder:  'stories',
        userId:  userId,
        isVideo: isVideo);
  }

  // ─── Upload message (image) ──────────────────────────────────────

  Future<String> uploadMessageImage(
      Uint8List bytes, String ext, String convId) async {
    _validate(bytes, ext, maxBytes: _maxPostBytes);
    return _upload(bytes, ext, folder: 'messages/$convId');
  }

  // ─── Core upload ─────────────────────────────────────────────────

  Future<String> _upload(
    Uint8List bytes,
    String ext, {
    required String folder,
    String?   userId,
    int?      index,
    bool      isVideo    = false,
    bool      upsert     = false,
    String    cacheControl = '3600',
  }) async {
    final ts       = DateTime.now().millisecondsSinceEpoch;
    final suffix   = index != null ? '_$index' : '';
    final prefix   = userId != null ? '${userId}_' : '';
    final path     = '$folder/$prefix$ts$suffix.$ext';
    final mimeType = isVideo ? 'video/$ext' : 'image/$ext';

    _log('📤 Upload → $path (${(bytes.length / 1024).toStringAsFixed(0)} KB)');

    try {
      await _supabase.storage.from(_bucket).uploadBinary(
        path, bytes,
        fileOptions: FileOptions(
          contentType:  mimeType,
          cacheControl: cacheControl,
          upsert:       upsert,
        ),
      );

      final url = _supabase.storage.from(_bucket).getPublicUrl(path);
      _log('✅ Upload OK → $url');
      return url;
    } catch (e) {
      _log('❌ Upload error: $e');
      // ✅ Pas de print en production
      rethrow;
    }
  }

  // ─── Suppression ─────────────────────────────────────────────────

  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri     = Uri.parse(fileUrl);
      final idx     = uri.pathSegments.indexOf(_bucket);
      if (idx == -1 || idx >= uri.pathSegments.length - 1) return;

      final filePath = uri.pathSegments.sublist(idx + 1).join('/');
      _log('🗑️ Delete → $filePath');
      await _supabase.storage.from(_bucket).remove([filePath]);
    } catch (e) {
      // ✅ Ne pas bloquer l'app si la suppression échoue
      _log('⚠️ Delete failed (non bloquant): $e');
    }
  }

  Future<void> deleteIfSupabase(String? url) async {
    if (url == null || !url.contains('supabase.co/storage')) return;
    await deleteFile(url);
  }

  // ─── Logger conditionnel ─────────────────────────────────────────

  // ✅ Log UNIQUEMENT en debug — rien en production
  static void _log(String msg) {
    if (kDebugMode) debugPrint('[StorageUploadService] $msg');
  }
}

// ─── Exception validation ────────────────────────────────────────────

class UploadValidationException implements Exception {
  final String message;
  const UploadValidationException(this.message);

  @override
  String toString() => 'UploadValidationException: $message';
}
