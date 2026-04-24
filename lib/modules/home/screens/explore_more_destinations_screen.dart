import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/home/models/home_destination.dart';
import 'package:smarttrip_ai/modules/home/screens/destination_detail_screen.dart';
import 'package:smarttrip_ai/modules/home/services/home_destination_image_loader.dart';
import 'package:smarttrip_ai/modules/home/widgets/home_destination_card.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ExploreMoreDestinationsScreen extends StatefulWidget {
  const ExploreMoreDestinationsScreen({
    super.key,
    required this.destinations,
    this.initialImageUrls = const <String, String?>{},
    this.imageLoader,
  });

  final List<HomeDestination> destinations;
  final Map<String, String?> initialImageUrls;
  final HomeDestinationImageLoader? imageLoader;

  @override
  State<ExploreMoreDestinationsScreen> createState() =>
      _ExploreMoreDestinationsScreenState();
}

class _ExploreMoreDestinationsScreenState
    extends State<ExploreMoreDestinationsScreen> {
  late final HomeDestinationImageLoader _imageLoader;
  late final bool _ownsImageLoader;

  final Map<String, String?> _imageUrls = <String, String?>{};
  final Set<String> _loadingDestinationIds = <String>{};

  @override
  void initState() {
    super.initState();
    _ownsImageLoader = widget.imageLoader == null;
    _imageLoader = widget.imageLoader ?? PexelsHomeDestinationImageLoader();

    _imageUrls.addAll(widget.initialImageUrls);
    _loadMissingImages();
  }

  @override
  void dispose() {
    if (_ownsImageLoader) {
      _imageLoader.dispose();
    }
    super.dispose();
  }

  void _loadMissingImages() {
    for (final HomeDestination destination in widget.destinations) {
      if (_imageUrls.containsKey(destination.id)) {
        continue;
      }
      unawaited(_loadDestinationImage(destination));
    }
  }

  Future<void> _loadDestinationImage(HomeDestination destination) async {
    if (_loadingDestinationIds.contains(destination.id)) {
      return;
    }

    if (mounted) {
      setState(() => _loadingDestinationIds.add(destination.id));
    }

    final String? imageUrl = await _imageLoader.fetchImageUrl(destination);
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingDestinationIds.remove(destination.id);
      _imageUrls[destination.id] = imageUrl;
    });
  }

  void _openDestinationDetail(HomeDestination destination) {
    Navigator.of(context).push(
      buildDestinationDetailRoute(
        destination: destination,
        imageUrl: _imageUrls[destination.id],
      ),
    );
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
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: widget.destinations.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (BuildContext context, int index) {
          final HomeDestination destination = widget.destinations[index];
          return HomeDestinationCard(
            key: Key('explore_destination_card_${destination.id}'),
            destination: destination,
            imageUrl: _imageUrls[destination.id],
            showLoading: _loadingDestinationIds.contains(destination.id),
            heroTag: homeDestinationHeroTag(destination.id),
            onTap: () => _openDestinationDetail(destination),
          );
        },
      ),
    );
  }
}
