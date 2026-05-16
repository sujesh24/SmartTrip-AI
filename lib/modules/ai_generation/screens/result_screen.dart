import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/day_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/place_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/viewmodels/result_view_model.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_primary_button.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_day_chip.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_day_section.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_header.dart';
import 'package:smarttrip_ai/modules/external_api/image_service.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/models/saved_itinerary.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/screens/saved_trips_screen.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/services/saved_itinerary_store.dart';
import 'package:smarttrip_ai/modules/ai_generation/services/generated_places_service.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.request,
    required this.generatedText,
    this.savedItineraryStore,
    this.generatedPlacesService,
    this.authService,
  });

  final ItineraryRequest request;
  final String generatedText;
  final SavedItineraryStore? savedItineraryStore;
  final GeneratedPlacesServiceBase? generatedPlacesService;
  final AuthServiceBase? authService;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const Color _accentNavy = Color(0xFF0C1A4B);
  static const Color _mutedChip = Color(0xFFB9BDC3);

  late final ResultViewModel _viewModel;
  final ImageService _imageService = ImageService();
  late final GeneratedPlacesServiceBase _generatedPlacesService;
  late final AuthServiceBase _authService;
  late final SavedItineraryStore _savedItineraryStore;
  late List<DayPlan> _dayPlans;
  late final Future<void> _placeImagesFuture;
  bool _isLoadingPlaceImages = false;
  bool _isSavingItinerary = false;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ResultViewModel(
      request: widget.request,
      generatedText: widget.generatedText,
    );
    _savedItineraryStore =
        widget.savedItineraryStore ?? SharedPrefsSavedItineraryStore();
    _generatedPlacesService =
        widget.generatedPlacesService ?? GeneratedPlacesService();
    _authService = widget.authService ?? AuthService();
    _dayPlans = _viewModel.dayPlans;
    _placeImagesFuture = _loadPlaceImages();
    _recordGeneratedPlace();
  }

  @override
  void dispose() {
    _imageService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<DayPlan> visiblePlans = _selectedDay == 0
        ? _dayPlans
        : _dayPlans
              .where((DayPlan dayPlan) => dayPlan.dayNumber == _selectedDay)
              .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _closeToHome,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          ResultHeader(
            title: _viewModel.title,
            companion: _viewModel.companion,
            budgetLabel: _viewModel.budgetLabel,
            dateRangeLabel: _viewModel.dateRangeLabel,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDayTabs(),
                  const SizedBox(height: 14),
                  ItineraryPrimaryButton(
                    key: const Key('result_save_button'),
                    label: _isSavingItinerary
                        ? 'Saving...'
                        : _isLoadingPlaceImages
                        ? 'Preparing image...'
                        : 'Save to My Items',
                    onPressed: _isSavingItinerary ? null : _saveToMyItems,
                    isLoading: _isSavingItinerary || _isLoadingPlaceImages,
                    expand: true,
                  ),
                  const SizedBox(height: 18),
                  ...visiblePlans.map((DayPlan dayPlan) {
                    return ResultDaySection(
                      dayPlan: dayPlan,
                      formattedDate: _viewModel.formatDayDate(dayPlan.date),
                      showImageSkeleton: _isLoadingPlaceImages,
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

  Widget _buildDayTabs() {
    final List<Widget> chips = <Widget>[
      ResultDayChip(
        label: 'All',
        selected: _selectedDay == 0,
        onTap: () => setState(() => _selectedDay = 0),
        selectedColor: _accentNavy,
        unselectedColor: _mutedChip,
      ),
    ];

    for (final DayPlan dayPlan in _dayPlans) {
      chips.add(
        ResultDayChip(
          label: _viewModel.dayChipLabel(dayPlan),
          selected: _selectedDay == dayPlan.dayNumber,
          onTap: () => setState(() => _selectedDay = dayPlan.dayNumber),
          selectedColor: _accentNavy,
          unselectedColor: _mutedChip,
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) => chips[index],
      ),
    );
  }

  Future<void> _loadPlaceImages() async {
    final List<DayPlan> sourcePlans = _dayPlans;
    if (sourcePlans.isEmpty) {
      return;
    }

    final bool hasMissingImages = sourcePlans.any(
      (DayPlan dayPlan) => dayPlan.places.any(
        (PlacePlan place) => (place.imageUrl ?? '').trim().isEmpty,
      ),
    );
    if (!hasMissingImages) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingPlaceImages = true;
      });
    }

    try {
      final List<DayPlan> enrichedPlans = <DayPlan>[];
      for (final DayPlan dayPlan in sourcePlans) {
        final List<Future<PlacePlan>> placeFutures = dayPlan.places
            .map((PlacePlan place) => _enrichPlaceWithImage(place))
            .toList();
        final List<PlacePlan> enrichedPlaces = await Future.wait(placeFutures);
        enrichedPlans.add(dayPlan.copyWith(places: enrichedPlaces));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _dayPlans = enrichedPlans;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlaceImages = false;
        });
      }
    }
  }

  Future<void> _saveToMyItems() async {
    if (_isSavingItinerary) {
      return;
    }

    setState(() {
      _isSavingItinerary = true;
    });

    try {
      await _placeImagesFuture;
      if (!mounted) {
        return;
      }

      final String? coverImageUrl = _coverImageUrl;
      final String? coverImageBase64 = coverImageUrl == null
          ? null
          : await _imageService.downloadImageAsBase64(coverImageUrl);
      final SavedItinerary itinerary = SavedItinerary.fromRequest(
        request: widget.request,
        dayPlans: _dayPlans,
        coverImageUrl: coverImageUrl,
        coverImageBase64: coverImageBase64,
      );
      await _savedItineraryStore.saveItinerary(itinerary);
      await _recordGeneratedPlaceSave();

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => SavedTripsScreen(
            store: _savedItineraryStore,
            navigateHomeOnExit: true,
            successMessage: 'Trip saved to My Items.',
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        'Unable to save this itinerary right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingItinerary = false;
        });
      }
    }
  }

  Future<PlacePlan> _enrichPlaceWithImage(PlacePlan place) async {
    if (place.imageUrl != null && place.imageUrl!.trim().isNotEmpty) {
      return place;
    }

    final String? imageUrl = await _imageService.fetchPlaceImageUrl(
      placeName: place.name,
      destination: _viewModel.destination,
    );
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return place;
    }

    return place.copyWith(imageUrl: imageUrl);
  }

  String? get _coverImageUrl {
    for (final DayPlan dayPlan in _dayPlans) {
      for (final PlacePlan place in dayPlan.places) {
        final String? imageUrl = place.imageUrl?.trim();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
    }
    return null;
  }

  void _recordGeneratedPlace() {
    final String? userId = _authService.currentUserId;
    final String destination = _trackingDestination;
    if (userId == null || userId.isEmpty || destination.isEmpty) {
      return;
    }

    unawaited(
      _generatedPlacesService.recordPlaceGeneration(
        placeName: destination,
        userId: userId,
        userEmail: _authService.currentUserEmail,
      ),
    );
  }

  Future<void> _recordGeneratedPlaceSave() async {
    final String? userId = _authService.currentUserId;
    final String destination = _trackingDestination;
    if (userId == null || userId.isEmpty || destination.isEmpty) {
      return;
    }

    await _generatedPlacesService.recordPlaceSave(
      placeName: destination,
      userId: userId,
      userEmail: _authService.currentUserEmail,
    );
  }

  String get _trackingDestination {
    return widget.request.destination.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _closeToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
