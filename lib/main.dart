import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/firebase_options.dart';
import 'package:smarttrip_ai/modules/admin/common/admin_constants.dart';
import 'package:smarttrip_ai/modules/admin/screens/admin_dashboard_screen.dart';
import 'package:smarttrip_ai/modules/admin/screens/admin_verification_screen.dart';
import 'package:smarttrip_ai/modules/admin/services/admin_session_service.dart';
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
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
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
              : _AuthGate(authService: currentAuthService),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.authService});

  final AuthServiceBase authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      initialData: authService.isSignedIn
          ? FirebaseAuth.instance.currentUser
          : null,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        final User? user = snapshot.data;

        if (user == null) {
          return SignupScreen(authService: authService);
        }

        final String? email = user.email ?? authService.currentUserEmail;
        if (!AdminCredentials.isAdminEmail(email)) {
          return HomeScreen(authService: authService);
        }

        return _AdminSessionGate(authService: authService, email: email);
      },
    );
  }
}

class _AdminSessionGate extends StatelessWidget {
  const _AdminSessionGate({required this.authService, required this.email});

  final AuthServiceBase authService;
  final String? email;

  static final AdminSessionService _adminSessionService = AdminSessionService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminSessionService.hasVerifiedAdminSession(email),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return AdminDashboardScreen(
            authService: authService,
            sessionService: _adminSessionService,
          );
        }

        return AdminVerificationScreen(
          authService: authService,
          sessionService: _adminSessionService,
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
