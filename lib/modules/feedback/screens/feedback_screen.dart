import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';
import 'package:smarttrip_ai/modules/home/common/home_username_formatter.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.authService,
    this.feedbackService,
  });

  final AuthServiceBase authService;
  final FeedbackServiceBase? feedbackService;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final FeedbackServiceBase _feedbackService;
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) {
      return;
    }

    final String? userId = widget.authService.currentUserId;
    if (userId == null || userId.isEmpty) {
      AppSnackBar.showError(context, 'Please login before sending feedback.');
      return;
    }

    if (_rating == 0) {
      AppSnackBar.showError(context, 'Choose a star rating.');
      return;
    }

    final String message = _messageController.text.trim();
    if (message.isEmpty) {
      AppSnackBar.showError(context, 'Feedback message is required.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _feedbackService.submitFeedback(
        userId: userId,
        userName: formatHomeUsername(widget.authService.currentUserEmail),
        message: message,
        rating: _rating,
      );
      if (!mounted) {
        return;
      }
      _messageController.clear();
      setState(() => _rating = 0);
      AppSnackBar.showSuccess(context, 'Feedback submitted.');
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to submit feedback. Please try again.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to submit feedback right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          'Feedback',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Rate your experience',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontFamily: 'Times New Roman',
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(5, (int index) {
                        final int value = index + 1;
                        return IconButton(
                          tooltip: '$value star',
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() => _rating = value),
                          icon: Icon(
                            value <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 38,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _messageController,
                      enabled: !_isSubmitting,
                      minLines: 5,
                      maxLines: 8,
                      cursorColor: primaryTextColor,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your feedback',
                        hintStyle: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.45),
                          fontFamily: 'Times New Roman',
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.darkBackground
                            : Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryTextColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTextColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit Feedback',
                          style: const TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
