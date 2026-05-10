import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.rating,
    required this.createdAt,
    required this.adminReply,
    required this.replyTime,
    required this.isReplied,
    required this.isRead,
  });

  final String id;
  final String userId;
  final String userName;
  final String message;
  final int rating;
  final DateTime? createdAt;
  final String adminReply;
  final DateTime? replyTime;
  final bool isReplied;
  final bool isRead;

  factory FeedbackEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    return FeedbackEntry(
      id: _readString(data['feedback_id']).isEmpty
          ? document.id
          : _readString(data['feedback_id']),
      userId: _readString(data['user_id']),
      userName: _readString(data['user_name']),
      message: _readString(data['message']),
      rating: _readInt(data['rating'], fallback: 0),
      createdAt: _readDate(data['created_at']),
      adminReply: _readString(data['admin_reply']),
      replyTime: _readDate(data['reply_time']),
      isReplied: data['is_replied'] == true,
      isRead: data['is_read'] == true,
    );
  }
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
