import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';

class DestinationImageView extends StatelessWidget {
  const DestinationImageView({
    super.key,
    required this.destinationId,
    required this.imageUrl,
    this.showLoading = false,
    this.fit = BoxFit.cover,
  });

  final String destinationId;
  final String? imageUrl;
  final bool showLoading;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String? sanitizedUrl = imageUrl?.trim();
    if (sanitizedUrl != null && sanitizedUrl.isNotEmpty) {
      return Image.network(
        sanitizedUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }
              return _buildLoading();
            },
        errorBuilder: (_, __, ___) => _buildAssetFallback(),
      );
    }

    if (showLoading) {
      return _buildLoading();
    }

    return _buildAssetFallback();
  }

  Widget _buildLoading() {
    return Container(
      color: const Color(0xFFD9DDD6),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }

  Widget _buildAssetFallback() {
    return Image.asset(
      AppAssets.resultPlaceholder,
      key: Key('destination_asset_fallback_$destinationId'),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return Container(
          key: Key('destination_color_fallback_$destinationId'),
          color: const Color(0xFFD2D6DD),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF7D8696),
            size: 28,
          ),
        );
      },
    );
  }
}
