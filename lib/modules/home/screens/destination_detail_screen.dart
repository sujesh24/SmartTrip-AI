import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/home/widgets/destination_image_view.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

Route<void> buildDestinationDetailRoute({
  required TrendingPlace place,
  String? imageUrl,
  String? imageBytesBase64,
}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (BuildContext context, Animation<double> animation, _) {
      return DestinationDetailScreen(
        place: place,
        imageUrl: imageUrl,
        imageBytesBase64: imageBytesBase64,
      );
    },
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
  );
}

class DestinationDetailScreen extends StatelessWidget {
  const DestinationDetailScreen({
    super.key,
    required this.place,
    this.imageUrl,
    this.imageBytesBase64,
  });

  final TrendingPlace place;
  final String? imageUrl;
  final String? imageBytesBase64;

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

    return Scaffold(
      backgroundColor: pageColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: pageColor,
            elevation: 0,
            iconTheme: IconThemeData(color: titleColor),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Hero(
                    tag: trendingPlaceHeroTag(place.id),
                    child: DestinationImageView(
                      destinationId: place.id,
                      imageUrl: imageUrl,
                      imageBytesBase64: imageBytesBase64,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x26000000), Color(0xA5000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Text(
                      place.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Times New Roman',
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        height: 0.92,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    key: const Key('destination_detail_title'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      place.displayName,
                      style: TextStyle(
                        color: titleColor,
                        fontFamily: 'Times New Roman',
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    place.description,
                    style: TextStyle(
                      color: titleColor.withValues(alpha: 0.9),
                      fontFamily: 'Times New Roman',
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _MetaChip(
                        key: const Key('destination_detail_best_time'),
                        title: 'Best Time',
                        value: place.bestTime,
                        titleColor: titleColor,
                        cardColor: cardColor,
                      ),
                      _MetaChip(
                        key: const Key('destination_detail_budget'),
                        title: 'Budget',
                        value: place.budget,
                        titleColor: titleColor,
                        cardColor: cardColor,
                      ),
                      _MetaChip(
                        key: const Key('destination_detail_rating'),
                        title: 'Rating',
                        value: place.rating.toStringAsFixed(1),
                        titleColor: titleColor,
                        cardColor: cardColor,
                      ),
                      if (place.category.isNotEmpty)
                        _MetaChip(
                          title: 'Category',
                          value: place.category,
                          titleColor: titleColor,
                          cardColor: cardColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    super.key,
    required this.title,
    required this.value,
    required this.titleColor,
    required this.cardColor,
  });

  final String title;
  final String value;
  final Color titleColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: titleColor.withValues(alpha: 0.7),
              fontFamily: 'Times New Roman',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: titleColor,
              fontFamily: 'Times New Roman',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
