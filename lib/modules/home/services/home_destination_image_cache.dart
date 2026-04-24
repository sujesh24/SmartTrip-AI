import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class HomeDestinationImageCache {
  Future<Map<String, String>> loadCachedImageUrls();
  Future<void> saveImageUrl({
    required String destinationId,
    required String imageUrl,
  });
  Future<void> clear();
}

class SharedPrefsHomeDestinationImageCache
    implements HomeDestinationImageCache {
  static const String _cacheKey = 'home.destination_images.v1';

  Future<Map<String, String>> _readCache(SharedPreferences preferences) async {
    final String? rawJson = preferences.getString(_cacheKey);
    if (rawJson == null || rawJson.isEmpty) {
      return <String, String>{};
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return <String, String>{};
      }

      return decoded.map((Object? key, Object? value) {
        final String normalizedKey = key?.toString() ?? '';
        final String normalizedValue = value?.toString() ?? '';
        return MapEntry<String, String>(normalizedKey, normalizedValue);
      })..removeWhere(
        (String key, String value) => key.isEmpty || value.isEmpty,
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  @override
  Future<Map<String, String>> loadCachedImageUrls() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return _readCache(preferences);
  }

  @override
  Future<void> saveImageUrl({
    required String destinationId,
    required String imageUrl,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Map<String, String> currentCache = await _readCache(preferences);
    currentCache[destinationId] = imageUrl;
    await preferences.setString(_cacheKey, jsonEncode(currentCache));
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cacheKey);
  }
}
