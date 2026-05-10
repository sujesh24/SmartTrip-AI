import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserProfile {
  const AdminUserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Unknown User';
  }

  factory AdminUserProfile.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final String email = _readString(data['email']);

    return AdminUserProfile(
      id: document.id,
      name: _readString(
        data['name'] ??
            data['fullName'] ??
            data['username'] ??
            data['displayName'],
      ),
      email: email.isNotEmpty ? email : 'No email',
      createdAt: _readDate(
        data['createdAt'] ?? data['created_at'] ?? data['createdDate'],
      ),
    );
  }
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
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
