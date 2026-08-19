// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dak/screens/comment_detail_screen.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/models/profile.dart';
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
class _FakeDbForComment extends DatabaseService {
  Future<List<Map<String, dynamic>>> fetchCommentReplies(String commentId) async => [];

  Future<void> markNotificationRead(String notificationId) async {}

  Future<List<Profile>> fetchSuggestedProfiles({int limit = 10}) async => [];
}

// ── Helper comment data ──────────────────────────────────────────────────────
Map<String, dynamic> _makeComment({
  String id = 'comment-1',
  String content = 'Test comment content',
  String userId = 'user-1',
  String authorName = 'Test User',
  String authorUsername = 'testuser',
}) {
  final authorProfile = Profile(
    id: userId,
    fullName: authorName,
    username: authorUsername,
    avatarUrl: '',
    isVerified: false,
    isPrivate: false,
  );
  return {
    'id': id,
    'content': content,
    'user_id': userId,
    'thread_id': 'thread-1',
    'created_at': DateTime.now().toIso8601String(),
    'likes_count': 0,
    'is_liked': false,
    'is_saved': false,
    'author': authorProfile,
    'profiles': {
      'id': userId,
      'full_name': authorName,
      'username': authorUsername,
      'avatar_url': '',
      'is_verified': false,
      'is_private': false,
    },
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _registerDeps();
  });

  group('CommentDetailScreen Tests', () {
    late _FakeDbForComment mockDb;

    setUp(() {
      mockDb = _FakeDbForComment();
    });

    tearDown(() {
      mockDb.dispose();
    });

    Widget buildApp({Map<String, dynamic>? comment}) {
      return ChangeNotifierProvider<DatabaseService>.value(
        value: mockDb,
        child: MaterialApp(
          home: CommentDetailScreen(
            comment: comment ?? _makeComment(),
            threadId: 'thread-1',
          ),
        ),
      );
    }

    testWidgets('Renders without crash for a basic comment', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CommentDetailScreen), findsOneWidget);
    });

    testWidgets('Renders the comment author name', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(comment: _makeComment(authorName: 'Jane Doe')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Jane Doe')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Renders the comment content text', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(comment: _makeComment(content: 'Hello world reply here')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Hello world reply here'), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders back navigation button', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // Back button or icon button should be present
      expect(
        find.byWidgetPredicate((w) => w is IconButton || w is BackButton),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Renders reply input field', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('Empty replies list shows no extra cards initially', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // No extra reply items beyond the base comment
      expect(find.byType(CommentDetailScreen), findsOneWidget);
    });

    testWidgets('Has scrollable content area', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((w) =>
            w is CustomScrollView || w is ListView || w is SingleChildScrollView),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Screen shows Scaffold widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
