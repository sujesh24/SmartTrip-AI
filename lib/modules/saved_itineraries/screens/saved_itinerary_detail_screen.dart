import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_day_section.dart';
import 'package:smarttrip_ai/modules/home/widgets/destination_image_view.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/models/saved_itinerary.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class SavedItineraryDetailScreen extends StatelessWidget {
  const SavedItineraryDetailScreen({super.key, required this.itinerary});

  final SavedItinerary itinerary;

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
                    tag: savedItineraryHeroTag(itinerary.id),
                    child: DestinationImageView(
                      destinationId: itinerary.id,
                      imageUrl: itinerary.coverImageUrl,
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
                      itinerary.destination,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  Text(
                    'Trip Overview',
                    key: const Key('saved_itinerary_detail_overview'),
                    style: TextStyle(
                      color: titleColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _MetaChip(
                          title: 'People',
                          value: itinerary.companion,
                          titleColor: titleColor,
                          cardColor: pageColor,
                        ),
                        _MetaChip(
                          title: 'Budget',
                          value: itinerary.budgetLabel,
                          titleColor: titleColor,
                          cardColor: pageColor,
                        ),
                        _MetaChip(
                          title: 'Dates',
                          value: itinerary.dateRangeLabel,
                          titleColor: titleColor,
                          cardColor: pageColor,
                        ),
                        _MetaChip(
                          title: 'Interests',
                          value: itinerary.interestsLabel,
                          titleColor: titleColor,
                          cardColor: pageColor,
                          wide: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Day by Day Plan',
                    key: const Key('saved_itinerary_detail_days'),
                    style: TextStyle(
                      color: titleColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...itinerary.dayPlans.map((dayPlan) {
                    return ResultDaySection(
                      dayPlan: dayPlan,
                      formattedDate: _formatDayDate(dayPlan.date),
                      showImageSkeleton: false,
                      showEditIcon: false,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.cardColor,
    this.wide = false,
  });

  final String title;
  final String value;
  final Color titleColor;
  final Color cardColor;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: wide ? 220 : 150),
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
