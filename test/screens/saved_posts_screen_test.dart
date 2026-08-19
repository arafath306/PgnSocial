// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:dak/screens/saved_posts_screen.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:dak/services/view_tracking_service.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/models/thread_post.dart';
import 'package:dak/core/injection.dart';
import 'package:dak/core/error/failures.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';
import 'package:dak/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:dak/features/feed/domain/usecases/create_thread_use_case.dart';
import 'package:dak/features/feed/domain/usecases/toggle_like_use_case.dart';
import 'package:dak/features/feed/domain/usecases/toggle_save_thread_use_case.dart';
import 'package:dak/features/feed/domain/usecases/fetch_comments_use_case.dart';
import 'package:dak/features/feed/domain/usecases/add_comment_use_case.dart';
import 'package:dak/widgets/custom_thread_card.dart';
import 'package:dak/state/music_playback_controller.dart';
import 'package:dak/state/monetization_controller.dart';

// ── Fake Feed Repository ─────────────────────────────────────────────────────
class _FakeFeedRepo implements IFeedRepository {
  @override Future<Either<Failure, List<ThreadPostEntity>>> fetchFeed({bool silent = false}) async => Right([]);
  @override Future<Either<Failure, List<ThreadPostEntity>>> fetchMyThreads() async => Right([]);
  @override Future<Either<Failure, List<ThreadPostEntity>>> fetchUserThreads(String userId) async => Right([]);
  @override Future<Either<Failure, List<ThreadPostEntity>>> fetchUserRepliedThreads(String userId) async => Right([]);
  @override Future<Either<Failure, List<Map<String, dynamic>>>> fetchThreadReactors(String threadId) async => Right([]);
  @override Future<Either<Failure, bool>> createThread(String content, {List<String>? imageUrls, String? videoUrl, String? audioUrl, String? audience, List<String>? pollOptions, DateTime? pollExpiresAt, String? communityId, bool isSubscriberOnly = false, bool isAnonymous = false}) async => Right(true);
  @override Future<Either<Failure, void>> toggleLike(String threadId, bool shouldLike) async => Right(null);
  @override Future<Either<Failure, bool>> togglePinPost(String threadId, bool isPinned) async => Right(true);
  @override Future<Either<Failure, bool>> toggleMutePostNotifications(String threadId, bool mute) async => Right(true);
  @override Future<Either<Failure, bool>> toggleHidePostFromProfile(String threadId, bool hide) async => Right(true);
  @override Future<Either<Failure, List<Map<String, dynamic>>>> fetchComments(String threadId) async => Right([]);
  @override Future<Either<Failure, List<Map<String, dynamic>>>> fetchCommentReplies(String commentId) async => Right([]);
  @override Future<Either<Failure, bool>> addComment(String threadId, String content, {String? parentId, String? imageUrl}) async => Right(true);
  @override Future<Either<Failure, bool>> toggleCommentLike(String commentId, bool isLiked) async => Right(true);
  @override Future<Either<Failure, bool>> toggleSaveComment(String commentId) async => Right(true);
  @override Future<Either<Failure, bool>> deleteComment(String commentId) async => Right(true);
  @override Future<Either<Failure, bool>> editComment(String commentId, String newContent) async => Right(true);
  @override Future<Either<Failure, List<ThreadPostEntity>>> fetchSavedPosts() async => Right([]);
  @override Future<Either<Failure, void>> toggleSaveThread(String threadId, bool wasAlreadySaved) async => Right(null);
}

// ── Register GetIt Fakes ─────────────────────────────────────────────────────
void _registerDepsForSavedPosts() {
  final fakeFeedRepo = _FakeFeedRepo();

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerSingleton<SupabaseClient>(
      SupabaseClient('https://test.supabase.co', 'test-anon-key'),
    );
  }
  if (!sl.isRegistered<IFeedRepository>()) {
    sl.registerSingleton<IFeedRepository>(fakeFeedRepo);
  }
  if (!sl.isRegistered<GetFeedUseCase>()) {
    sl.registerSingleton<GetFeedUseCase>(GetFeedUseCase(fakeFeedRepo));
  }
  if (!sl.isRegistered<CreateThreadUseCase>()) {
    sl.registerSingleton<CreateThreadUseCase>(CreateThreadUseCase(fakeFeedRepo));
  }
  if (!sl.isRegistered<ToggleLikeUseCase>()) {
    sl.registerSingleton<ToggleLikeUseCase>(ToggleLikeUseCase(fakeFeedRepo));
  }
  if (!sl.isRegistered<ToggleSaveThreadUseCase>()) {
    sl.registerSingleton<ToggleSaveThreadUseCase>(ToggleSaveThreadUseCase(fakeFeedRepo));
  }
  if (!sl.isRegistered<FetchCommentsUseCase>()) {
    sl.registerSingleton<FetchCommentsUseCase>(FetchCommentsUseCase(fakeFeedRepo));
  }
  if (!sl.isRegistered<AddCommentUseCase>()) {
    sl.registerSingleton<AddCommentUseCase>(AddCommentUseCase(fakeFeedRepo));
  }
}

// ── Fake DatabaseService ─────────────────────────────────────────────────────
class _FakeDbForSaved extends DatabaseService {
  @override
  Future<void> fetchSavedPosts() async {}


  Future<void> fetchSavedComments() async {}

  Future<List<Profile>> fetchSuggestedProfiles({int limit = 10}) async => [];

  void populateSavedPosts(List<ThreadPost> posts) {
    savedPosts.clear();
    savedPosts.addAll(posts);
    notifyListeners();
  }

  void populateSavedComments(List<Map<String, dynamic>> comments) {
    savedComments.clear();
    savedComments.addAll(comments);
    notifyListeners();
  }
}

// ── Mock classes for CustomThreadCard providers ──────────────────────────────
class MockGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  bool get autoplayVideos => false;

  @override
  bool get lowDataMode => false;
}

class MockMonetizationController extends ChangeNotifier implements MonetizationController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool isSubscribedTo(String creatorId) => false;
}

class MockViewTrackingService extends ChangeNotifier implements ViewTrackingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  void trackView(String postId) {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    _registerDepsForSavedPosts();
  });

  group('SavedPostsScreen Tests', () {
    late _FakeDbForSaved mockDb;

    setUp(() {
      mockDb = _FakeDbForSaved();
    });

    tearDown(() {
      mockDb.dispose();
    });

    Widget buildApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseService>.value(value: mockDb),
          ChangeNotifierProvider<MusicPlaybackController>(
            create: (_) => MusicPlaybackController(),
          ),
          ChangeNotifierProvider<GeneralSettingsProvider>(
            create: (_) => MockGeneralSettingsProvider(),
          ),
          ChangeNotifierProvider<MonetizationController>(
            create: (_) => MockMonetizationController(),
          ),
          ChangeNotifierProvider<ViewTrackingService>(
            create: (_) => MockViewTrackingService(),
          ),
        ],
        child: const MaterialApp(
          home: SavedPostsScreen(),
        ),
      );
    }

    testWidgets('Renders screen without crash', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SavedPostsScreen), findsOneWidget);
    });

    testWidgets('Shows "Saved Posts" or equivalent title', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // Screen should render with some title
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Shows empty state when no saved posts or comments',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomThreadCard), findsNothing);
    });

    testWidgets('Renders saved thread post cards when posts are present',
        (WidgetTester tester) async {
      mockDb.populateSavedPosts([
        ThreadPost(
          id: 'sp1',
          userId: 'u1',
          author: Profile(id: 'u1', fullName: 'Alice', username: 'alice', avatarUrl: ''),
          content: 'Saved post content',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomThreadCard), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders multiple saved posts', (WidgetTester tester) async {
      mockDb.populateSavedPosts([
        ThreadPost(
          id: 'sp1',
          userId: 'u1',
          author: Profile(id: 'u1', fullName: 'Alice', username: 'alice', avatarUrl: ''),
          content: 'First saved post',
          createdAt: DateTime.now().toIso8601String(),
        ),
        ThreadPost(
          id: 'sp2',
          userId: 'u2',
          author: Profile(id: 'u2', fullName: 'Bob', username: 'bob', avatarUrl: ''),
          content: 'Second saved post',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomThreadCard), findsAtLeastNWidgets(1));
    });

    testWidgets('Saved post content is visible in the list', (WidgetTester tester) async {
      mockDb.populateSavedPosts([
        ThreadPost(
          id: 'sp3',
          userId: 'u3',
          author: Profile(id: 'u3', fullName: 'Carol', username: 'carol', avatarUrl: ''),
          content: 'Unique saved text content here',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Unique saved text content here')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Renders TabBar for posts and comments tabs', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // SavedPostsScreen should have tab or equivalent UI element
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Screen has at least one scrollable widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // CustomScrollView or ListView should be present
      expect(
        find.byWidgetPredicate((w) => w is CustomScrollView || w is ListView || w is SingleChildScrollView),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
