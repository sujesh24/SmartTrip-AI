import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';
import 'dart:io';
import 'package:smarttrip_ai/modules/ai_generation/screens/step1.dart';
import 'package:smarttrip_ai/modules/feedback/models/feedback_entry.dart';
import 'package:smarttrip_ai/modules/feedback/screens/notifications_screen.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';
import 'package:smarttrip_ai/modules/feedback/services/user_notification_service.dart';
import 'package:smarttrip_ai/modules/home/common/home_username_formatter.dart';
import 'package:smarttrip_ai/modules/home/screens/destination_detail_screen.dart';
import 'package:smarttrip_ai/modules/home/screens/explore_more_destinations_screen.dart';
import 'package:smarttrip_ai/modules/home/services/home_destination_image_cache.dart';
import 'package:smarttrip_ai/modules/home/services/home_destination_image_loader.dart';
import 'package:smarttrip_ai/modules/home/widgets/add_itinerary_popup.dart';
import 'package:smarttrip_ai/modules/home/widgets/home_destination_card.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/screens/saved_trips_screen.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/services/saved_itinerary_store.dart';
import 'package:smarttrip_ai/modules/settings/screens/settings_screen.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';
import 'package:smarttrip_ai/modules/trending_places/services/trending_places_service.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/theme/app_theme_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authService,
    this.imageLoader,
    this.imageCache,
    this.savedItineraryStore,
    this.placesService,
    this.feedbackService,
    this.notificationService,
  });

  final AuthServiceBase? authService;
  final HomeDestinationImageLoader? imageLoader;
  final HomeDestinationImageCache? imageCache;
  final SavedItineraryStore? savedItineraryStore;
  final TrendingPlacesServiceBase? placesService;
  final FeedbackServiceBase? feedbackService;
  final UserNotificationServiceBase? notificationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AuthServiceBase _authService;
  late final TrendingPlacesServiceBase _placesService;
  late final FeedbackServiceBase _feedbackService;
  late final UserNotificationServiceBase _notificationService;
  late final AnimationController _popupAnimationController;
  late final AnimationController _refreshBounceController;
  late final Animation<double> _refreshBounceScale;
  String? _customUsername;
  String? _localAvatarPath;

  bool _isPopupOpen = false;
  bool _isOpeningPopup = false;
  bool _isRefreshing = false;

  static const Duration _homeIconSpinDuration = Duration(milliseconds: 240);

  @override
  void initState() {
    super.initState();

    _authService = widget.authService ?? AuthService();
    final bool hasFirebase = Firebase.apps.isNotEmpty;
    _placesService =
        widget.placesService ??
        (hasFirebase ? TrendingPlacesService() : _NoOpTrendingPlacesService());
    _feedbackService =
        widget.feedbackService ??
        (hasFirebase ? FeedbackService() : _NoOpFeedbackService());
    _notificationService =
        widget.notificationService ??
        (hasFirebase
            ? FirestoreUserNotificationService(
                feedbackService: _feedbackService,
              )
            : FeedbackOnlyUserNotificationService(service: _feedbackService));

    _popupAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    );

    _refreshBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _refreshBounceScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 0.985,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.985,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_refreshBounceController);
    _loadCustomUsername();
  }

  @override
  void dispose() {
    _refreshBounceController.dispose();
    _popupAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshHomeContent() async {
    if (_isRefreshing) {
      return;
    }

    setState(() => _isRefreshing = true);
    await _loadCustomUsername();
    await _refreshBounceController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _showAddPopup() async {
    if (_isPopupOpen || _isOpeningPopup) {
      return;
    }

    setState(() {
      _isPopupOpen = true;
      _isOpeningPopup = true;
    });
    await Future<void>.delayed(_homeIconSpinDuration);
    if (!mounted) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: _popupAnimationController,
      builder: (BuildContext sheetContext) {
        return AddItineraryPopup(
          onCreatePressed: () async {
            await _dismissPopup(sheetContext);
            if (!mounted) {
              return;
            }
            navigator.push(
              MaterialPageRoute<void>(builder: (_) => const ItineraryOne()),
            );
          },
          onClosePressed: () => _dismissPopup(sheetContext),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isPopupOpen = false;
        _isOpeningPopup = false;
      });
    }
  }

  Future<void> _dismissPopup(BuildContext sheetContext) async {
    if (mounted && _isPopupOpen) {
      setState(() => _isPopupOpen = false);
    }
    Navigator.of(sheetContext).pop();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(authService: _authService),
      ),
    );
    if (mounted) {
      await _loadCustomUsername();
    }
  }

  void _openSavedTrips() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedTripsScreen(store: widget.savedItineraryStore),
      ),
    );
  }

  void _openExploreMore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExploreMoreDestinationsScreen(placesService: _placesService),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          authService: _authService,
          feedbackService: _feedbackService,
          notificationService: _notificationService,
        ),
      ),
    );
  }

  void _openPlaceDetail(TrendingPlace place) {
    Navigator.of(
      context,
    ).push(buildDestinationDetailRoute(place: place, imageUrl: place.imageUrl));
  }

  Stream<int> _watchUnreadNotifications() {
    final String? userId = _authService.currentUserId;
    if (userId == null || userId.isEmpty) {
      return Stream<int>.value(0);
    }
    return _notificationService.watchUnreadCount(userId);
  }

  Future<void> _loadCustomUsername() async {
    final String? userId = _authService.currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (!mounted) {
        return;
      }
      final String? name = snapshot.data()?['name'] as String?;
      final String? avatarPath = snapshot.data()?['avatarPath'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        setState(() => _customUsername = name.trim());
      }
      if (avatarPath != null && avatarPath.trim().isNotEmpty) {
        setState(() => _localAvatarPath = avatarPath.trim());
      }
    } catch (_) {
      // Silently fail; fall back to email-derived username.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.instance.themeModeListenable,
      builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
        final bool isDarkMode = themeMode == ThemeMode.dark;
        final Color pageColor = isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground;
        final Color titleColor = isDarkMode
            ? AppColors.accentGreen
            : AppColors.primaryGreen;
        final Color cardColor = isDarkMode
            ? AppColors.darkSurface
            : Colors.white;
        final Color borderColor = isDarkMode
            ? AppColors.darkBorder
            : const Color(0x338DA180);

        final String username =
            _customUsername ??
            formatHomeUsername(_authService.currentUserEmail);
        return Scaffold(
          backgroundColor: pageColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              color: titleColor,
              onRefresh: _refreshHomeContent,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: ScaleTransition(
                  scale: _refreshBounceScale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        key: const Key('home_profile_header_button'),
                        onTap: _openSettings,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 21,
                                backgroundColor: isDarkMode
                                    ? AppColors.darkSurface
                                    : AppColors.borderGreen.withValues(
                                        alpha: 0.3,
                                      ),
                                backgroundImage:
                                    _localAvatarPath != null &&
                                        _localAvatarPath!.isNotEmpty
                                    ? FileImage(File(_localAvatarPath!))
                                          as ImageProvider
                                    : null,
                                child: _localAvatarPath == null
                                    ? Icon(
                                        Icons.person,
                                        color: titleColor,
                                        size: 24,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      username,
                                      key: const Key('home_username'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontFamily: 'Times New Roman',
                                        fontSize: 27,
                                        fontWeight: FontWeight.w600,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PromoBanner(titleColor: titleColor),
                      const SizedBox(height: 14),
                      Text(
                        'Popular Places',
                        style: TextStyle(
                          color: titleColor,
                          fontFamily: 'Times New Roman',
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<TrendingPlace>>(
                        stream: _placesService.watchTrendingPlaces(),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<TrendingPlace>> snapshot,
                            ) {
                              if (snapshot.hasError) {
                                return _HomeStateCard(
                                  icon: Icons.cloud_off_outlined,
                                  title: 'Unable to load places',
                                  message:
                                      'Check your connection and try again.',
                                  primaryTextColor: titleColor,
                                  backgroundColor: cardColor,
                                  borderColor: borderColor,
                                );
                              }

                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  snapshot.data == null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 50),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: titleColor,
                                    ),
                                  ),
                                );
                              }

                              final List<TrendingPlace> places =
                                  snapshot.data ?? <TrendingPlace>[];
                              if (places.isEmpty) {
                                return _HomeStateCard(
                                  icon: Icons.travel_explore_outlined,
                                  title: 'No popular places yet',
                                  message:
                                      'Admin-added destinations will appear here.',
                                  primaryTextColor: titleColor,
                                  backgroundColor: cardColor,
                                  borderColor: borderColor,
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  GridView.builder(
                                    key: const Key('home_destination_grid'),
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: places.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.92,
                                        ),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final TrendingPlace place =
                                              places[index];
                                          return HomeDestinationCard(
                                            key: Key(
                                              'home_destination_card_${place.id}',
                                            ),
                                            place: place,
                                            imageUrl: place.imageUrl,
                                            showLoading: false,
                                            heroTag: trendingPlaceHeroTag(
                                              place.id,
                                            ),
                                            onTap: () =>
                                                _openPlaceDetail(place),
                                          );
                                        },
                                  ),
                                  const SizedBox(height: 14),
                                  if (_isRefreshing)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: LinearProgressIndicator(
                                        minHeight: 3,
                                        color: titleColor,
                                        backgroundColor: titleColor.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                  ElevatedButton(
                                    key: const Key('home_explore_more_button'),
                                    onPressed: _openExploreMore,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: titleColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Explore More',
                                      style: TextStyle(
                                        fontFamily: 'Times New Roman',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: StreamBuilder<int>(
            stream: _watchUnreadNotifications(),
            initialData: 0,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              return _HomeBottomNavigationBar(
                onAddPressed: _showAddPopup,
                onNotificationsPressed: _openNotifications,
                onSavedItemsPressed: _openSavedTrips,
                onSettingsPressed: _openSettings,
                notificationBadgeCount: snapshot.data ?? 0,
                isPopupOpen: _isPopupOpen,
              );
            },
          ),
        );
      },
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.titleColor});

  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double bannerHeight = compact ? 104 : 112;

        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 11,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  AppAssets.itineraryHeader,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(color: AppColors.borderGreen);
                  },
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xA6000000), Color(0x42000000)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 22, 10, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 6,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(1, 7, 10, 7),
                            decoration: BoxDecoration(
                              color: const Color(0x4DFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Discover new places and build your next unforgettable trip.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Times New Roman',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'New Era\nJourney',
                              maxLines: 2,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: titleColor == AppColors.accentGreen
                                    ? AppColors.accentGreen
                                    : Colors.white,
                                fontFamily: 'Times New Roman',
                                fontSize: compact ? 32 : 30,
                                fontWeight: FontWeight.w600,
                                height: 0.95,
                              ),
                            ),
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
      },
    );
  }
}

class _HomeStateCard extends StatelessWidget {
  const _HomeStateCard({
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

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.onAddPressed,
    required this.onNotificationsPressed,
    required this.onSavedItemsPressed,
    required this.onSettingsPressed,
    required this.notificationBadgeCount,
    required this.isPopupOpen,
  });

  final VoidCallback onAddPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onSavedItemsPressed;
  final VoidCallback onSettingsPressed;
  final int notificationBadgeCount;
  final bool isPopupOpen;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color barColor = isDarkMode
        ? AppColors.darkSurface
        : AppColors.lightBackground;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        height: 82,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.near_me,
                  selectedIcon: Icons.near_me,
                  label: 'Discover',
                  selected: true,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  key: const Key('home_notifications_nav'),
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  label: 'Notification',
                  badgeCount: notificationBadgeCount,
                  onTap: onNotificationsPressed,
                ),
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: onAddPressed,
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.borderGreen,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: isPopupOpen ? 0.125 : 0,
                        duration: _HomeScreenState._homeIconSpinDuration,
                        curve: Curves.easeInOutCubic,
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  key: const Key('home_saved_items_nav'),
                  icon: Icons.bookmark_outline,
                  selectedIcon: Icons.bookmark,
                  label: 'Saved',
                  onTap: onSavedItemsPressed,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  key: const Key('home_settings_nav'),
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Setting',
                  onTap: onSettingsPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.selected = false,
    this.badgeCount = 0,
    this.onTap,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color unselectedColor = isDarkMode
        ? AppColors.accentGreen.withValues(alpha: 0.62)
        : AppColors.primaryGreen.withValues(alpha: 0.55);

    final Color color = selected ? AppColors.borderGreen : unselectedColor;
    final IconData activeIcon = selected ? (selectedIcon ?? icon) : icon;

    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                  child: Stack(
                    key: ValueKey<IconData>(activeIcon),
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Icon(activeIcon, color: color, size: 28),
                      if (badgeCount > 0)
                        Positioned(
                          right: -10,
                          top: -7,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              badgeCount > 9 ? '9+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Times New Roman',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _NoOpFeedbackService implements FeedbackServiceBase {
  @override
  Future<void> markFeedbackRead(String feedbackId) async {}

  @override
  Future<void> replyToFeedback({
    required String feedbackId,
    required String reply,
  }) async {}

  @override
  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String message,
    required int rating,
  }) async {}

  @override
  Stream<List<FeedbackEntry>> watchAllFeedback() {
    return Stream<List<FeedbackEntry>>.value(<FeedbackEntry>[]);
  }

  @override
  Stream<List<FeedbackEntry>> watchRepliedFeedbackForUser(String userId) {
    return Stream<List<FeedbackEntry>>.value(<FeedbackEntry>[]);
  }

  @override
  Stream<int> watchUnreadReplyCount(String userId) {
    return Stream<int>.value(0);
  }

  @override
  Future<void> deleteFeedback(String feedbackId) async {}
}

class _NoOpTrendingPlacesService implements TrendingPlacesServiceBase {
  @override
  Future<void> addTrendingPlace(TrendingPlace place) async {}

  @override
  Future<void> deleteTrendingPlace(String placeId) async {}

  @override
  Future<int> seedDefaultTrendingPlaces() async => 0;

  @override
  Future<void> updateTrendingPlace(TrendingPlace place) async {}

  @override
  Stream<List<TrendingPlace>> watchTrendingPlaces() {
    return Stream<List<TrendingPlace>>.value(<TrendingPlace>[]);
  }
}
