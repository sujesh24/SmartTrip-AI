import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step1.dart';

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
