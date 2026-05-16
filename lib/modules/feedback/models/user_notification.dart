enum UserNotificationType { feedbackReply, announcement }

class UserNotificationEntry {
  const UserNotificationEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.secondaryMessage,
    this.feedbackId,
    this.announcementId,
    this.rating,
  });

  final String id;
  final UserNotificationType type;
  final String title;
  final String message;
  final String? secondaryMessage;
  final DateTime? createdAt;
  final bool isRead;
  final String? feedbackId;
  final String? announcementId;
  final int? rating;

  bool get isFeedbackReply => type == UserNotificationType.feedbackReply;
  bool get isAnnouncement => type == UserNotificationType.announcement;
}
