import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Mengambil foto dari galeri atau kamera, mengompres ke resolusi optimal (maks 600x600 @ 80% quality),
  /// lalu mengubahnya menjadi format Base64 Data URI ('data:image/jpeg;base64,...').
  /// Format ini 100% offline-ready, tidak kedaluwarsa di Web (IndexedDB), dan otomatis
  /// terangkut saat backup/restore database SQLite.
  static Future<String?> pickImageAsBase64({
    ImageSource source = ImageSource.gallery,
    double maxWidth = 600,
    double maxHeight = 600,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (file == null) return null;

      final Uint8List bytes = await file.readAsBytes();
      final String base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  /// Mengubah Base64 Data URI atau raw Base64 string menjadi bytes (Uint8List).
  static Uint8List? bytesFromBase64(String? dataUriOrBase64) {
    if (dataUriOrBase64 == null || dataUriOrBase64.trim().isEmpty) return null;

    try {
      String cleanStr = dataUriOrBase64.trim();
      if (cleanStr.contains('base64,')) {
        cleanStr = cleanStr.split('base64,').last;
      }
      return base64Decode(cleanStr);
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }

  /// Memeriksa apakah string merupakan Base64 image
  static bool isBase64Image(String? str) {
    if (str == null) return false;
    return str.startsWith('data:image/') || str.startsWith('data:;base64,') || (!str.startsWith('http') && !str.startsWith('/') && !str.contains(':\\') && str.length > 100);
  }
}
