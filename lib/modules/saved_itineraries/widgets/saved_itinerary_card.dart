import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/home/widgets/destination_image_view.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/models/saved_itinerary.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class SavedItineraryCard extends StatelessWidget {
  const SavedItineraryCard({
    super.key,
    required this.itinerary,
    required this.onTap,
  });

  final SavedItinerary itinerary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color titleColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;

    return InkWell(
      key: Key('saved_itinerary_card_${itinerary.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 122,
              height: 132,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: Hero(
                  tag: savedItineraryHeroTag(itinerary.id),
                  child: DestinationImageView(
                    destinationId: itinerary.id,
                    imageUrl: itinerary.coverImageUrl,
                    imageBytesBase64: itinerary.coverImageBase64,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      itinerary.destination,
                      key: Key('saved_itinerary_destination_${itinerary.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontFamily: 'Times New Roman',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(
                      label: 'Budget',
                      value: itinerary.budgetLabel,
                      textColor: titleColor,
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      label: 'People',
                      value: itinerary.companion,
                      textColor: titleColor,
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      label: 'Dates',
                      value: itinerary.dateRangeLabel,
                      textColor: titleColor,
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.68),
              fontFamily: 'Times New Roman',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: textColor,
              fontFamily: 'Times New Roman',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
