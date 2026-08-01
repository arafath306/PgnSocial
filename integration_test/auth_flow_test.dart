import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// App imports using package imports
import 'package:dak/main.dart';
import 'package:dak/models/thread_post.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/services/auth_service.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/community_service.dart';
import 'package:dak/services/notification_settings_provider.dart';
import 'package:dak/services/chat_settings_provider.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:dak/state/verification_controller.dart';
import 'package:dak/state/monetization_controller.dart';
import 'package:dak/state/music_playback_controller.dart';
import 'package:dak/screens/auth/onboarding_screen.dart';
import 'package:dak/screens/auth/auth_screen.dart';
import 'package:dak/screens/main_screen.dart';
import 'package:dak/core/error/failures.dart';
import 'package:dak/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:dak/features/feed/domain/usecases/create_thread_use_case.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';

// Mock class declarations
class MockAuthService extends ChangeNotifier implements AuthService {
  bool _signedIn = false;
  bool _loading = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isLoading => _loading;

  @override
  String? get errorMessage => null;

  @override
  bool get isUserSignedIn => _signedIn;

  @override
  sb.User? get currentUser => _signedIn
      ? sb.User(
          id: 'user123',
          email: 'test@example.com',
          createdAt: DateTime.now().toIso8601String(),
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          emailConfirmedAt: DateTime.now().toIso8601String(),
        )
      : null;

  @override
  bool get requires2FA => false;

  @override
  bool get isEmailVerified => true;

  @override
  Future<LoginResult> handleLogin(String emailOrUsername, String password) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _loading = false;
    _signedIn = true;
    notifyListeners();
    return LoginResult.success;
  }

  @override
  Future<bool> handleSignup({
    required String birthdate,
    String? city,
    String? division,
    required String email,
    required String fullName,
    required String gender,
    required String password,
    required String phone,
    String? username,
    String? village,
    String? zip,
  }) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _loading = false;
    _signedIn = true;
    notifyListeners();
    return true;
  }

  @override
  Future<void> handleSignout() async {
    _signedIn = false;
    notifyListeners();
  }
}

class MockDatabaseService extends DatabaseService {
  @override
  Profile? get myProfile => Profile(id: 'user123', username: 'john_doe', fullName: 'John Doe');

  @override
  String get currentUid => 'user123';

  @override
  List<ThreadPost> get feed => [];

  @override
  List<ThreadPost> get personalizedFeed => [];

  @override
  bool get aiFeedHasMore => false;

  @override
  List<ThreadPost> get myThreads => [];

  @override
  bool isBlocked(String userId) => false;

  @override
  bool isBlockedByMe(String userId) => false;

  @override
  bool isSaved(String postId) => false;

  @override
  bool isReposted(String postId) => false;

  @override
  ThreadPost getLatestPost(ThreadPost post) => post;

  @override
  bool isPostDeleted(String postId) => false;

  @override
  void clearUser() {}
}

class MockGetFeedUseCase implements GetFeedUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> call({bool silent = false}) async {
    return const Right([]);
  }
}

class MockCreateThreadUseCase implements CreateThreadUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, bool>> call(
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    String? audience,
    List<String>? pollOptions,
    DateTime? pollExpiresAt,
    String? communityId,
    bool isSubscriberOnly = false,
    bool isAnonymous = false,
  }) async {
    return const Right(true);
  }
}

class MockNotificationSettingsProvider extends ChangeNotifier implements NotificationSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockChatSettingsProvider extends ChangeNotifier implements ChatSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

class MockVerificationController extends ChangeNotifier implements VerificationController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMonetizationController extends ChangeNotifier implements MonetizationController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool isSubscribedTo(String creatorId) => false;
}

class MockMusicPlaybackController extends ChangeNotifier implements MusicPlaybackController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCommunityService extends ChangeNotifier implements CommunityService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSupabaseClient implements sb.SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.instance;

  setUp(() {
    getIt.reset();
    getIt.registerSingleton<sb.SupabaseClient>(MockSupabaseClient());
    getIt.registerSingleton<GetFeedUseCase>(MockGetFeedUseCase());
    getIt.registerSingleton<CreateThreadUseCase>(MockCreateThreadUseCase());
  });

  testWidgets('Full Auth Flow Integration Test (Onboarding -> Login -> Home)', (WidgetTester tester) async {
    // Set viewport dimensions
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthService();
    final mockDb = MockDatabaseService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
          ChangeNotifierProvider<DatabaseService>.value(value: mockDb),
          ChangeNotifierProvider<NotificationSettingsProvider>.value(value: MockNotificationSettingsProvider()),
          ChangeNotifierProvider<ChatSettingsProvider>.value(value: MockChatSettingsProvider()),
          ChangeNotifierProvider<GeneralSettingsProvider>.value(value: MockGeneralSettingsProvider()),
          ChangeNotifierProvider<VerificationController>.value(value: MockVerificationController()),
          ChangeNotifierProvider<MonetizationController>.value(value: MockMonetizationController()),
          ChangeNotifierProvider<MusicPlaybackController>.value(value: MockMusicPlaybackController()),
          ChangeNotifierProvider<CommunityService>.value(value: MockCommunityService()),
        ],
        child: const PigeonApp(),
      ),
    );

    // 1. Verify Onboarding Screen is loaded
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Pigeon'), findsOneWidget);

    // 2. Tap on "Log In" to navigate to AuthScreen
    final loginButtonFinder = find.text('Log In');
    expect(loginButtonFinder, findsOneWidget);
    await tester.tap(loginButtonFinder);
    
    // Pump frames to let onboarding finish and AuthScreen render
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Verify AuthScreen and LoginForm are loaded
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // 4. Enter test email and password
    final emailFieldFinder = find.byType(TextFormField).first;
    final passwordFieldFinder = find.byType(TextFormField).at(1);
    await tester.enterText(emailFieldFinder, 'test@example.com');
    await tester.enterText(passwordFieldFinder, 'password123');
    await tester.pump();

    // 5. Tap on the login submit button
    final submitButtonFinder = find.text('Login');
    await tester.tap(submitButtonFinder);

    // Pump and wait for auth mock delay
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 6. Verify transition to MainScreen (authenticated state)
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
