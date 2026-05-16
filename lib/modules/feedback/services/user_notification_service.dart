import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarttrip_ai/modules/feedback/models/feedback_entry.dart';
import 'package:smarttrip_ai/modules/feedback/models/user_notification.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';

abstract class UserNotificationServiceBase {
  Stream<List<UserNotificationEntry>> watchNotifications(String userId);
  Stream<int> watchUnreadCount(String userId);

  Future<void> markNotificationsRead({
    required String userId,
    required Iterable<UserNotificationEntry> notifications,
  });
}

class FirestoreUserNotificationService implements UserNotificationServiceBase {
  FirestoreUserNotificationService({
    required FeedbackServiceBase feedbackService,
    FirebaseFirestore? firestore,
  }) : _feedbackService = feedbackService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FeedbackServiceBase _feedbackService;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  CollectionReference<Map<String, dynamic>> _announcementReads(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('announcement_reads');
  }

  @override
  Stream<List<UserNotificationEntry>> watchNotifications(String userId) {
    late final StreamController<List<UserNotificationEntry>> controller;
    StreamSubscription<List<FeedbackEntry>>? replySubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    announcementSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? readSubscription;

    List<FeedbackEntry> replies = <FeedbackEntry>[];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> announcementDocs =
        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    Set<String> readAnnouncementIds = <String>{};

    void emitNotifications() {
      if (controller.isClosed) {
        return;
      }

      final List<UserNotificationEntry> notifications = <UserNotificationEntry>[
        ...replies.map(_fromFeedbackReply),
        ...announcementDocs.map((
          QueryDocumentSnapshot<Map<String, dynamic>> document,
        ) {
          return _fromAnnouncement(
            document,
            isRead: readAnnouncementIds.contains(document.id),
          );
        }),
      ];

      notifications.sort(_compareNotifications);
      controller.add(notifications);
    }

    controller = StreamController<List<UserNotificationEntry>>(
      onListen: () {
        replySubscription = _feedbackService
            .watchRepliedFeedbackForUser(userId)
            .listen((List<FeedbackEntry> items) {
              replies = items;
              emitNotifications();
            }, onError: controller.addError);

        announcementSubscription = _announcements.snapshots().listen((
          QuerySnapshot<Map<String, dynamic>> snapshot,
        ) {
          announcementDocs = snapshot.docs
              .where((QueryDocumentSnapshot<Map<String, dynamic>> document) {
                return document.data()['is_active'] != false;
              })
              .toList(growable: false);
          emitNotifications();
        }, onError: controller.addError);

        readSubscription = _announcementReads(userId).snapshots().listen((
          QuerySnapshot<Map<String, dynamic>> snapshot,
        ) {
          readAnnouncementIds = snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> document,
          ) {
            return document.id;
          }).toSet();
          emitNotifications();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await replySubscription?.cancel();
        await announcementSubscription?.cancel();
        await readSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return watchNotifications(userId).map((List<UserNotificationEntry> items) {
      return items
          .where((UserNotificationEntry notification) => !notification.isRead)
          .length;
    });
  }

  @override
  Future<void> markNotificationsRead({
    required String userId,
    required Iterable<UserNotificationEntry> notifications,
  }) async {
    final List<Future<void>> writes = <Future<void>>[];
    final WriteBatch batch = _firestore.batch();
    bool hasAnnouncementWrites = false;

    for (final UserNotificationEntry notification in notifications) {
      if (notification.isRead) {
        continue;
      }

      final String? feedbackId = notification.feedbackId;
      if (notification.isFeedbackReply &&
          feedbackId != null &&
          feedbackId.isNotEmpty) {
        writes.add(_feedbackService.markFeedbackRead(feedbackId));
      }

      final String? announcementId = notification.announcementId;
      if (notification.isAnnouncement &&
          announcementId != null &&
          announcementId.isNotEmpty) {
        batch.set(
          _announcementReads(userId).doc(announcementId),
          <String, Object?>{
            'announcement_id': announcementId,
            'read_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        hasAnnouncementWrites = true;
      }
    }

    if (hasAnnouncementWrites) {
      writes.add(batch.commit());
    }

    await Future.wait(writes);
  }

  UserNotificationEntry _fromFeedbackReply(FeedbackEntry feedback) {
    return UserNotificationEntry(
      id: 'feedback:${feedback.id}',
      type: UserNotificationType.feedbackReply,
      title: 'Admin replied',
      message: feedback.adminReply.isEmpty
          ? 'You received a new feedback reply.'
          : feedback.adminReply,
      secondaryMessage: feedback.message.isEmpty
          ? null
          : 'Your feedback: ${feedback.message}',
      createdAt: feedback.replyTime ?? feedback.createdAt,
      isRead: feedback.isRead,
      feedbackId: feedback.id,
      rating: feedback.rating,
    );
  }

  UserNotificationEntry _fromAnnouncement(
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    required bool isRead,
  }) {
    final Map<String, dynamic> data = document.data();
    final String title = _readString(data['title'], fallback: 'Announcement');
    final String message = _readString(data['message']);

    return UserNotificationEntry(
      id: 'announcement:${document.id}',
      type: UserNotificationType.announcement,
      title: title.isEmpty ? 'Announcement' : title,
      message: message.isEmpty ? title : message,
      secondaryMessage: 'Broadcast from admin',
      createdAt: _readDate(data['created_at'] ?? data['createdAt']),
      isRead: isRead,
      announcementId: document.id,
    );
  }
}

class FeedbackOnlyUserNotificationService
    implements UserNotificationServiceBase {
  FeedbackOnlyUserNotificationService({required FeedbackServiceBase service})
    : _feedbackService = service;

  final FeedbackServiceBase _feedbackService;

  @override
  Stream<List<UserNotificationEntry>> watchNotifications(String userId) {
    return _feedbackService.watchRepliedFeedbackForUser(userId).map((
      List<FeedbackEntry> replies,
    ) {
      final List<UserNotificationEntry> notifications = replies.map((
        FeedbackEntry feedback,
      ) {
        return UserNotificationEntry(
          id: 'feedback:${feedback.id}',
          type: UserNotificationType.feedbackReply,
          title: 'Admin replied',
          message: feedback.adminReply.isEmpty
              ? 'You received a new feedback reply.'
              : feedback.adminReply,
          secondaryMessage: feedback.message.isEmpty
              ? null
              : 'Your feedback: ${feedback.message}',
          createdAt: feedback.replyTime ?? feedback.createdAt,
          isRead: feedback.isRead,
          feedbackId: feedback.id,
          rating: feedback.rating,
        );
      }).toList();

      notifications.sort(_compareNotifications);
      return notifications;
    });
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return watchNotifications(userId).map((List<UserNotificationEntry> items) {
      return items
          .where((UserNotificationEntry notification) => !notification.isRead)
          .length;
    });
  }

  @override
  Future<void> markNotificationsRead({
    required String userId,
    required Iterable<UserNotificationEntry> notifications,
  }) async {
    await Future.wait(
      notifications
          .where((UserNotificationEntry notification) {
            return notification.isFeedbackReply &&
                !notification.isRead &&
                notification.feedbackId != null &&
                notification.feedbackId!.isNotEmpty;
          })
          .map((UserNotificationEntry notification) {
            return _feedbackService.markFeedbackRead(notification.feedbackId!);
          }),
    );
  }
}

class NoOpUserNotificationService implements UserNotificationServiceBase {
  const NoOpUserNotificationService();

  @override
  Future<void> markNotificationsRead({
    required String userId,
    required Iterable<UserNotificationEntry> notifications,
  }) async {}

  @override
  Stream<List<UserNotificationEntry>> watchNotifications(String userId) {
    return Stream<List<UserNotificationEntry>>.value(<UserNotificationEntry>[]);
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return Stream<int>.value(0);
  }
}

int _compareNotifications(
  UserNotificationEntry first,
  UserNotificationEntry second,
) {
  final DateTime firstDate =
      first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final DateTime secondDate =
      second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return secondDate.compareTo(firstDate);
}

String _readString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
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
