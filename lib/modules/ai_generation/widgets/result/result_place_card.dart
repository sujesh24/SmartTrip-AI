import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/place_plan.dart';

class ResultPlaceCard extends StatelessWidget {
  const ResultPlaceCard({super.key, required this.place});

  final PlacePlan place;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC6CBD2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69A8F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          place.rating,
                          style: const TextStyle(
                            color: Color(0xFF10223F),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A223D),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.access_time_filled,
                        size: 14,
                        color: Color(0xFF1A223D),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          place.timing,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A223D),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.confirmation_number,
                        size: 14,
                        color: Color(0xFF1A223D),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          place.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A223D),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildPlaceImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceImage() {
    final String? imageUrl = place.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 85,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAssetFallback(),
      );
    }
    return _buildAssetFallback();
  }

  Widget _buildAssetFallback() {
    return Image.asset(
      AppAssets.resultPlaceholder,
      width: 85,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object _, StackTrace? __) {
        return Container(
          width: 85,
          color: const Color(0xFFD2D6DD),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF7D8696),
            size: 20,
          ),
        );
      },
    );
  }
}
