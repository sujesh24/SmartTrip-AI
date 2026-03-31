import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/firebase_options.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanMyTrip AI',
      home: StreamBuilder(
        stream: _authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data != null) {
            return const HomeScreen();
          }

          return const SignupScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
