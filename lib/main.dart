import 'package:flutter/material.dart';
import 'package:smarttrip_ai/presentation/screen/itinerary_one.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTrip AI',
      home: const ItineraryOne(),
      debugShowCheckedModeBanner: false,
    );
  }
}
