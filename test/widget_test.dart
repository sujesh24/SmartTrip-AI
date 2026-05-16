import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttrip_ai/modules/feedback/models/feedback_entry.dart';
import 'package:smarttrip_ai/modules/feedback/models/user_notification.dart';
import 'package:smarttrip_ai/modules/feedback/screens/notifications_screen.dart';
import 'package:smarttrip_ai/modules/feedback/services/feedback_service.dart';
import 'package:smarttrip_ai/modules/feedback/services/user_notification_service.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/settings/screens/manage_account_screen.dart';
import 'package:smarttrip_ai/modules/settings/screens/settings_screen.dart';
import 'package:smarttrip_ai/modules/settings/services/settings_preferences_service.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';
import 'package:smarttrip_ai/modules/trending_places/services/trending_places_service.dart';
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
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
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
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
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
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anna Wang'), findsOneWidget);
  });

  testWidgets('home renders destination cards from dynamic data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
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

  testWidgets('home notification badge uses merged unread count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
          notificationService: FakeUserNotificationService(unreadCount: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_notifications_nav')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('notifications screen marks unread notifications read', (
    WidgetTester tester,
  ) async {
    final FakeUserNotificationService notificationService =
        FakeUserNotificationService(
          notifications: <UserNotificationEntry>[
            UserNotificationEntry(
              id: 'feedback:one',
              type: UserNotificationType.feedbackReply,
              title: 'Admin replied',
              message: 'Thanks for the feedback.',
              createdAt: DateTime(2026, 5, 14),
              isRead: false,
              feedbackId: 'one',
            ),
            UserNotificationEntry(
              id: 'announcement:two',
              type: UserNotificationType.announcement,
              title: 'Travel update',
              message: 'New destinations are live.',
              createdAt: DateTime(2026, 5, 14),
              isRead: false,
              announcementId: 'two',
            ),
          ],
        );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          authService: FakeAuthService(),
          notificationService: notificationService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Admin replied'), findsOneWidget);
    expect(find.text('Travel update'), findsOneWidget);
    expect(notificationService.markedNotificationIds, <String>[
      'feedback:one',
      'announcement:two',
    ]);
  });

  testWidgets('explore more button opens full destinations page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: FakeAuthService(),
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder exploreButton = find.byKey(
      const Key('home_explore_more_button'),
    );
    await tester.ensureVisible(exploreButton);
    await tester.tap(exploreButton);
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
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder tokyoCard = find.byKey(
      const Key('home_destination_card_tokyo'),
    );
    await tester.ensureVisible(tokyoCard);
    await tester.tap(tokyoCard);
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
            placesService: FakeTrendingPlacesService(),
            feedbackService: FakeFeedbackService(),
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
          placesService: FakeTrendingPlacesService(),
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder exploreButton = find.byKey(
      const Key('home_explore_more_button'),
    );
    await tester.ensureVisible(exploreButton);
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    final Finder tokyoCard = find.byKey(
      const Key('explore_destination_card_tokyo'),
    );
    await tester.tap(tokyoCard);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('destination_detail_title')), findsOneWidget);
    expect(find.textContaining('Tokyo'), findsWidgets);
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
    final Finder deleteButton = find.byKey(
      const Key('manage_delete_account_button'),
    );
    final Finder accountScrollView = find.byType(Scrollable).first;

    await tester.pumpWidget(
      MaterialApp(home: ManageAccountScreen(authService: authService)),
    );

    await tester.scrollUntilVisible(
      deleteButton,
      80,
      scrollable: accountScrollView,
    );
    await tester.tap(deleteButton);
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
    final Finder deleteButton = find.byKey(
      const Key('manage_delete_account_button'),
    );
    final Finder accountScrollView = find.byType(Scrollable).first;

    await tester.pumpWidget(
      MaterialApp(home: ManageAccountScreen(authService: authService)),
    );

    await tester.scrollUntilVisible(
      deleteButton,
      80,
      scrollable: accountScrollView,
    );
    await tester.tap(deleteButton);
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
    final Finder deleteButton = find.byKey(
      const Key('manage_delete_account_button'),
    );
    final Finder accountScrollView = find.byType(Scrollable).first;

    await tester.pumpWidget(
      MaterialApp(home: ManageAccountScreen(authService: authService)),
    );

    await tester.scrollUntilVisible(
      deleteButton,
      80,
      scrollable: accountScrollView,
    );
    await tester.tap(deleteButton);
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
    expect(find.text('Login'), findsWidgets);
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
  String? get currentUserId => email == null ? null : 'test-user-id';

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

  @override
  Future<void> updateUserProfile({String? name, String? avatarPath}) async {
    // Fake implementation does nothing.
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

class FakeTrendingPlacesService implements TrendingPlacesServiceBase {
  FakeTrendingPlacesService({this.places = _testTrendingPlaces});

  final List<TrendingPlace> places;

  @override
  Stream<List<TrendingPlace>> watchTrendingPlaces() {
    return Stream<List<TrendingPlace>>.value(places);
  }

  @override
  Future<void> addTrendingPlace(TrendingPlace place) async {}

  @override
  Future<void> updateTrendingPlace(TrendingPlace place) async {}

  @override
  Future<void> deleteTrendingPlace(String placeId) async {}

  @override
  Future<int> seedDefaultTrendingPlaces() async {
    return 0;
  }
}

class FakeFeedbackService implements FeedbackServiceBase {
  const FakeFeedbackService({this.unreadCount = 0});

  final int unreadCount;

  @override
  Stream<List<FeedbackEntry>> watchAllFeedback() {
    return const Stream<List<FeedbackEntry>>.empty();
  }

  @override
  Stream<List<FeedbackEntry>> watchRepliedFeedbackForUser(String userId) {
    return const Stream<List<FeedbackEntry>>.empty();
  }

  @override
  Stream<int> watchUnreadReplyCount(String userId) {
    return Stream<int>.value(unreadCount);
  }

  @override
  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String message,
    required int rating,
  }) async {}

  @override
  Future<void> replyToFeedback({
    required String feedbackId,
    required String reply,
  }) async {}

  @override
  Future<void> markFeedbackRead(String feedbackId) async {}

  @override
  Future<void> deleteFeedback(String feedbackId) async {}
}

class FakeUserNotificationService implements UserNotificationServiceBase {
  FakeUserNotificationService({
    this.unreadCount = 0,
    this.notifications = const <UserNotificationEntry>[],
  });

  final int unreadCount;
  final List<UserNotificationEntry> notifications;
  final List<String> markedNotificationIds = <String>[];

  @override
  Future<void> markNotificationsRead({
    required String userId,
    required Iterable<UserNotificationEntry> notifications,
  }) async {
    markedNotificationIds.addAll(
      notifications.map((UserNotificationEntry notification) {
        return notification.id;
      }),
    );
  }

  @override
  Stream<List<UserNotificationEntry>> watchNotifications(String userId) {
    return Stream<List<UserNotificationEntry>>.value(notifications);
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return Stream<int>.value(unreadCount);
  }
}

const List<TrendingPlace> _testTrendingPlaces = <TrendingPlace>[
  TrendingPlace(
    id: 'tokyo',
    name: 'Tokyo',
    country: 'Japan',
    description: 'Tokyo is a vibrant destination for travelers.',
    imageUrl: '',
    bestTime: 'March - May',
    budget: 'High',
    rating: 4.8,
    category: 'City',
    createdAt: null,
    updatedAt: null,
  ),
  TrendingPlace(
    id: 'london',
    name: 'London',
    country: 'United Kingdom',
    description: 'London blends heritage and modern travel.',
    imageUrl: '',
    bestTime: 'March - May',
    budget: 'High',
    rating: 4.7,
    category: 'Heritage',
    createdAt: null,
    updatedAt: null,
  ),
  TrendingPlace(
    id: 'paris',
    name: 'Paris',
    country: 'France',
    description: 'Paris is loved for art, food, and landmarks.',
    imageUrl: '',
    bestTime: 'April - June',
    budget: 'High',
    rating: 4.8,
    category: 'Romantic',
    createdAt: null,
    updatedAt: null,
  ),
  TrendingPlace(
    id: 'dubai',
    name: 'Dubai',
    country: 'United Arab Emirates',
    description: 'Dubai is known for luxury and architecture.',
    imageUrl: '',
    bestTime: 'November - March',
    budget: 'High',
    rating: 4.6,
    category: 'Luxury',
    createdAt: null,
    updatedAt: null,
  ),
  TrendingPlace(
    id: 'singapore',
    name: 'Singapore',
    country: 'Singapore',
    description: 'Singapore is clean, green, and family friendly.',
    imageUrl: '',
    bestTime: 'February - April',
    budget: 'Medium',
    rating: 4.7,
    category: 'Family',
    createdAt: null,
    updatedAt: null,
  ),
  TrendingPlace(
    id: 'kerala',
    name: 'Kerala',
    country: 'India',
    description: 'Kerala is famous for backwaters and nature.',
    imageUrl: '',
    bestTime: 'October - March',
    budget: 'Medium',
    rating: 4.6,
    category: 'Nature',
    createdAt: null,
    updatedAt: null,
  ),
];
