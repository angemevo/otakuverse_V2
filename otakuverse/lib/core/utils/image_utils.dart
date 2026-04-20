import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Utilitaires images — compression et sélection uniquement
/// Note: redimensionnement/filtres supprimés (package 'image' retiré du projet)
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  // ─── SÉLECTION ───────────────────────────────────────────────────

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (_) { return null; }
  }

  static Future<List<File>> pickMultipleImages({int maxImages = 10}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      return images.take(maxImages).map((x) => File(x.path)).toList();
    } catch (_) { return []; }
  }

  static Future<File?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (_) { return null; }
  }

  // ─── COMPRESSION ─────────────────────────────────────────────────

  static Future<File?> compressImage(File file, {int quality = 85, int maxWidth = 1920, int maxHeight = 1920}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, targetPath,
        quality: quality, minWidth: maxWidth, minHeight: maxHeight,
      );
      return result != null ? File(result.path) : null;
    } catch (_) { return null; }
  }

  static Future<File?> compressAvatar(File file) =>
      compressImage(file, quality: 90, maxWidth: 400, maxHeight: 400);

  static Future<File?> compressPost(File file) =>
      compressImage(file, quality: 85, maxWidth: 1920, maxHeight: 1920);

  // ─── VALIDATION ──────────────────────────────────────────────────

  static bool isValidImage(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  static Future<bool> isValidSize(File file, {int maxSizeBytes = AppConstants.maxImageSize}) async {
    try { return await file.length() <= maxSizeBytes; }
    catch (_) { return false; }
  }

  // ─── CONVERSION ──────────────────────────────────────────────────

  static Future<Uint8List?> fileToBytes(File file) async {
    try { return await file.readAsBytes(); }
    catch (_) { return null; }
  }

  static Future<File?> bytesToFile(Uint8List bytes, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file;
    } catch (_) { return null; }
  }

  // ─── NETTOYAGE ───────────────────────────────────────────────────

  static Future<void> deleteFile(File file) async {
    try { if (await file.exists()) await file.delete(); }
    catch (_) {}
  }

  static Future<void> clearTempDirectory() async {
    try {
      final dir = await getTemporaryDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    } catch (_) {}
  }
}
