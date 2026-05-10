import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HomeCachedImage {
  const HomeCachedImage({this.imageUrl, this.imageBytesBase64});

  final String? imageUrl;
  final String? imageBytesBase64;

  bool get hasLocalBytes {
    final String? bytes = imageBytesBase64?.trim();
    return bytes != null && bytes.isNotEmpty;
  }

  bool get hasImageUrl {
    final String? url = imageUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  bool get hasAnyImageData => hasLocalBytes || hasImageUrl;

  Map<String, String> toJson() {
    final Map<String, String> json = <String, String>{};
    final String? normalizedUrl = imageUrl?.trim();
    final String? normalizedBytes = imageBytesBase64?.trim();
    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      json['url'] = normalizedUrl;
    }
    if (normalizedBytes != null && normalizedBytes.isNotEmpty) {
      json['bytes'] = normalizedBytes;
    }
    return json;
  }
}

abstract class HomeDestinationImageCache {
  Future<Map<String, HomeCachedImage>> loadCachedImages();
  Future<void> saveImage({
    required String destinationId,
    String? imageUrl,
    String? imageBytesBase64,
  });
  Future<void> clear();
}

class SharedPrefsHomeDestinationImageCache
    implements HomeDestinationImageCache {
  static const String _cacheKey = 'home.destination_images.v1';

  Future<Map<String, HomeCachedImage>> _readCache(
    SharedPreferences preferences,
  ) async {
    final String? rawJson = preferences.getString(_cacheKey);
    if (rawJson == null || rawJson.isEmpty) {
      return <String, HomeCachedImage>{};
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return <String, HomeCachedImage>{};
      }

      final Map<String, HomeCachedImage> normalized =
          <String, HomeCachedImage>{};

      decoded.forEach((Object? key, dynamic value) {
        final String destinationId = key?.toString() ?? '';
        if (destinationId.isEmpty) {
          return;
        }

        if (value is String) {
          final String imageUrl = value.trim();
          if (imageUrl.isNotEmpty) {
            normalized[destinationId] = HomeCachedImage(imageUrl: imageUrl);
          }
          return;
        }

        if (value is Map<String, dynamic>) {
          final String? imageUrl = value['url']?.toString().trim();
          final String? imageBytes = value['bytes']?.toString().trim();
          final HomeCachedImage cached = HomeCachedImage(
            imageUrl: imageUrl,
            imageBytesBase64: imageBytes,
          );
          if (cached.hasAnyImageData) {
            normalized[destinationId] = cached;
          }
        }
      });

      return normalized;
    } catch (_) {
      return <String, HomeCachedImage>{};
    }
  }

  @override
  Future<Map<String, HomeCachedImage>> loadCachedImages() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return _readCache(preferences);
  }

  @override
  Future<void> saveImage({
    required String destinationId,
    String? imageUrl,
    String? imageBytesBase64,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Map<String, HomeCachedImage> currentCache = await _readCache(
      preferences,
    );
    final HomeCachedImage? existing = currentCache[destinationId];

    final HomeCachedImage next = HomeCachedImage(
      imageUrl: imageUrl?.trim().isNotEmpty == true
          ? imageUrl?.trim()
          : existing?.imageUrl,
      imageBytesBase64: imageBytesBase64?.trim().isNotEmpty == true
          ? imageBytesBase64?.trim()
          : existing?.imageBytesBase64,
    );

    if (!next.hasAnyImageData) {
      return;
    }

    currentCache[destinationId] = next;
    final Map<String, Map<String, String>> encoded = currentCache.map(
      (String key, HomeCachedImage value) =>
          MapEntry<String, Map<String, String>>(key, value.toJson()),
    );
    await preferences.setString(_cacheKey, jsonEncode(encoded));
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cacheKey);
  }
}
