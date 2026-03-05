import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smarttrip_ai/modules/ai_generation/api/pexel_api_config.dart';

class ImageService {
  ImageService({http.Client? client}) : _client = client ?? http.Client();

  static const String _host = 'api.pexels.com';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final Map<String, String?> _cache = <String, String?>{};

  void dispose() {
    _client.close();
  }

  Future<String?> fetchPlaceImageUrl({
    required String placeName,
    required String destination,
  }) async {
    final String key = '${placeName.trim().toLowerCase()}|'
        '${destination.trim().toLowerCase()}';
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    if (PexelsApiConfig.apiKey.trim().isEmpty) {
      _cache[key] = null;
      return null;
    }

    final String query = _buildQuery(placeName, destination);
    final Uri url = Uri.https(_host, '/v1/search', <String, String>{
      'query': query,
      'per_page': '1',
      'orientation': 'landscape',
      'size': 'medium',
    });

    try {
      final http.Response response = await _client
          .get(
            url,
            headers: <String, String>{
              'Authorization': PexelsApiConfig.apiKey,
            },
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _cache[key] = null;
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _cache[key] = null;
        return null;
      }

      final dynamic photos = decoded['photos'];
      if (photos is! List || photos.isEmpty) {
        _cache[key] = null;
        return null;
      }

      final dynamic firstPhoto = photos.first;
      if (firstPhoto is! Map<String, dynamic>) {
        _cache[key] = null;
        return null;
      }

      final dynamic src = firstPhoto['src'];
      if (src is! Map<String, dynamic>) {
        _cache[key] = null;
        return null;
      }

      final String? imageUrl =
          _asString(src['medium']) ??
          _asString(src['landscape']) ??
          _asString(src['large']) ??
          _asString(src['original']);

      _cache[key] = imageUrl;
      return imageUrl;
    } on TimeoutException {
      _cache[key] = null;
      return null;
    } on SocketException {
      _cache[key] = null;
      return null;
    } on HandshakeException {
      _cache[key] = null;
      return null;
    } on http.ClientException {
      _cache[key] = null;
      return null;
    } on FormatException {
      _cache[key] = null;
      return null;
    }
  }

  String _buildQuery(String placeName, String destination) {
    final String place = placeName.trim();
    final String city = destination.trim();
    if (place.isEmpty && city.isEmpty) {
      return 'travel destination';
    }
    if (city.isEmpty) {
      return '$place travel';
    }
    if (place.isEmpty) {
      return '$city travel';
    }
    return '$place $city travel';
  }

  String? _asString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
