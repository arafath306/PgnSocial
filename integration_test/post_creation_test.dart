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
import 'package:dak/screens/create_thread_screen.dart';
import 'package:dak/screens/main_screen.dart';
import 'package:dak/core/error/failures.dart';
import 'package:dak/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:dak/features/feed/domain/usecases/create_thread_use_case.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';

// Mock class declarations
class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  bool get isUserSignedIn => true;

  @override
  sb.User? get currentUser => sb.User(
        id: 'user123',
        email: 'test@example.com',
        createdAt: DateTime.now().toIso8601String(),
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        emailConfirmedAt: DateTime.now().toIso8601String(),
      );

  @override
  bool get requires2FA => false;

  @override
  bool get isEmailVerified => true;
}

class MockDatabaseService extends DatabaseService {
  final List<ThreadPost> _mockFeed = [];

  @override
  Profile? get myProfile => Profile(id: 'user123', username: 'john_doe', fullName: 'John Doe');

  @override
  String get currentUid => 'user123';

  @override
  List<ThreadPost> get feed => _mockFeed;

  @override
  List<ThreadPost> get personalizedFeed => _mockFeed;

  @override
  bool get aiFeedHasMore => false;

  @override
  List<ThreadPost> get myThreads => _mockFeed;

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

  // A local helper to add mock threads dynamically for the test assertion
  void addMockThread(String content) {
    _mockFeed.insert(
      0,
      ThreadPost(
        id: 'post_123',
        userId: 'user123',
        author: Profile(id: 'user123', username: 'john_doe', fullName: 'John Doe'),
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    notifyListeners();
  }
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
  final MockDatabaseService mockDb;
  MockCreateThreadUseCase(this.mockDb);

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
    mockDb.addMockThread(content);
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
  late MockDatabaseService mockDb;

  setUp(() {
    getIt.reset();
    mockDb = MockDatabaseService();
    getIt.registerSingleton<sb.SupabaseClient>(MockSupabaseClient());
    getIt.registerSingleton<GetFeedUseCase>(MockGetFeedUseCase());
    getIt.registerSingleton<CreateThreadUseCase>(MockCreateThreadUseCase(mockDb));
  });

  testWidgets('Authenticated user can create a new thread and view it in the feed', (WidgetTester tester) async {
    // Set viewport dimensions
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthService();

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

    // 1. Verify MainScreen is loaded initially in signed-in state
    expect(find.byType(MainScreen), findsOneWidget);

    // 2. Tap on Floating Action Button (Create Thread)
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);

    // Wait for the delayed navigation action (180ms in main_screen.dart)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // 3. Verify CreateThreadScreen is loaded
    expect(find.byType(CreateThreadScreen), findsOneWidget);

    // 4. Input text content into the composer TextField
    final textFieldFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == "Send your thoughts...",
    );
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(textFieldFinder, 'This is a brand new integration test thread post!');
    await tester.pump();

    // 5. Tap on the "Release" button in the custom header to submit the thread
    final releaseButtonFinder = find.text('Release');
    expect(releaseButtonFinder, findsOneWidget);
    await tester.tap(releaseButtonFinder);

    // Pump and wait for pop navigation transition
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 6. Verify CreateThreadScreen is popped and new post is visible in the feed
    expect(find.byType(CreateThreadScreen), findsNothing);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('This is a brand new integration test thread post!'), findsOneWidget);
  });
}
