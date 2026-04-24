import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/models/saved_itinerary.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/screens/saved_itinerary_detail_screen.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/services/saved_itinerary_store.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/widgets/saved_itinerary_card.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({
    super.key,
    this.store,
    this.navigateHomeOnExit = false,
    this.successMessage,
  });

  final SavedItineraryStore? store;
  final bool navigateHomeOnExit;
  final String? successMessage;

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  late final SavedItineraryStore _store;
  List<SavedItinerary> _itineraries = <SavedItinerary>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? SharedPrefsSavedItineraryStore();
    _loadSavedTrips();
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        AppSnackBar.showSuccess(context, widget.successMessage!);
      });
    }
  }

  Future<void> _loadSavedTrips() async {
    try {
      final List<SavedItinerary> itineraries = await _store
          .loadSavedItineraries();
      if (!mounted) {
        return;
      }
      setState(() {
        _itineraries = itineraries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load your saved trips right now.';
        _isLoading = false;
      });
    }
  }

  void _openDetail(SavedItinerary itinerary) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedItineraryDetailScreen(itinerary: itinerary),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
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

    return WillPopScope(
      onWillPop: () async {
        if (widget.navigateHomeOnExit) {
          _goHome();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: pageColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: !widget.navigateHomeOnExit,
          leading: widget.navigateHomeOnExit
              ? IconButton(
                  onPressed: _goHome,
                  icon: Icon(Icons.arrow_back, color: titleColor),
                )
              : null,
          iconTheme: IconThemeData(color: titleColor),
          title: Text(
            'My Items',
            key: const Key('saved_trips_title'),
            style: TextStyle(
              color: titleColor,
              fontFamily: 'Times New Roman',
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: _buildBody(titleColor),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Color titleColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontFamily: 'Times New Roman',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (_itineraries.isEmpty) {
      return Center(
        child: Container(
          key: const Key('saved_trips_empty_state'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.menu_book_outlined, size: 42, color: titleColor),
              const SizedBox(height: 14),
              Text(
                'No saved itineraries yet',
                style: TextStyle(
                  color: titleColor,
                  fontFamily: 'Times New Roman',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Save a generated trip from the result page and it will appear here.',
                style: TextStyle(
                  color: titleColor.withValues(alpha: 0.75),
                  fontFamily: 'Times New Roman',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('saved_trips_list'),
      itemCount: _itineraries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (BuildContext context, int index) {
        final SavedItinerary itinerary = _itineraries[index];
        return SavedItineraryCard(
          itinerary: itinerary,
          onTap: () => _openDetail(itinerary),
        );
      },
    );
  }
}
