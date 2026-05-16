import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

abstract class GeneratedPlacesServiceBase {
  Future<void> recordPlaceGeneration({
    required String placeName,
    required String userId,
    String? userEmail,
  });

  Future<void> recordPlaceSave({
    required String placeName,
    required String userId,
    String? userEmail,
  });
}

class GeneratedPlacesService implements GeneratedPlacesServiceBase {
  final FirebaseFirestore _firestore;

  GeneratedPlacesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> recordPlaceGeneration({
    required String placeName,
    required String userId,
    String? userEmail,
  }) async {
    await _recordPlaceStats(
      placeName: placeName,
      userId: userId,
      userEmail: userEmail,
      incrementGeneration: true,
      incrementSave: false,
    );
  }

  @override
  Future<void> recordPlaceSave({
    required String placeName,
    required String userId,
    String? userEmail,
  }) async {
    await _recordPlaceStats(
      placeName: placeName,
      userId: userId,
      userEmail: userEmail,
      incrementGeneration: false,
      incrementSave: true,
    );
  }

  Future<void> _recordPlaceStats({
    required String placeName,
    required String userId,
    required String? userEmail,
    required bool incrementGeneration,
    required bool incrementSave,
  }) async {
    final String normalizedPlaceName = placeName.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final String normalizedUserId = userId.trim();
    if (normalizedPlaceName.isEmpty || normalizedUserId.isEmpty) {
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> docRef = _firestore
          .collection('generated_places')
          .doc(_slugify(normalizedPlaceName));

      final Map<String, Object?> data = <String, Object?>{
        'placeName': normalizedPlaceName,
        'lastUserId': normalizedUserId,
        'lastUserEmail': userEmail?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (incrementGeneration) {
        data['lastGeneratedAt'] = FieldValue.serverTimestamp();
        data['generationCount'] = FieldValue.increment(1);
      }

      if (incrementSave) {
        data['lastSavedAt'] = FieldValue.serverTimestamp();
        data['savedCount'] = FieldValue.increment(1);
      }

      await docRef.set(data, SetOptions(merge: true));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Unable to record generated place stats for '
          '"$normalizedPlaceName" (user: $normalizedUserId): $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  String _slugify(String input) {
    final String trimmed = input.trim().toLowerCase();
    final String replaced = trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final String slug = replaced
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? 'generated_place' : slug;
  }
}
