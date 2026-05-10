import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/home/models/home_destination.dart';
import 'package:smarttrip_ai/modules/home/widgets/destination_image_view.dart';

class HomeDestinationCard extends StatelessWidget {
  const HomeDestinationCard({
    super.key,
    required this.destination,
    required this.imageUrl,
    this.imageBytesBase64,
    required this.showLoading,
    required this.onTap,
    required this.heroTag,
  });

  final HomeDestination destination;
  final String? imageUrl;
  final String? imageBytesBase64;
  final bool showLoading;
  final VoidCallback onTap;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Hero(
                tag: heroTag,
                child: DestinationImageView(
                  destinationId: destination.id,
                  imageUrl: imageUrl,
                  imageBytesBase64: imageBytesBase64,
                  showLoading: showLoading,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x1A000000), Color(0x92000000)],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                top: 12,
                child: Text(
                  destination.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Times New Roman',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 0.95,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        'Reviews  ${destination.rating.toStringAsFixed(1)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Times New Roman',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
