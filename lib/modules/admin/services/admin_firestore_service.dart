import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarttrip_ai/modules/admin/models/admin_user_profile.dart';

class AdminFirestoreService {
  AdminFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Stream<List<AdminUserProfile>> watchUsers() {
    return _usersCollection.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<AdminUserProfile> users = snapshot.docs
          .map(AdminUserProfile.fromDocument)
          .toList();

      users.sort((AdminUserProfile first, AdminUserProfile second) {
        final DateTime firstDate =
            first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime secondDate =
            second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return secondDate.compareTo(firstDate);
      });

      return users;
    });
  }

  Future<void> deleteUser(String userId) {
    return _usersCollection.doc(userId).delete();
  }
}
