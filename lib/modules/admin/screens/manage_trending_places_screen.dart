import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/admin/screens/add_edit_place_screen.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';
import 'package:smarttrip_ai/modules/trending_places/services/trending_places_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ManageTrendingPlacesScreen extends StatefulWidget {
  const ManageTrendingPlacesScreen({super.key, this.placesService});

  final TrendingPlacesServiceBase? placesService;

  @override
  State<ManageTrendingPlacesScreen> createState() =>
      _ManageTrendingPlacesScreenState();
}

class _ManageTrendingPlacesScreenState
    extends State<ManageTrendingPlacesScreen> {
  late final TrendingPlacesServiceBase _placesService;
  final Set<String> _deletingPlaceIds = <String>{};

  @override
  void initState() {
    super.initState();
    _placesService = widget.placesService ?? TrendingPlacesService();
  }

  Future<void> _openAddPlace() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEditPlaceScreen(placesService: _placesService),
      ),
    );
  }

  Future<void> _openEditPlace(TrendingPlace place) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AddEditPlaceScreen(place: place, placesService: _placesService),
      ),
    );
  }

  Future<void> _deletePlace(TrendingPlace place) async {
    if (_deletingPlaceIds.contains(place.id)) {
      return;
    }

    final bool didConfirm = await _showDeleteConfirmationDialog(place);
    if (!didConfirm || !mounted) {
      return;
    }

    setState(() => _deletingPlaceIds.add(place.id));
    try {
      await _placesService.deleteTrendingPlace(place.id);
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, 'Place deleted.');
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to delete place. Please check permissions.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to delete place right now.');
    } finally {
      if (mounted) {
        setState(() => _deletingPlaceIds.remove(place.id));
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(TrendingPlace place) async {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBackground = isDarkMode
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.borderGreen;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          title: Text(
            'Delete Place',
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          content: Text(
            'Remove ${place.name.isEmpty ? 'this place' : place.name} from trending places?',
            style: TextStyle(
              color: primaryTextColor.withValues(alpha: 0.75),
              fontFamily: 'Times New Roman',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: primaryTextColor,
                  fontFamily: 'Times New Roman',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pageColor = isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
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
        title: Text(
          'Trending Places',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add place',
        onPressed: _openAddPlace,
        backgroundColor: primaryTextColor,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<TrendingPlace>>(
          stream: _placesService.watchTrendingPlaces(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<TrendingPlace>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return _AdminStateCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Unable to load places',
                    message: 'Check Firestore rules and try again.',
                    primaryTextColor: primaryTextColor,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryTextColor),
                  );
                }

                final List<TrendingPlace> places =
                    snapshot.data ?? <TrendingPlace>[];

                if (places.isEmpty) {
                  return _AdminStateCard(
                    icon: Icons.add_location_alt_outlined,
                    title: 'No trending places',
                    message: 'Tap the add button to publish your first place.',
                    primaryTextColor: primaryTextColor,
                    backgroundColor: cardColor,
                    borderColor: borderColor,
                  );
                }

                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final int crossAxisCount = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 620
                        ? 3
                        : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
                      itemCount: places.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: constraints.maxWidth < 380
                            ? 0.83
                            : 0.9,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final TrendingPlace place = places[index];
                        return _PlaceGridCard(
                          place: place,
                          isDeleting: _deletingPlaceIds.contains(place.id),
                          primaryTextColor: primaryTextColor,
                          backgroundColor: cardColor,
                          borderColor: borderColor,
                          onEdit: () => _openEditPlace(place),
                          onDelete: () => _deletePlace(place),
                        );
                      },
                    );
                  },
                );
              },
        ),
      ),
    );
  }
}

class _PlaceGridCard extends StatelessWidget {
  const _PlaceGridCard({
    required this.place,
    required this.isDeleting,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onEdit,
    required this.onDelete,
  });

  final TrendingPlace place;
  final bool isDeleting;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (place.imageUrl.isNotEmpty)
                    Image.network(
                      place.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ImageFallback(primaryTextColor: primaryTextColor),
                    )
                  else
                    _ImageFallback(primaryTextColor: primaryTextColor),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<_PlaceAction>(
                        tooltip: 'Place actions',
                        enabled: !isDeleting,
                        color: backgroundColor,
                        icon: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white,
                              ),
                        onSelected: (_PlaceAction action) {
                          switch (action) {
                            case _PlaceAction.edit:
                              onEdit();
                              break;
                            case _PlaceAction.delete:
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<_PlaceAction>>[
                            PopupMenuItem<_PlaceAction>(
                              value: _PlaceAction.edit,
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.edit_outlined,
                                    color: primaryTextColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontFamily: 'Times New Roman',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<_PlaceAction>(
                              value: _PlaceAction.delete,
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontFamily: 'Times New Roman',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    place.name.isEmpty ? 'Untitled Place' : place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.country.isEmpty ? 'No location' : place.country,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.78),
                      fontFamily: 'Times New Roman',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.description.isEmpty
                        ? 'No description'
                        : place.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.68),
                      fontFamily: 'Times New Roman',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.78),
                          fontFamily: 'Times New Roman',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (place.category.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: primaryTextColor.withValues(alpha: 0.62),
                              fontFamily: 'Times New Roman',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.primaryTextColor});

  final Color primaryTextColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: primaryTextColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.image_outlined, color: primaryTextColor, size: 34),
      ),
    );
  }
}

class _AdminStateCard extends StatelessWidget {
  const _AdminStateCard({
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

enum _PlaceAction { edit, delete }
