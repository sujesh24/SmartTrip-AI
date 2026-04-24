import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step1.dart';
import 'package:smarttrip_ai/modules/home/common/home_username_formatter.dart';
import 'package:smarttrip_ai/modules/home/data/home_destinations_data.dart';
import 'package:smarttrip_ai/modules/home/models/home_destination.dart';
import 'package:smarttrip_ai/modules/home/screens/destination_detail_screen.dart';
import 'package:smarttrip_ai/modules/home/screens/explore_more_destinations_screen.dart';
import 'package:smarttrip_ai/modules/home/services/home_destination_image_cache.dart';
import 'package:smarttrip_ai/modules/home/services/home_destination_image_loader.dart';
import 'package:smarttrip_ai/modules/home/widgets/add_itinerary_popup.dart';
import 'package:smarttrip_ai/modules/home/widgets/home_destination_card.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/screens/saved_trips_screen.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/services/saved_itinerary_store.dart';
import 'package:smarttrip_ai/modules/settings/screens/settings_screen.dart';
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
  });

  final AuthServiceBase? authService;
  final HomeDestinationImageLoader? imageLoader;
  final HomeDestinationImageCache? imageCache;
  final SavedItineraryStore? savedItineraryStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AuthServiceBase _authService;
  late final AnimationController _popupAnimationController;

  late final HomeDestinationImageLoader _imageLoader;
  late final bool _ownsImageLoader;
  late final HomeDestinationImageCache _imageCache;
  late final AnimationController _refreshBounceController;
  late final Animation<double> _refreshBounceScale;
  late final SavedItineraryStore _savedItineraryStore;

  late final List<HomeDestination> _destinations;

  final Map<String, String?> _destinationImages = <String, String?>{};
  final Set<String> _loadingDestinationIds = <String>{};

  bool _isPopupOpen = false;
  bool _isOpeningPopup = false;
  bool _isRefreshing = false;

  static const Duration _homeIconSpinDuration = Duration(milliseconds: 240);

  @override
  void initState() {
    super.initState();

    _authService = widget.authService ?? AuthService();
    _destinations = kHomeDestinations
        .where((HomeDestination destination) => destination.showOnHome)
        .toList(growable: false);
    _savedItineraryStore =
        widget.savedItineraryStore ?? SharedPrefsSavedItineraryStore();

    _ownsImageLoader = widget.imageLoader == null;
    _imageLoader = widget.imageLoader ?? PexelsHomeDestinationImageLoader();
    _imageCache = widget.imageCache ?? SharedPrefsHomeDestinationImageCache();

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

    unawaited(_loadCachedAndRemoteImages());
  }

  @override
  void dispose() {
    if (_ownsImageLoader) {
      _imageLoader.dispose();
    }
    _refreshBounceController.dispose();
    _popupAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedAndRemoteImages() async {
    final Map<String, String> cachedUrls = await _imageCache
        .loadCachedImageUrls();
    if (!mounted) {
      return;
    }

    if (cachedUrls.isNotEmpty) {
      setState(() {
        for (final HomeDestination destination in _destinations) {
          final String? cachedUrl = cachedUrls[destination.id];
          if (cachedUrl != null && cachedUrl.isNotEmpty) {
            _destinationImages[destination.id] = cachedUrl;
          }
        }
      });
    }

    _loadDestinationImages();
  }

  void _loadDestinationImages() {
    for (final HomeDestination destination in _destinations) {
      unawaited(_loadDestinationImage(destination));
    }
  }

  Future<void> _loadDestinationImage(HomeDestination destination) async {
    if (_loadingDestinationIds.contains(destination.id) ||
        _destinationImages.containsKey(destination.id)) {
      return;
    }

    if (mounted) {
      setState(() => _loadingDestinationIds.add(destination.id));
    }

    final String? imageUrl = await _imageLoader.fetchImageUrl(destination);
    if (!mounted) {
      return;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      unawaited(
        _imageCache.saveImageUrl(
          destinationId: destination.id,
          imageUrl: imageUrl,
        ),
      );
    }

    setState(() {
      _loadingDestinationIds.remove(destination.id);
      _destinationImages[destination.id] = imageUrl;
    });
  }

  Future<void> _refreshHomeContent() async {
    if (_isRefreshing) {
      return;
    }

    setState(() => _isRefreshing = true);
    await _refreshBounceController.forward(from: 0);

    final List<Future<void>> requests = <Future<void>>[];
    for (final HomeDestination destination in _destinations) {
      requests.add(_refreshSingleDestination(destination));
    }
    await Future.wait(requests);

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshSingleDestination(HomeDestination destination) async {
    if (!mounted) {
      return;
    }

    setState(() => _loadingDestinationIds.add(destination.id));
    try {
      final String? imageUrl = await _imageLoader.fetchImageUrl(destination);
      if (!mounted || imageUrl == null || imageUrl.isEmpty) {
        return;
      }

      await _imageCache.saveImageUrl(
        destinationId: destination.id,
        imageUrl: imageUrl,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _destinationImages[destination.id] = imageUrl;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingDestinationIds.remove(destination.id));
      }
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(authService: _authService),
      ),
    );
  }

  void _openExploreMore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreMoreDestinationsScreen(
          destinations: _destinations,
          initialImageUrls: _destinationImages,
          imageLoader: _imageLoader,
        ),
      ),
    );
  }

  void _openMyItems() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedTripsScreen(store: _savedItineraryStore),
      ),
    );
  }

  void _openDestinationDetail(HomeDestination destination) {
    Navigator.of(context).push(
      buildDestinationDetailRoute(
        destination: destination,
        imageUrl: _destinationImages[destination.id],
      ),
    );
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

        final String username = formatHomeUsername(
          _authService.currentUserEmail,
        );
        final String handle = '@${username.toLowerCase().replaceAll(' ', '')}';

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
                                child: Icon(
                                  Icons.person,
                                  color: titleColor,
                                  size: 24,
                                ),
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
                                    Text(
                                      handle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: titleColor.withValues(
                                          alpha: 0.64,
                                        ),
                                        fontFamily: 'Times New Roman',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
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
                      GridView.builder(
                        key: const Key('home_destination_grid'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _destinations.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.92,
                            ),
                        itemBuilder: (BuildContext context, int index) {
                          final HomeDestination destination =
                              _destinations[index];
                          return HomeDestinationCard(
                            key: Key('home_destination_card_${destination.id}'),
                            destination: destination,
                            imageUrl: _destinationImages[destination.id],
                            showLoading: _loadingDestinationIds.contains(
                              destination.id,
                            ),
                            heroTag: homeDestinationHeroTag(destination.id),
                            onTap: () => _openDestinationDetail(destination),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_isRefreshing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: titleColor,
                            backgroundColor: titleColor.withValues(alpha: 0.22),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('home_explore_more_button'),
                          onPressed: _openExploreMore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: titleColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _HomeBottomNavigationBar(
            onAddPressed: _showAddPopup,
            onMyItemsPressed: _openMyItems,
            onSettingsPressed: _openSettings,
            isPopupOpen: _isPopupOpen,
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

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.onAddPressed,
    required this.onMyItemsPressed,
    required this.onSettingsPressed,
    required this.isPopupOpen,
  });

  final VoidCallback onAddPressed;
  final VoidCallback onMyItemsPressed;
  final VoidCallback onSettingsPressed;
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
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  label: 'Notification',
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
                  key: const Key('home_my_items_nav'),
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  label: 'My Items',
                  onTap: onMyItemsPressed,
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
    this.onTap,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
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
                  child: Icon(
                    activeIcon,
                    key: ValueKey<IconData>(activeIcon),
                    color: color,
                    size: 28,
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
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
