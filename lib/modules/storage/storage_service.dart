import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a place image and returns a public download URL.
  /// Uses a sanitized filename and derives a safe content-type.
  Future<String> uploadPlaceImage({
    required XFile file,
    String? placeId,
  }) async {
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw ArgumentError('Selected file is empty');
    }

    final String extension = _getFileExtension(file.path);
    final String filename = placeId != null
        ? _getSafeFilename(placeId, extension)
        : 'temp-${DateTime.now().millisecondsSinceEpoch}$extension';
    final String contentType = _getContentType(extension, file.mimeType);

    final Reference ref = _storage.ref().child('places/$filename');
    final SettableMetadata metadata = SettableMetadata(
      contentType: contentType,
    );

    final UploadTask uploadTask = ref.putData(bytes, metadata);
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  String _getFileExtension(String filePath) {
    try {
      final int dot = filePath.lastIndexOf('.');
      if (dot == -1 || dot >= filePath.length - 1) {
        return '.jpg';
      }
      return filePath.substring(dot).toLowerCase();
    } catch (_) {
      return '.jpg';
    }
  }

  String _getSafeFilename(String name, String extension) {
    var safe = name.trim();
    safe = safe.replaceAll(RegExp(r'\s+'), '_');
    safe = safe.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    if (safe.isEmpty) {
      safe = 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
    const int max = 200;
    if (safe.length > max) {
      safe = safe.substring(0, max);
    }
    return '$safe$extension';
  }

  String _getContentType(String extension, String? mime) {
    final String ext = extension.toLowerCase();
    const Map<String, String> map = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.svg': 'image/svg+xml',
      '.bmp': 'image/bmp',
      '.tiff': 'image/tiff',
      '.ico': 'image/x-icon',
    };
    return map[ext] ??
        (mime != null && mime.isNotEmpty ? mime : 'application/octet-stream');
  }
}
