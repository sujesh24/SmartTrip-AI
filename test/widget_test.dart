import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttrip_ai/modules/home/models/home_destination.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/home/services/home_destination_image_loader.dart';
import 'package:smarttrip_ai/modules/settings/screens/manage_account_screen.dart';
import 'package:smarttrip_ai/modules/settings/screens/settings_screen.dart';
import 'package:smarttrip_ai/modules/settings/services/settings_preferences_service.dart';
import 'package:smarttrip_ai/modules/user/models/auth_result.dart';
import 'package:smarttrip_ai/modules/user/models/delete_account_result.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_theme_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppThemeController.instance.setDarkMode(false);
  });

  testWidgets('home opens settings from nav and has no top-right logout', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: authService,
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );

    expect(find.byIcon(Icons.logout), findsNothing);

    await tester.tap(find.byKey(const Key('home_settings_nav')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('home shows Guest when user email is missing', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService(email: null);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: authService,
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_username')), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
  });

  testWidgets('home formats username from email local-part', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService(
      email: 'anna.wang@example.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: authService,
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anna Wang'), findsOneWidget);
  });

  testWidgets('home renders six destination cards from fixed data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('home_destination_card_tokyo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_destination_card_london')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_destination_card_paris')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_destination_card_dubai')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_destination_card_singapore')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home_destination_card_kerala')),
      findsOneWidget,
    );
  });

  testWidgets('explore more button opens full destinations page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_explore_more_button')));
    await tester.pumpAndSettle();

    expect(find.text('Explore More'), findsOneWidget);
    expect(
      find.byKey(const Key('explore_destination_card_tokyo')),
      findsOneWidget,
    );
  });

  testWidgets('tapping home card opens detail with matching metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_destination_card_tokyo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('destination_detail_title')), findsOneWidget);
    expect(find.textContaining('Tokyo'), findsWidgets);
    expect(
      find.byKey(const Key('destination_detail_best_time')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('destination_detail_budget')), findsOneWidget);
    expect(find.byKey(const Key('destination_detail_rating')), findsOneWidget);
  });

  testWidgets(
    'fallback placeholder asset is used when image URL is unavailable',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: FakeAuthService(),
            imageLoader: FakeHomeDestinationImageLoader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('destination_asset_fallback_tokyo')),
        findsOneWidget,
      );
    },
  );

  testWidgets('detail opens from Explore More destination tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          imageLoader: FakeHomeDestinationImageLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_explore_more_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('explore_destination_card_paris')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('destination_detail_title')), findsOneWidget);
    expect(find.textContaining('Paris'), findsWidgets);
  });

  testWidgets('notifications toggle persists across rebuild', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService();

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(authService: authService)),
    );
    await tester.pumpAndSettle();

    final Finder toggleFinder = find.byKey(
      const Key('settings_notifications_toggle'),
    );

    Switch toggle = tester.widget<Switch>(toggleFinder);
    expect(toggle.value, isTrue);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    toggle = tester.widget<Switch>(toggleFinder);
    expect(toggle.value, isFalse);

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(authService: authService)),
    );
    await tester.pumpAndSettle();

    toggle = tester.widget<Switch>(toggleFinder);
    expect(toggle.value, isFalse);
  });

  testWidgets('help and support launches support mailto URI', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService();
    Uri? launchedUri;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          authService: authService,
          preferencesService: FakeSettingsPreferencesService(),
          launchSupportUri: (Uri uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_help_support_tile')));
    await tester.pumpAndSettle();

    expect(launchedUri, isNotNull);
    expect(launchedUri?.scheme, 'mailto');
    expect(launchedUri?.path, 'support@planmytrip.ai');
  });

  testWidgets('delete confirmation stays disabled until DELETE is typed', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService();

    await tester.pumpWidget(
      MaterialApp(home: ManageAccountScreen(authService: authService)),
    );

    await tester.tap(find.byKey(const Key('manage_delete_account_button')));
    await tester.pumpAndSettle();

    ElevatedButton confirmButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('delete_account_confirm_button')),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delete_account_confirmation_input')),
      'DELETE',
    );
    await tester.pumpAndSettle();

    confirmButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('delete_account_confirm_button')),
    );
    expect(confirmButton.onPressed, isNotNull);
  });

  testWidgets('delete account success routes to auth entry screen', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService(
      deleteResult: DeleteAccountResult.success(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ManageAccountScreen(authService: authService)),
    );

    await tester.tap(find.byKey(const Key('manage_delete_account_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('delete_account_confirmation_input')),
      'DELETE',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
    await tester.pumpAndSettle();

    expect(authService.deleteCalled, isTrue);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('requires recent login path signs out and routes to login', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService(
      deleteResult: DeleteAccountResult.requiresRecentLogin(
        message: 'Please login again.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ManageAccountScreen(authService: authService)),
    );

    await tester.tap(find.byKey(const Key('manage_delete_account_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('delete_account_confirmation_input')),
      'DELETE',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Re-login Required'), findsOneWidget);

    await tester.tap(find.text('Re-login'));
    await tester.pumpAndSettle();

    expect(authService.signOutCalled, isTrue);
    expect(find.text('Login'), findsOneWidget);
  });
}

class FakeAuthService implements AuthServiceBase {
  FakeAuthService({
    this.email = 'traveler@example.com',
    this.providerLabel = 'Email',
    DeleteAccountResult? deleteResult,
  }) : _deleteResult = deleteResult ?? DeleteAccountResult.success();

  final String? email;
  final String providerLabel;
  final DeleteAccountResult _deleteResult;

  bool signOutCalled = false;
  bool deleteCalled = false;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  bool get isSignedIn => email != null;

  @override
  String? get currentUserEmail => email;

  @override
  String get currentUserProviderLabel => providerLabel;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthResult.success;
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return AuthResult.success;
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthResult.success;
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    return AuthResult.success;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<DeleteAccountResult> deleteCurrentUser() async {
    deleteCalled = true;
    return _deleteResult;
  }
}

class FakeSettingsPreferencesService implements SettingsPreferencesService {
  FakeSettingsPreferencesService({this.notificationsEnabled = true});

  bool notificationsEnabled;

  @override
  Future<bool> loadNotificationsEnabled() async {
    return notificationsEnabled;
  }

  @override
  Future<void> saveNotificationsEnabled(bool isEnabled) async {
    notificationsEnabled = isEnabled;
  }
}

class FakeHomeDestinationImageLoader implements HomeDestinationImageLoader {
  FakeHomeDestinationImageLoader({
    this.imageUrlsById = const <String, String?>{},
    this.imageBytesByUrl = const <String, String?>{},
  });

  final Map<String, String?> imageUrlsById;
  final Map<String, String?> imageBytesByUrl;

  @override
  Future<String?> fetchImageUrl(HomeDestination destination) async {
    return imageUrlsById[destination.id];
  }

  @override
  Future<String?> downloadImageAsBase64(String imageUrl) async {
    return imageBytesByUrl[imageUrl];
  }

  @override
  void dispose() {}
}
