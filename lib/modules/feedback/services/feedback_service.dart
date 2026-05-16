import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarttrip_ai/modules/feedback/models/feedback_entry.dart';

abstract class FeedbackServiceBase {
  Stream<List<FeedbackEntry>> watchAllFeedback();
  Stream<List<FeedbackEntry>> watchRepliedFeedbackForUser(String userId);
  Stream<int> watchUnreadReplyCount(String userId);

  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String message,
    required int rating,
  });

  Future<void> replyToFeedback({
    required String feedbackId,
    required String reply,
  });

  Future<void> markFeedbackRead(String feedbackId);

  Future<void> deleteFeedback(String feedbackId);
}

class FeedbackService implements FeedbackServiceBase {
  FeedbackService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('feedback');

  @override
  Stream<List<FeedbackEntry>> watchAllFeedback() {
    return _collection.snapshots().map(_sortFeedbackSnapshot);
  }

  @override
  Stream<List<FeedbackEntry>> watchRepliedFeedbackForUser(String userId) {
    return _collection
        .where('user_id', isEqualTo: userId)
        .where('is_replied', isEqualTo: true)
        .snapshots()
        .map(_sortFeedbackSnapshot);
  }

  @override
  Stream<int> watchUnreadReplyCount(String userId) {
    return watchRepliedFeedbackForUser(userId).map((List<FeedbackEntry> items) {
      return items.where((FeedbackEntry item) => !item.isRead).length;
    });
  }

  @override
  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String message,
    required int rating,
  }) {
    final DocumentReference<Map<String, dynamic>> document = _collection.doc();
    return document.set(<String, Object?>{
      'feedback_id': document.id,
      'user_id': userId,
      'user_name': userName.trim(),
      'message': message.trim(),
      'rating': rating,
      'created_at': FieldValue.serverTimestamp(),
      'admin_reply': '',
      'reply_time': null,
      'is_replied': false,
      'is_read': false,
    });
  }

  @override
  Future<void> replyToFeedback({
    required String feedbackId,
    required String reply,
  }) {
    return _collection.doc(feedbackId).set(<String, Object?>{
      'admin_reply': reply.trim(),
      'reply_time': FieldValue.serverTimestamp(),
      'is_replied': true,
      'is_read': false,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markFeedbackRead(String feedbackId) {
    return _collection.doc(feedbackId).set(<String, Object?>{
      'is_read': true,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteFeedback(String feedbackId) {
    return _collection.doc(feedbackId).delete();
  }

  List<FeedbackEntry> _sortFeedbackSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<FeedbackEntry> items = snapshot.docs
        .map(FeedbackEntry.fromDocument)
        .toList();

    items.sort((FeedbackEntry first, FeedbackEntry second) {
      final DateTime firstDate =
          first.replyTime ??
          first.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime secondDate =
          second.replyTime ??
          second.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return secondDate.compareTo(firstDate);
    });

    return items;
  }
}
