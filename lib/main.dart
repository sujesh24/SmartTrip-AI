import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/result_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ItineraryRequest devRequest = ItineraryRequest(
      destination: 'Tokyo',
      startDate: '2026-04-19',
      endDate: '2026-04-22',
      companion: 'Solo',
      interests: <String>['Landmarks', 'Food'],
      budget: '5000',
    );

    return MaterialApp(
      title: 'SmartTrip AI',
      home: ResultScreen(
        request: devRequest,
        generatedText: 'Dev mode placeholder',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
