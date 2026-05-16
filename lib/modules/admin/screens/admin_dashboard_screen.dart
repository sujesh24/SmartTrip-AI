import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_feedback_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_trending_places_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_users_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_generated_places_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/admin_settings_screen.dart';
import 'package:smarttrip_ai/modules/admin/services/admin_session_service.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.authService,
    this.sessionService,
  });

  final AuthServiceBase authService;
  final AdminSessionService? sessionService;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _refreshVersion = 0;

  void _openManageUsers() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ManageUsersScreen()));
  }

  void _openManageTrendingPlaces() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ManageTrendingPlacesScreen(),
      ),
    );
  }

  void _openManageFeedback() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ManageFeedbackScreen()),
    );
  }

  void _openManageGeneratedPlaces() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ManageGeneratedPlacesScreen(),
      ),
    );
  }

  void _openAdminSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminSettingsScreen(authService: widget.authService),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) {
      return;
    }

    setState(() => _refreshVersion += 1);
    try {
      await Future.wait(<Future<void>>[
        FirebaseFirestore.instance
            .collection('users')
            .limit(1)
            .get()
            .then((_) {}),
        FirebaseFirestore.instance
            .collection('feedback')
            .limit(1)
            .get()
            .then((_) {}),
        FirebaseFirestore.instance
            .collection('trending_places')
            .limit(1)
            .get()
            .then((_) {}),
        FirebaseFirestore.instance
            .collection('generated_places')
            .limit(1)
            .get()
            .then((_) {}),
      ]);
    } catch (_) {
      // Keep pull-to-refresh silent when offline or blocked by rules.
    }
  }

  Future<void> _openBroadcastDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
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

    final _BroadcastDraft? draft = await showDialog<_BroadcastDraft>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          title: Text(
            'Broadcast to Users',
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                cursorColor: primaryTextColor,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                minLines: 3,
                maxLines: 5,
                cursorColor: primaryTextColor,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String title = titleController.text.trim();
                final String message = messageController.text.trim();
                if (title.isEmpty || message.isEmpty) {
                  AppSnackBar.showError(
                    dialogContext,
                    'Title and message are required.',
                  );
                  return;
                }

                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(
                  dialogContext,
                ).pop(_BroadcastDraft(title: title, message: message));
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    messageController.dispose();

    if (draft == null || !mounted) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .add(<String, Object?>{
            'title': draft.title,
            'message': draft.message,
            'created_at': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'created_by': widget.authService.currentUserEmail ?? '',
            'created_by_user_id': widget.authService.currentUserId ?? '',
            'is_active': true,
          });
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, 'Broadcast sent to users.');
    } on FirebaseException catch (error) {
      debugPrint('Unable to send broadcast: ${error.code} ${error.message}');
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to send broadcast. Check Firestore rules.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to send broadcast.');
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            onPressed: _openAdminSettings,
            icon: Icon(Icons.settings_rounded, color: primaryTextColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 520;
            final int crossAxisCount = compact
                ? 1
                : constraints.maxWidth >= 720
                ? 3
                : 2;
            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: primaryTextColor,
              child: GridView.count(
                key: ValueKey<int>(_refreshVersion),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: compact
                    ? 1.55
                    : constraints.maxWidth < 380
                    ? 1.12
                    : 1.18,
                children: <Widget>[
                  _DashboardCard(
                    title: 'Manage Users',
                    subtitle: 'Search, review, and remove user records',
                    icon: Icons.people_alt_outlined,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onTap: _openManageUsers,
                  ),
                  _DashboardCard(
                    title: 'Trending Places',
                    subtitle: 'Add, edit, and publish destination cards',
                    icon: Icons.travel_explore_rounded,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onTap: _openManageTrendingPlaces,
                  ),
                  _DashboardCard(
                    title: 'Feedback',
                    subtitle: 'Read ratings and reply to users',
                    icon: Icons.rate_review_outlined,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onTap: _openManageFeedback,
                  ),
                  _DashboardCard(
                    title: 'Broadcast',
                    subtitle: 'Send one announcement to all users',
                    icon: Icons.campaign_outlined,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onTap: _openBroadcastDialog,
                  ),
                  _DashboardCard(
                    title: 'Generated Places',
                    subtitle: 'Review AI-generated places from users',
                    icon: Icons.public_rounded,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onTap: _openManageGeneratedPlaces,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BroadcastDraft {
  const _BroadcastDraft({required this.title, required this.message});

  final String title;
  final String message;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color primaryTextColor;
  final VoidCallback? onTap;

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
            border: Border.all(color: borderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryTextColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primaryTextColor, size: 27),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.68),
                    fontFamily: 'Times New Roman',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.18,
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
