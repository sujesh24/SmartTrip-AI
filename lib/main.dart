import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/firebase_options.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_theme_controller.dart';
import 'package:smarttrip_ai/theme/app_theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());

  AppThemeController.instance.loadThemeMode().catchError((_) {
    // Keep startup resilient even if theme preference cannot be read.
  });
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<Object?> _initializationFuture = _initializeFirebase();

  Future<Object?> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
      return null;
    } catch (error) {
      return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object?>(
      future: _initializationFuture,
      builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MyApp(firebaseInitError: snapshot.data);
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.authService, this.firebaseInitError});

  final AuthServiceBase? authService;
  final Object? firebaseInitError;
  static final AuthServiceBase _defaultAuthService = AuthService();

  @override
  Widget build(BuildContext context) {
    final AuthServiceBase currentAuthService =
        authService ?? _defaultAuthService;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.instance.themeModeListenable,
      builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
        return MaterialApp(
          title: 'PlanMyTrip AI',
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          themeMode: themeMode,
          home: firebaseInitError != null
              ? const _StartupErrorScreen()
              : StreamBuilder<User?>(
                  stream: currentAuthService.authStateChanges(),
                  initialData: currentAuthService.isSignedIn
                      ? FirebaseAuth.instance.currentUser
                      : null,
                  builder:
                      (BuildContext context, AsyncSnapshot<User?> snapshot) {
                        if (snapshot.data != null) {
                          return HomeScreen(authService: currentAuthService);
                        }

                        return SignupScreen(authService: currentAuthService);
                      },
                ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Unable to initialize the app. Please restart and try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
