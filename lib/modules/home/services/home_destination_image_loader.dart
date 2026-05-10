import 'package:smarttrip_ai/modules/external_api/image_service.dart';
import 'package:smarttrip_ai/modules/home/models/home_destination.dart';

abstract class HomeDestinationImageLoader {
  Future<String?> fetchImageUrl(HomeDestination destination);
  Future<String?> downloadImageAsBase64(String imageUrl);
  void dispose();
}

class PexelsHomeDestinationImageLoader implements HomeDestinationImageLoader {
  PexelsHomeDestinationImageLoader({ImageService? imageService})
    : _imageService = imageService ?? ImageService();

  final ImageService _imageService;

  @override
  Future<String?> fetchImageUrl(HomeDestination destination) {
    return _imageService.fetchPlaceImageUrl(
      placeName: destination.name,
      destination: destination.pexelsQuery,
    );
  }

  @override
  Future<String?> downloadImageAsBase64(String imageUrl) {
    return _imageService.downloadImageAsBase64(imageUrl);
  }

  @override
  void dispose() {
    _imageService.dispose();
  }
}
