import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/feedback/models/user_notification.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';
import 'package:smarttrip_ai/modules/feedback/services/user_notification_service.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.authService,
    this.feedbackService,
    this.notificationService,
  });

  final AuthServiceBase authService;
  final FeedbackServiceBase? feedbackService;
  final UserNotificationServiceBase? notificationService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final UserNotificationServiceBase _notificationService;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    final FeedbackServiceBase? feedbackService = widget.feedbackService;
    final bool hasFirebase = Firebase.apps.isNotEmpty;
    _notificationService =
        widget.notificationService ??
        (hasFirebase
            ? FirestoreUserNotificationService(
                feedbackService: feedbackService ?? FeedbackService(),
              )
            : feedbackService == null
            ? const NoOpUserNotificationService()
            : FeedbackOnlyUserNotificationService(service: feedbackService));
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) {
      return;
    }

    setState(() => _refreshVersion += 1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  void _markUnreadNotificationsRead(
    String userId,
    List<UserNotificationEntry> notifications,
  ) {
    final List<UserNotificationEntry> unreadNotifications = notifications
        .where((UserNotificationEntry notification) => !notification.isRead)
        .toList(growable: false);
    if (unreadNotifications.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _notificationService
            .markNotificationsRead(
              userId: userId,
              notifications: unreadNotifications,
            )
            .catchError((Object error) {
              debugPrint('Unable to mark notifications read: $error');
            }),
      );
    });
  }

  Stream<List<UserNotificationEntry>> _watchNotifications(String userId) {
    return _notificationService.watchNotifications(userId);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pageColor = isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : const Color(0x338DA180);
    final String? userId = widget.authService.currentUserId;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: userId == null || userId.isEmpty
            ? _NotificationStateCard(
                icon: Icons.login_rounded,
                title: 'Login required',
                message: 'Login to view notifications.',
                primaryTextColor: primaryTextColor,
                backgroundColor: cardColor,
                borderColor: borderColor,
              )
            : StreamBuilder<List<UserNotificationEntry>>(
                key: ValueKey<int>(_refreshVersion),
                stream: _watchNotifications(userId),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<UserNotificationEntry>> snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return RefreshIndicator(
                          onRefresh: _refreshNotifications,
                          color: primaryTextColor,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            children: <Widget>[
                              _NotificationStateCard(
                                icon: Icons.cloud_off_outlined,
                                title: 'Unable to load notifications',
                                message:
                                    'Check Firestore access and try again.',
                                primaryTextColor: primaryTextColor,
                                backgroundColor: cardColor,
                                borderColor: borderColor,
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryTextColor,
                          ),
                        );
                      }

                      final List<UserNotificationEntry> notifications =
                          snapshot.data ?? <UserNotificationEntry>[];
                      _markUnreadNotificationsRead(userId, notifications);

                      if (notifications.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshNotifications,
                          color: primaryTextColor,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            children: <Widget>[
                              _NotificationStateCard(
                                icon: Icons.notifications_none_rounded,
                                title: 'No notifications',
                                message:
                                    'Admin replies and broadcasts appear here.',
                                primaryTextColor: primaryTextColor,
                                backgroundColor: cardColor,
                                borderColor: borderColor,
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshNotifications,
                        color: primaryTextColor,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          itemCount: notifications.length,
                          itemBuilder: (BuildContext context, int index) {
                            final UserNotificationEntry notification =
                                notifications[index];
                            return Padding(
                              key: ValueKey<String>(notification.id),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NotificationCard(
                                notification: notification,
                                primaryTextColor: primaryTextColor,
                                backgroundColor: cardColor,
                                borderColor: borderColor,
                              ),
                            );
                          },
                        ),
                      );
                    },
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final UserNotificationEntry notification;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final IconData icon = notification.isAnnouncement
        ? Icons.campaign_outlined
        : notification.isRead
        ? Icons.mark_email_read_outlined
        : Icons.mark_email_unread_outlined;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead ? borderColor : primaryTextColor,
            width: notification.isRead ? 1 : 1.3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: primaryTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontFamily: 'Times New Roman',
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(notification.createdAt),
                style: TextStyle(
                  color: primaryTextColor.withValues(alpha: 0.56),
                  fontFamily: 'Times New Roman',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: TextStyle(
                  color: primaryTextColor.withValues(alpha: 0.88),
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.24,
                ),
              ),
              if (notification.secondaryMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  notification.secondaryMessage!,
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.7),
                    fontFamily: 'Times New Roman',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
              if (notification.rating != null) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Icon(Icons.star_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      notification.rating.toString(),
                      style: TextStyle(
                        color: primaryTextColor.withValues(alpha: 0.72),
                        fontFamily: 'Times New Roman',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationStateCard extends StatelessWidget {
  const _NotificationStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: primaryTextColor, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontFamily: 'Times New Roman',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.68),
                    fontFamily: 'Times New Roman',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? date) {
  if (date == null) {
    return 'Time not available';
  }

  final DateTime localDate = date.toLocal();
  final String month = localDate.month.toString().padLeft(2, '0');
  final String day = localDate.day.toString().padLeft(2, '0');
  final String hour = localDate.hour.toString().padLeft(2, '0');
  final String minute = localDate.minute.toString().padLeft(2, '0');
  return '${localDate.year}-$month-$day $hour:$minute';
}
