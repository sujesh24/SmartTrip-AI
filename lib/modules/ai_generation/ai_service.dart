import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smarttrip_ai/modules/ai_generation/api/api_config.dart';

class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseHost = 'generativelanguage.googleapis.com';
  static const String _apiVersionPath = '/v1beta';
  static const String _defaultModel = 'gemini-2.5-flash';
  static const List<String> _fallbackModels = <String>[
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
  ];
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxSocketRetries = 2;

  final http.Client _client;

  void dispose() {
    _client.close();
  }

  Future<String> generateText(String prompt) async {
    final String trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }
    if (ApiConfig.apiKey.trim().isEmpty) {
      throw Exception('Gemini API key is missing in api_config.dart.');
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, String>>[
            <String, String>{'text': trimmedPrompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseMimeType': 'application/json',
      },
    };

    try {
      return await _generateWithModel(_defaultModel, body);
    } on _ModelNotFoundException {
      String? discoveredModel;
      try {
        discoveredModel = await _discoverSupportedModel();
      } catch (_) {
        // Keep fallback behavior below if model discovery fails.
      }

      final List<String> modelsToTry = <String>[];
      if (discoveredModel != null) {
        modelsToTry.add(discoveredModel);
      }
      for (final String model in _fallbackModels) {
        if (model != _defaultModel && !modelsToTry.contains(model)) {
          modelsToTry.add(model);
        }
      }

      for (final String model in modelsToTry) {
        try {
          return await _generateWithModel(model, body);
        } on _ModelNotFoundException {
          continue;
        }
      }

      throw Exception(
        'No supported Gemini model is available for generateContent on your API key.',
      );
    }
  }

  Future<String> _generateWithModel(
    String model,
    Map<String, dynamic> body,
  ) async {
    final Uri url = Uri.https(
      _baseHost,
      '$_apiVersionPath/models/${_normalizeModelName(model)}:generateContent',
      <String, String>{'key': ApiConfig.apiKey},
    );

    final http.Response response = await _postWithRetry(url, body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String errorMessage = _readError(response.body);
      if (response.statusCode == 404 &&
          errorMessage.toLowerCase().contains('not found')) {
        throw _ModelNotFoundException(model, errorMessage);
      }
      throw Exception(
        'AI request failed (${response.statusCode}): $errorMessage',
      );
    }

    final dynamic data = jsonDecode(response.body);
    final String? generated = _readGeneratedText(data);
    if (generated == null || generated.trim().isEmpty) {
      throw Exception('AI response text is empty.');
    }

    return generated.trim();
  }

  Future<String?> _discoverSupportedModel() async {
    final Uri url = Uri.https(
      _baseHost,
      '$_apiVersionPath/models',
      <String, String>{'key': ApiConfig.apiKey},
    );
    final http.Response response = await _getWithRetry(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final dynamic models = decoded['models'];
    if (models is! List) {
      return null;
    }

    final List<String> available = <String>[];
    for (final dynamic item in models) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final dynamic name = item['name'];
      final dynamic methods = item['supportedGenerationMethods'];
      if (name is! String || methods is! List) {
        continue;
      }

      final bool supportsGenerateContent = methods.any(
        (dynamic method) => method is String && method == 'generateContent',
      );
      if (supportsGenerateContent) {
        available.add(_normalizeModelName(name));
      }
    }

    if (available.isEmpty) {
      return null;
    }

    final List<String> preferredOrder = <String>[
      _defaultModel,
      ..._fallbackModels,
    ];
    for (final String preferred in preferredOrder) {
      if (available.contains(preferred)) {
        return preferred;
      }
    }

    return available.first;
  }

  String _normalizeModelName(String model) {
    if (model.startsWith('models/')) {
      return model.substring(7);
    }
    return model;
  }

  Future<http.Response> _postWithRetry(
    Uri url,
    Map<String, dynamic> body,
  ) async {
    for (int attempt = 1; attempt <= _maxSocketRetries; attempt++) {
      try {
        return await _client
            .post(
              url,
              headers: <String, String>{'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);
      } on TimeoutException {
        throw Exception('AI request timed out after 30 seconds.');
      } on SocketException catch (error) {
        final String message = error.message.trim();
        final String lower = message.toLowerCase();
        final bool isHostLookup = lower.contains('failed host lookup');

        if (isHostLookup && attempt < _maxSocketRetries) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }

        if (isHostLookup) {
          throw Exception(
            "Network DNS error: failed to resolve '$_baseHost'. Check device internet or emulator DNS, then restart the app.",
          );
        }

        throw Exception('Network error: $message');
      } on HandshakeException {
        throw Exception('Secure connection failed (TLS/SSL handshake).');
      } on http.ClientException catch (error) {
        throw Exception('Network client error: ${error.message}');
      }
    }

    throw Exception('Unable to connect to AI service.');
  }

  Future<http.Response> _getWithRetry(Uri url) async {
    for (int attempt = 1; attempt <= _maxSocketRetries; attempt++) {
      try {
        return await _client.get(url).timeout(_timeout);
      } on TimeoutException {
        throw Exception('AI request timed out after 30 seconds.');
      } on SocketException catch (error) {
        final String message = error.message.trim();
        final String lower = message.toLowerCase();
        final bool isHostLookup = lower.contains('failed host lookup');

        if (isHostLookup && attempt < _maxSocketRetries) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }

        if (isHostLookup) {
          throw Exception(
            "Network DNS error: failed to resolve '$_baseHost'. Check device internet or emulator DNS, then restart the app.",
          );
        }

        throw Exception('Network error: $message');
      } on HandshakeException {
        throw Exception('Secure connection failed (TLS/SSL handshake).');
      } on http.ClientException catch (error) {
        throw Exception('Network client error: ${error.message}');
      }
    }

    throw Exception('Unable to connect to AI service.');
  }

  String? _readGeneratedText(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final dynamic candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final dynamic firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      return null;
    }

    final dynamic content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }

    final dynamic parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return null;
    }

    final dynamic firstPart = parts.first;
    if (firstPart is! Map<String, dynamic>) {
      return null;
    }

    final dynamic text = firstPart['text'];
    return text is String ? text : null;
  }

  String _readError(String responseBody) {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final dynamic message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {
      // Keep fallback below when response isn't valid JSON.
    }
    return 'Unknown error';
  }
}

class _ModelNotFoundException implements Exception {
  const _ModelNotFoundException(this.model, this.message);

  final String model;
  final String message;

  @override
  String toString() => 'Model not found: $model ($message)';
}
