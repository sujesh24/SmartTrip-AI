import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/feedback/models/feedback_entry.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ManageFeedbackScreen extends StatefulWidget {
  const ManageFeedbackScreen({super.key, this.feedbackService});

  final FeedbackServiceBase? feedbackService;

  @override
  State<ManageFeedbackScreen> createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen> {
  late final FeedbackServiceBase _feedbackService;
  final Set<String> _replyingIds = <String>{};
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
  }

  Future<void> _refreshFeedback() async {
    if (!mounted) {
      return;
    }

    setState(() => _refreshVersion += 1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  Future<bool> _deleteFeedback(FeedbackEntry feedback) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete feedback?'),
          content: Text('Delete the feedback from ${feedback.userName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return false;
    }

    try {
      await _feedbackService.deleteFeedback(feedback.id);
      if (!mounted) {
        return false;
      }
      AppSnackBar.showSuccess(context, 'Feedback deleted.');
      return true;
    } on FirebaseException catch (error) {
      if (!mounted) {
        return false;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to delete feedback right now.',
      );
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      AppSnackBar.showError(context, 'Unable to delete feedback right now.');
      return false;
    }
  }

  Future<void> _replyToFeedback(FeedbackEntry feedback) async {
    if (_replyingIds.contains(feedback.id)) {
      return;
    }

    final String? reply = await _showReplyDialog(feedback);
    if (reply == null || reply.trim().isEmpty || !mounted) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    setState(() => _replyingIds.add(feedback.id));
    try {
      await _feedbackService.replyToFeedback(
        feedbackId: feedback.id,
        reply: reply.trim(),
      );
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, 'Reply sent.');
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to send reply. Please check permissions.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to send reply right now.');
    } finally {
      if (mounted) {
        setState(() => _replyingIds.remove(feedback.id));
      }
    }
  }

  Future<String?> _showReplyDialog(FeedbackEntry feedback) async {
    final TextEditingController controller = TextEditingController(
      text: feedback.adminReply,
    );
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBackground = isDarkMode
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.borderGreen;

    final String? reply = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          title: Text(
            feedback.isReplied ? 'Update Reply' : 'Reply to Feedback',
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          content: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            cursorColor: primaryTextColor,
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Write admin reply',
              hintStyle: TextStyle(
                color: primaryTextColor.withValues(alpha: 0.45),
                fontFamily: 'Times New Roman',
              ),
              filled: true,
              fillColor: isDarkMode ? AppColors.darkBackground : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryTextColor, width: 1.5),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: primaryTextColor,
                  fontFamily: 'Times New Roman',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final String value = controller.text.trim();
                if (value.isEmpty) {
                  AppSnackBar.showError(dialogContext, 'Reply is required.');
                  return;
                }
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(dialogContext).pop(value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTextColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.send_outlined),
              label: const Text(
                'Send',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return reply;
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

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Feedback',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<FeedbackEntry>>(
          key: ValueKey<int>(_refreshVersion),
          stream: _feedbackService.watchAllFeedback(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<FeedbackEntry>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refreshFeedback,
                    color: primaryTextColor,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      children: <Widget>[
                        _FeedbackStateCard(
                          icon: Icons.cloud_off_outlined,
                          title: 'Unable to load feedback',
                          message: 'Check Firestore rules and try again.',
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
                    child: CircularProgressIndicator(color: primaryTextColor),
                  );
                }

                final List<FeedbackEntry> feedbackItems =
                    snapshot.data ?? <FeedbackEntry>[];
                if (feedbackItems.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshFeedback,
                    color: primaryTextColor,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      children: <Widget>[
                        _FeedbackStateCard(
                          icon: Icons.rate_review_outlined,
                          title: 'No feedback yet',
                          message: 'User feedback will appear here.',
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshFeedback,
                  color: primaryTextColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: feedbackItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final FeedbackEntry feedback = feedbackItems[index];
                      return Padding(
                        key: ValueKey<String>(feedback.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedbackCard(
                          feedback: feedback,
                          isReplying: _replyingIds.contains(feedback.id),
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
                          onReply: () => _replyToFeedback(feedback),
                          onDelete: () {
                            _deleteFeedback(feedback);
                          },
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

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.feedback,
    required this.isReplying,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onReply,
    required this.onDelete,
  });

  final FeedbackEntry feedback;
  final bool isReplying;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    feedback.userName.isEmpty
                        ? 'Unknown User'
                        : feedback.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
                _RatingStars(rating: feedback.rating),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _formatDateTime(feedback.createdAt),
              style: TextStyle(
                color: primaryTextColor.withValues(alpha: 0.56),
                fontFamily: 'Times New Roman',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              feedback.message,
              style: TextStyle(
                color: primaryTextColor.withValues(alpha: 0.85),
                fontFamily: 'Times New Roman',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            if (feedback.isReplied) ...<Widget>[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: primaryTextColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Admin Reply',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontFamily: 'Times New Roman',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        feedback.adminReply,
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.82),
                          fontFamily: 'Times New Roman',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: 'Delete feedback',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isReplying ? null : onReply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTextColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isReplying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.reply_outlined),
                    label: Text(
                      feedback.isReplied ? 'Update Reply' : 'Reply',
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 17,
        );
      }),
    );
  }
}

class _FeedbackStateCard extends StatelessWidget {
  const _FeedbackStateCard({
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
