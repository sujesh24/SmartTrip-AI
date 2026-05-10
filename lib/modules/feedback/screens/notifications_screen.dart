import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/feedback/models/feedback_entry.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.authService,
    this.feedbackService,
  });

  final AuthServiceBase authService;
  final FeedbackServiceBase? feedbackService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final FeedbackServiceBase _feedbackService;
  final Set<String> _markingReadIds = <String>{};

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
  }

  Future<void> _markRead(FeedbackEntry feedback) async {
    if (feedback.isRead || _markingReadIds.contains(feedback.id)) {
      return;
    }

    setState(() => _markingReadIds.add(feedback.id));
    try {
      await _feedbackService.markFeedbackRead(feedback.id);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to mark notification read.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to mark notification read.');
    } finally {
      if (mounted) {
        setState(() => _markingReadIds.remove(feedback.id));
      }
    }
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
                message: 'Login to view reply notifications.',
                primaryTextColor: primaryTextColor,
                backgroundColor: cardColor,
                borderColor: borderColor,
              )
            : StreamBuilder<List<FeedbackEntry>>(
                stream: _feedbackService.watchRepliedFeedbackForUser(userId),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<FeedbackEntry>> snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return _NotificationStateCard(
                          icon: Icons.cloud_off_outlined,
                          title: 'Unable to load notifications',
                          message: 'Check Firestore access and try again.',
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
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

                      final List<FeedbackEntry> notifications =
                          snapshot.data ?? <FeedbackEntry>[];
                      if (notifications.isEmpty) {
                        return _NotificationStateCard(
                          icon: Icons.notifications_none_rounded,
                          title: 'No notifications',
                          message:
                              'Admin replies to your feedback appear here.',
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        itemCount: notifications.length,
                        itemBuilder: (BuildContext context, int index) {
                          final FeedbackEntry notification =
                              notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NotificationCard(
                              notification: notification,
                              isMarkingRead: _markingReadIds.contains(
                                notification.id,
                              ),
                              primaryTextColor: primaryTextColor,
                              backgroundColor: cardColor,
                              borderColor: borderColor,
                              onTap: () => _markRead(notification),
                              onMarkRead: () => _markRead(notification),
                            ),
                          );
                        },
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
    required this.isMarkingRead,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    required this.onMarkRead,
  });

  final FeedbackEntry notification;
  final bool isMarkingRead;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
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
                    Icon(
                      notification.isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                      color: primaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin replied',
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
                  _formatDateTime(notification.replyTime),
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.56),
                    fontFamily: 'Times New Roman',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  notification.adminReply,
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.88),
                    fontFamily: 'Times New Roman',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your feedback: ${notification.message}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.66),
                    fontFamily: 'Times New Roman',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      notification.rating.toString(),
                      style: TextStyle(
                        color: primaryTextColor.withValues(alpha: 0.7),
                        fontFamily: 'Times New Roman',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead)
                      TextButton(
                        onPressed: isMarkingRead ? null : onMarkRead,
                        child: isMarkingRead
                            ? SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryTextColor,
                                ),
                              )
                            : Text(
                                'Mark read',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontFamily: 'Times New Roman',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
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
