import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/day_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/place_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/viewmodels/result_view_model.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_day_chip.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_day_section.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_header.dart';
import 'package:smarttrip_ai/modules/external_api/image_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.request,
    required this.generatedText,
  });

  final ItineraryRequest request;
  final String generatedText;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const Color _accentNavy = Color(0xFF0C1A4B);
  static const Color _mutedChip = Color(0xFFB9BDC3);

  late final ResultViewModel _viewModel;
  final ImageService _imageService = ImageService();
  late List<DayPlan> _dayPlans;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ResultViewModel(
      request: widget.request,
      generatedText: widget.generatedText,
    );
    _dayPlans = _viewModel.dayPlans;
    _loadPlaceImages();
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
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: Colors.white),
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
                  const SizedBox(height: 18),
                  ...visiblePlans.map((DayPlan dayPlan) {
                    return ResultDaySection(
                      dayPlan: dayPlan,
                      formattedDate: _viewModel.formatDayDate(dayPlan.date),
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
}
