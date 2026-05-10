import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_feedback_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_trending_places_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/manage_users_screen.dart';
import 'package:smarttrip_ai/modules/admin/services/admin_session_service.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/trending_places/services/trending_places_service.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
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
  late final AdminSessionService _sessionService;
  late final TrendingPlacesServiceBase _placesService;
  bool _isLoggingOut = false;
  bool _isSeedingPlaces = false;

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService ?? AdminSessionService();
    _placesService = TrendingPlacesService();
  }

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

  Future<void> _seedPopularPlaces() async {
    if (_isSeedingPlaces) {
      return;
    }

    setState(() => _isSeedingPlaces = true);
    try {
      final int createdCount = await _placesService.seedDefaultTrendingPlaces();
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        createdCount == 0
            ? 'Default places already exist. No new places added.'
            : 'Seeded $createdCount new popular places.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to seed popular places.');
    } finally {
      if (mounted) {
        setState(() => _isSeedingPlaces = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await _sessionService.clearAdminSession();
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to logout. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
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
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.logout_rounded, color: primaryTextColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.count(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: constraints.maxWidth < 380 ? 0.95 : 1.08,
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
                  title: 'Seed Places',
                  subtitle: 'Initialize default places (skips existing)',
                  icon: Icons.auto_awesome_motion_outlined,
                  backgroundColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  onTap: _isSeedingPlaces ? null : _seedPopularPlaces,
                  isLoading: _isSeedingPlaces,
                ),
                _DashboardCard(
                  title: 'Logout',
                  subtitle: 'Clear the secure admin session',
                  icon: Icons.lock_reset_rounded,
                  backgroundColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  onTap: _isLoggingOut ? null : _logout,
                  isLoading: _isLoggingOut,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color primaryTextColor;
  final VoidCallback? onTap;
  final bool isLoading;

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
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryTextColor,
                          ),
                        )
                      : Icon(icon, color: primaryTextColor, size: 27),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontFamily: 'Times New Roman',
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.68),
                    fontFamily: 'Times New Roman',
                    fontSize: 14,
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
