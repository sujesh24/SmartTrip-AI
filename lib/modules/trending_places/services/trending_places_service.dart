import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarttrip_ai/modules/trending_places/data/default_trending_places.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';

abstract class TrendingPlacesServiceBase {
  Stream<List<TrendingPlace>> watchTrendingPlaces();
  Future<void> addTrendingPlace(TrendingPlace place);
  Future<void> updateTrendingPlace(TrendingPlace place);
  Future<void> deleteTrendingPlace(String placeId);
  Future<int> seedDefaultTrendingPlaces();
}

class TrendingPlacesService implements TrendingPlacesServiceBase {
  TrendingPlacesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('trending_places');

  @override
  Stream<List<TrendingPlace>> watchTrendingPlaces() {
    return _collection.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<TrendingPlace> places = snapshot.docs
          .map(TrendingPlace.fromDocument)
          .toList();

      places.sort((TrendingPlace first, TrendingPlace second) {
        final DateTime firstDate =
            first.updatedAt ??
            first.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime secondDate =
            second.updatedAt ??
            second.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return secondDate.compareTo(firstDate);
      });

      return places;
    });
  }

  @override
  Future<void> addTrendingPlace(TrendingPlace place) {
    return _collection.add(place.toFirestore(includeCreatedAt: true));
  }

  @override
  Future<void> updateTrendingPlace(TrendingPlace place) {
    return _collection
        .doc(place.id)
        .set(place.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteTrendingPlace(String placeId) {
    return _collection.doc(placeId).delete();
  }

  @override
  Future<int> seedDefaultTrendingPlaces() async {
    int createdCount = 0;

    for (final TrendingPlace place in kDefaultTrendingPlaces) {
      final DocumentReference<Map<String, dynamic>> document = _collection.doc(
        place.id,
      );
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await document
          .get();

      if (snapshot.exists) {
        continue;
      }

      await document.set(place.toFirestore(includeCreatedAt: true));
      createdCount += 1;
    }

    return createdCount;
  }
}
