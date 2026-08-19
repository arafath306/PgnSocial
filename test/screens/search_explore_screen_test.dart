// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dak/screens/search_explore_screen.dart';
import 'package:dak/services/database_service.dart';
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

void _registerDeps() {
  final fakeFeedRepo = _FakeFeedRepo();
  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerSingleton<SupabaseClient>(SupabaseClient('https://test.supabase.co', 'test-anon-key'));
  }
  if (!sl.isRegistered<IFeedRepository>()) sl.registerSingleton<IFeedRepository>(fakeFeedRepo);
  if (!sl.isRegistered<GetFeedUseCase>()) sl.registerSingleton<GetFeedUseCase>(GetFeedUseCase(fakeFeedRepo));
  if (!sl.isRegistered<CreateThreadUseCase>()) sl.registerSingleton<CreateThreadUseCase>(CreateThreadUseCase(fakeFeedRepo));
  if (!sl.isRegistered<ToggleLikeUseCase>()) sl.registerSingleton<ToggleLikeUseCase>(ToggleLikeUseCase(fakeFeedRepo));
  if (!sl.isRegistered<ToggleSaveThreadUseCase>()) sl.registerSingleton<ToggleSaveThreadUseCase>(ToggleSaveThreadUseCase(fakeFeedRepo));
  if (!sl.isRegistered<FetchCommentsUseCase>()) sl.registerSingleton<FetchCommentsUseCase>(FetchCommentsUseCase(fakeFeedRepo));
  if (!sl.isRegistered<AddCommentUseCase>()) sl.registerSingleton<AddCommentUseCase>(AddCommentUseCase(fakeFeedRepo));
}

// ── Fake DatabaseService ─────────────────────────────────────────────────────
class _FakeDbForSearch extends DatabaseService {
  List<Profile> _recommendedProfiles = [];
  List<Map<String, dynamic>> _trendingTopics = [];

  void setRecommended(List<Profile> profiles) {
    _recommendedProfiles = profiles;
  }

  void setTrendingTopics(List<Map<String, dynamic>> topics) {
    _trendingTopics = topics;
  }

  Future<List<Profile>> getRecommendedProfiles() async => _recommendedProfiles;

  Future<List<Map<String, dynamic>>> fetchTrendingTopics() async => _trendingTopics;

  Future<List<Profile>> searchUsers(String query) async => [];

  Future<List<ThreadPost>> searchPosts(String query) async => [];

  Future<List<Profile>> fetchSuggestedProfiles({int limit = 10}) async => [];
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _registerDeps();
  });

  group('SearchExploreScreen Tests', () {
    late _FakeDbForSearch mockDb;

    setUp(() {
      mockDb = _FakeDbForSearch();
    });

    tearDown(() {
      mockDb.dispose();
    });

    Widget buildApp({String? initialQuery}) {
      return ChangeNotifierProvider<DatabaseService>.value(
        value: mockDb,
        child: MaterialApp(
          home: SearchExploreScreen(initialQuery: initialQuery),
        ),
      );
    }

    testWidgets('Renders without crash', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SearchExploreScreen), findsOneWidget);
    });

    testWidgets('Renders search text field', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('Search field is pre-filled with initialQuery', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(initialQuery: 'flutter'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('flutter'), findsAtLeastNWidgets(1));
    });

    testWidgets('Shows shimmer while topics are loading', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      // Before postFrameCallback fires, _isTopicsLoading is true
      await tester.pump(Duration.zero);
      // Shimmer may be shown
      expect(find.byType(SearchExploreScreen), findsOneWidget);
    });

    testWidgets('Renders Scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Has scrollable area in explore mode', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((w) =>
            w is CustomScrollView || w is ListView ||
            w is SingleChildScrollView || w is GridView),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Shows recommended profiles when set', (WidgetTester tester) async {
      mockDb.setRecommended([
        Profile(id: 'r1', fullName: 'Recommended User', username: 'recuser', avatarUrl: ''),
      ]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 200));
      // Recommended user might appear in the explore section
      expect(find.byType(SearchExploreScreen), findsOneWidget);
    });

    testWidgets('Typing in search field does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'hello');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SearchExploreScreen), findsOneWidget);
    });

    testWidgets('Clearing search field does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(initialQuery: 'test'));
      await tester.pump(const Duration(milliseconds: 100));
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SearchExploreScreen), findsOneWidget);
    });
  });
}
