import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/admin/models/admin_user_profile.dart';
import 'package:smarttrip_ai/modules/admin/services/admin_firestore_service.dart';
import 'package:smarttrip_ai/modules/admin/common/admin_constants.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key, this.firestoreService});

  final AdminFirestoreService? firestoreService;

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late final AdminFirestoreService _firestoreService;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _deletingUserIds = <String>{};
  int _refreshVersion = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? AdminFirestoreService();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final String nextQuery = _searchController.text.trim().toLowerCase();
    if (nextQuery == _query) return;
    setState(() => _query = nextQuery);
  }

  Future<void> _refreshUsers() async {
    if (!mounted) {
      return;
    }

    setState(() => _refreshVersion += 1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  List<AdminUserProfile> _filterUsers(List<AdminUserProfile> users) {
    if (_query.isEmpty) return users;
    return users.where((AdminUserProfile user) {
      if (AdminCredentials.isAdminEmail(user.email)) {
        return false;
      }
      return user.displayName.toLowerCase().contains(_query) ||
          user.email.toLowerCase().contains(_query);
    }).toList();
  }

  Future<void> _deleteUser(AdminUserProfile user) async {
    if (_deletingUserIds.contains(user.id)) return;
    if (AdminCredentials.isAdminEmail(user.email)) {
      return;
    }

    final bool confirmed = await _showDeleteConfirmationDialog(user);
    if (!confirmed || !mounted) return;

    setState(() => _deletingUserIds.add(user.id));
    try {
      await _firestoreService.deleteUser(user.id);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'User deleted.');
    } on Exception catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Unable to delete user right now.');
    } finally {
      if (mounted) setState(() => _deletingUserIds.remove(user.id));
    }
  }

  Future<bool> _showDeleteConfirmationDialog(AdminUserProfile user) async {
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

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          title: Text(
            'Delete User',
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          content: Text(
            'Remove ${user.displayName} from the users collection?',
            style: TextStyle(
              color: primaryTextColor.withValues(alpha: 0.75),
              fontFamily: 'Times New Roman',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Delete',
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

    return result ?? false;
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
          'Manage Users',
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
        child: StreamBuilder<List<AdminUserProfile>>(
          key: ValueKey<int>(_refreshVersion),
          stream: _firestoreService.watchUsers(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<AdminUserProfile>> snapshot,
              ) {
                final List<AdminUserProfile> users = _filterUsers(
                  snapshot.data ?? <AdminUserProfile>[],
                );

                return RefreshIndicator(
                  onRefresh: _refreshUsers,
                  color: primaryTextColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    children: <Widget>[
                      _AdminSearchField(
                        controller: _searchController,
                        primaryTextColor: primaryTextColor,
                        borderColor: borderColor,
                        fillColor: cardColor,
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.hasError)
                        _AdminStateCard(
                          icon: Icons.cloud_off_outlined,
                          title: 'Unable to load users',
                          message: 'Check Firestore rules and try again.',
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
                        )
                      else if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          snapshot.data == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryTextColor,
                            ),
                          ),
                        )
                      else if (users.isEmpty)
                        _AdminStateCard(
                          icon: Icons.person_search_rounded,
                          title: _query.isEmpty
                              ? 'No users found'
                              : 'No match found',
                          message: _query.isEmpty
                              ? 'User documents from Firestore will appear here.'
                              : 'Try searching by another name or email.',
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
                        )
                      else
                        ...users.map(
                          (AdminUserProfile user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UserCard(
                              user: user,
                              isDeleting: _deletingUserIds.contains(user.id),
                              primaryTextColor: primaryTextColor,
                              backgroundColor: cardColor,
                              borderColor: borderColor,
                              onDelete: () => _deleteUser(user),
                            ),
                          ),
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

class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({
    required this.controller,
    required this.primaryTextColor,
    required this.borderColor,
    required this.fillColor,
  });

  final TextEditingController controller;
  final Color primaryTextColor;
  final Color borderColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: primaryTextColor,
      style: TextStyle(
        color: primaryTextColor,
        fontFamily: 'Times New Roman',
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search users',
        hintStyle: TextStyle(
          color: primaryTextColor.withValues(alpha: 0.45),
          fontFamily: 'Times New Roman',
        ),
        prefixIcon: Icon(Icons.search_rounded, color: primaryTextColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryTextColor, width: 1.5),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isDeleting,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onDelete,
  });

  final AdminUserProfile user;
  final bool isDeleting;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;
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
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryTextColor.withValues(alpha: 0.12),
              child: Icon(
                Icons.person_outline_rounded,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.72),
                      fontFamily: 'Times New Roman',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Created: ${_formatDate(user.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.58),
                      fontFamily: 'Times New Roman',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete user',
              onPressed: isDeleting ? null : onDelete,
              icon: isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryTextColor,
                      ),
                    )
                  : Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade700,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStateCard extends StatelessWidget {
  const _AdminStateCard({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
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
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not available';
  final DateTime localDate = date.toLocal();
  final String month = localDate.month.toString().padLeft(2, '0');
  final String day = localDate.day.toString().padLeft(2, '0');
  return '${localDate.year}-$month-$day';
}
