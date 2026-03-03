import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageUploadService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'otakuverse';

  // ✅ Accepte des bytes — fonctionne sur web ET mobile
  Future<String?> uploadImageBytes(
    Uint8List bytes,
    String userId, {
    String folder = 'general',
    String ext = 'jpg',
  }) async {
    final fileName =
        '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';

    // ✅ Correction du MIME type
    final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';

    print('📤 Upload vers : $_bucket/$fileName');

    await _supabase.storage.from(_bucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(
        contentType: mimeType, // ✅ image/jpeg au lieu de image/jpg
        upsert: true,
      ),
    );

    final url = _supabase.storage.from(_bucket).getPublicUrl(fileName);
    print('✅ URL générée : $url');
    return url;
  }

  // ✅ Upload multiple
  Future<List<String>> uploadMultipleBytes(
    List<Uint8List> bytesList,
    String userId,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < bytesList.length; i++) {
      final url = await uploadImageBytes(
        bytesList[i],
        userId,
        folder: 'posts',
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<List<String>> uploadImages(
    List<XFile> files,
    String userId,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final ext   = file.name.split('.').last.toLowerCase();
      final url   = await uploadImageBytes(
        bytes,
        userId,
        folder: 'posts',
        ext: ext,
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }
}