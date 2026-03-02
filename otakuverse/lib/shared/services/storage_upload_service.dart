import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageUploadService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'otakuverse';

  /// Upload une image vers Supabase Storage
  Future<String?> uploadImage(
    File file,
    String userId, {
    String folder = 'general',
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await file.readAsBytes();

      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

      return _supabase.storage.from(_bucket).getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  /// Upload plusieurs images
  Future<List<String>> uploadImages(List<File> files, String userId) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadImage(file, userId, folder: 'posts');
      if (url != null) urls.add(url);
    }
    return urls;
  }
}