import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/ai_service.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/result_screen.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.request});

  final ItineraryRequest request;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const double _previewWidth = 150;
  static const double _previewSpacing = 10;
  static const double _previewHeight = 190;

  final AiService _aiService = AiService();
  late final AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _generateAndNavigate();
  }

  @override
  void dispose() {
    _aiService.dispose();
    _marqueeController.dispose();
    super.dispose();
  }

  Future<void> _generateAndNavigate() async {
    final String prompt = _buildPrompt(widget.request);
    String generatedText;

    try {
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _aiService.generateText(prompt),
            Future<void>.delayed(const Duration(seconds: 3)),
          ]);
      generatedText = results[0] as String;
    } catch (error) {
      generatedText =
          'Unable to generate trip plan right now.\n\nError: $error';
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResultScreen(request: widget.request, generatedText: generatedText),
      ),
    );
  }

  String _buildPrompt(ItineraryRequest request) {
    final DateTime? start = DateTime.tryParse(request.startDate);
    final DateTime? end = DateTime.tryParse(request.endDate);
    int totalDays = 1;
    if (start != null && end != null && !end.isBefore(start)) {
      totalDays = end.difference(start).inDays + 1;
    }

    return '''
Create a travel itinerary and return ONLY valid JSON (no markdown, no extra text).

Trip details:
- Destination: ${request.destination}
- Start date: ${request.startDate}
- End date: ${request.endDate}
- Companion: ${request.companion}
- Interests: ${request.interests.join(', ')}
- Budget (INR): \u20B9 ${request.budget}

Output schema:
{
  "days": [
    {
      "day": 1,
      "date": "YYYY-MM-DD",
      "places": [
        {
          "name": "Place Name",
          "rating": "4.5",
          "timing": "10:00 - 12:00",
          "price": "\u20B9 2000 per person",
          "travel_to_next": "15 mins"
        }
      ]
    }
  ]
}

Rules:
- Include exactly $totalDays days.
- Each day must have 2 to 4 places.
- rating must be 1 decimal string (example: "4.6").
- Keep timing and price short and practical.
- All prices must be in INR and use \u20B9 symbol.
- For each place (except the last in a day), include travel_to_next like "12 mins".
- All places must be in/near ${request.destination}.
- JSON must be parseable by jsonDecode.
- Do not return markdown or code fences.
''';
  }

  @override
  Widget build(BuildContext context) {
    return ItineraryPageLayout(
      body: ListView(
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 5),
          const SizedBox(height: 30),
          const ItinerarySectionTitle(text: 'Working In Progress'),
          const SizedBox(height: 8),
          Text(
            'Please wait a little bit while our AI\nassistance is working on your itinerary.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryGreen.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: _previewHeight,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int imageCount = AppAssets.loadingPreviewImages.length;
                  final double stripWidth =
                      (imageCount * _previewWidth) +
                      ((imageCount - 1) * _previewSpacing);

                  return AnimatedBuilder(
                    animation: _marqueeController,
                    builder: (BuildContext context, Widget? _) {
                      final double dx = -_marqueeController.value * stripWidth;

                      return Stack(
                        children: <Widget>[
                          Positioned(
                            left: dx,
                            top: 0,
                            width: stripWidth,
                            height: _previewHeight,
                            child: _buildImageStrip(),
                          ),
                          Positioned(
                            left: dx + stripWidth + _previewSpacing,
                            top: 0,
                            width: stripWidth,
                            height: _previewHeight,
                            child: _buildImageStrip(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildImageStrip() {
    final int imageCount = AppAssets.loadingPreviewImages.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(imageCount, (int index) {
        final String imagePath = AppAssets.loadingPreviewImages[index];
        return Padding(
          padding: EdgeInsets.only(
            right: index == imageCount - 1 ? 0 : _previewSpacing,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              imagePath,
              width: _previewWidth,
              height: _previewHeight,
              fit: BoxFit.cover,
            ),
          ),
        );
      }),
    );
  }
}
