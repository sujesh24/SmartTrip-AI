import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/home/screens/destination_detail_screen.dart';
import 'package:smarttrip_ai/modules/home/widgets/home_destination_card.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';
import 'package:smarttrip_ai/modules/trending_places/services/trending_places_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ExploreMoreDestinationsScreen extends StatefulWidget {
  const ExploreMoreDestinationsScreen({super.key, this.placesService});

  final TrendingPlacesServiceBase? placesService;

  @override
  State<ExploreMoreDestinationsScreen> createState() =>
      _ExploreMoreDestinationsScreenState();
}

class _ExploreMoreDestinationsScreenState
    extends State<ExploreMoreDestinationsScreen> {
  late final TrendingPlacesServiceBase _placesService;

  @override
  void initState() {
    super.initState();
    _placesService = widget.placesService ?? TrendingPlacesService();
  }

  void _openPlaceDetail(TrendingPlace place) {
    Navigator.of(
      context,
    ).push(buildDestinationDetailRoute(place: place, imageUrl: place.imageUrl));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pageColor = isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color titleColor = isDarkMode
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
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          'Explore More',
          style: TextStyle(
            color: titleColor,
            fontFamily: 'Times New Roman',
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<TrendingPlace>>(
        stream: _placesService.watchTrendingPlaces(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<TrendingPlace>> snapshot,
            ) {
              if (snapshot.hasError) {
                return _ExploreStateCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Unable to load places',
                  message: 'Check your connection and try again.',
                  primaryTextColor: titleColor,
                  backgroundColor: cardColor,
                  borderColor: borderColor,
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return Center(
                  child: CircularProgressIndicator(color: titleColor),
                );
              }

              final List<TrendingPlace> places =
                  snapshot.data ?? <TrendingPlace>[];
              if (places.isEmpty) {
                return _ExploreStateCard(
                  icon: Icons.travel_explore_outlined,
                  title: 'No popular places yet',
                  message: 'New admin-added destinations will appear here.',
                  primaryTextColor: titleColor,
                  backgroundColor: cardColor,
                  borderColor: borderColor,
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: places.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final TrendingPlace place = places[index];
                  return HomeDestinationCard(
                    key: Key('explore_destination_card_${place.id}'),
                    place: place,
                    imageUrl: place.imageUrl,
                    showLoading: false,
                    heroTag: trendingPlaceHeroTag(place.id),
                    onTap: () => _openPlaceDetail(place),
                  );
                },
              );
            },
      ),
    );
  }
}

class _ExploreStateCard extends StatelessWidget {
  const _ExploreStateCard({
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
