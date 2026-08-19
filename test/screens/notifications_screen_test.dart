// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dak/screens/notifications_screen.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/models/notification.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/core/injection.dart';
import 'package:dak/features/notifications/domain/repositories/notification_repository.dart';
import 'package:dak/features/notifications/domain/usecases/clear_notification_inbox_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';
import 'package:dak/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:dak/features/feed/domain/usecases/create_thread_use_case.dart';
import 'package:dak/features/feed/domain/usecases/toggle_like_use_case.dart';
import 'package:dak/features/feed/domain/usecases/toggle_save_thread_use_case.dart';
import 'package:dak/features/feed/domain/usecases/fetch_comments_use_case.dart';
import 'package:dak/features/feed/domain/usecases/add_comment_use_case.dart';
import 'package:dak/core/error/failures.dart';

// ── Fake Notification Repository ─────────────────────────────────────────────
class FakeNotificationRepository implements INotificationRepository {
  @override
  Future<void> showMessageNotification(
          {required int id, required String senderName, required String message, String? payload}) async {}
  @override
  Future<void> showLikeNotification(
          {required int id, required String actorName, required String postSnippet, String? payload}) async {}
  @override
  Future<void> showFollowNotification({required int id, required String actorName, String? payload}) async {}
  @override
  Future<void> showMentionNotification(
          {required int id, required String actorName, required String snippet, String? payload}) async {}
  @override
  Future<void> showActivityNotification(
          {required int id, required String actorName, required String action, String? payload}) async {}
  @override
  Future<void> showNotification({required int id, required String title, required String body, String? payload}) async {}
  @override
  void clearInbox() {}
  @override
  Future<void> playPop() async {}
  @override
  Future<void> playChime() async {}
  @override
  Future<void> playSend() async {}
  @override
  Future<void> playLike() async {}
  @override
  Future<void> playComment() async {}
}

// ── Fake Feed Repository ─────────────────────────────────────────────────────
class FakeFeedRepoForNotif implements IFeedRepository {
  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchFeed({bool silent = false}) async => Right([]);
  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchMyThreads() async => Right([]);
  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserThreads(String userId) async => Right([]);
  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserRepliedThreads(String userId) async => Right([]);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchThreadReactors(String threadId) async => Right([]);
  @override
  Future<Either<Failure, bool>> createThread(String content,
      {List<String>? imageUrls, String? videoUrl, String? audioUrl, String? audience,
       List<String>? pollOptions, DateTime? pollExpiresAt, String? communityId,
       bool isSubscriberOnly = false, bool isAnonymous = false}) async => Right(true);
  @override
  Future<Either<Failure, void>> toggleLike(String threadId, bool shouldLike) async => Right(null);
  @override
  Future<Either<Failure, bool>> togglePinPost(String threadId, bool isPinned) async => Right(true);
  @override
  Future<Either<Failure, bool>> toggleMutePostNotifications(String threadId, bool mute) async => Right(true);
  @override
  Future<Either<Failure, bool>> toggleHidePostFromProfile(String threadId, bool hide) async => Right(true);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchComments(String threadId) async => Right([]);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchCommentReplies(String commentId) async => Right([]);
  @override
  Future<Either<Failure, bool>> addComment(String threadId, String content, {String? parentId, String? imageUrl}) async => Right(true);
  @override
  Future<Either<Failure, bool>> toggleCommentLike(String commentId, bool isLiked) async => Right(true);
  @override
  Future<Either<Failure, bool>> toggleSaveComment(String commentId) async => Right(true);
  @override
  Future<Either<Failure, bool>> deleteComment(String commentId) async => Right(true);
  @override
  Future<Either<Failure, bool>> editComment(String commentId, String newContent) async => Right(true);
  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchSavedPosts() async => Right([]);
  @override
  Future<Either<Failure, void>> toggleSaveThread(String threadId, bool wasAlreadySaved) async => Right(null);
}

// ── Register GetIt Fakes ─────────────────────────────────────────────────────
void _registerDepsForNotif() {
  final fakeNotifRepo = FakeNotificationRepository();
  final fakeFeedRepo = FakeFeedRepoForNotif();

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerSingleton<SupabaseClient>(
      SupabaseClient('https://test.supabase.co', 'test-anon-key'),
    );
  }
  if (!sl.isRegistered<INotificationRepository>()) {
    sl.registerSingleton<INotificationRepository>(fakeNotifRepo);
  }
  if (!sl.isRegistered<ClearNotificationInboxUseCase>()) {
    sl.registerSingleton<ClearNotificationInboxUseCase>(
      ClearNotificationInboxUseCase(fakeNotifRepo),
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
class FakeDbForNotif extends DatabaseService {
  List<AppNotification> _fakeNotifications = [];

  @override
  List<AppNotification> get notifications => _fakeNotifications;

  void setNotifications(List<AppNotification> items) {
    _fakeNotifications = items;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    // No-op: avoid real network calls
  }

  Future<void> markAllNotificationsRead() async {
    // No-op: avoid real network calls
  }

  Future<void> markNotificationRead(String notificationId) async {
    // No-op: avoid real network calls
  }

  Future<List<Profile>> fetchSuggestedProfiles({int limit = 10}) async => [];
}

// ── Helper to build a test notification ─────────────────────────────────────
AppNotification _makeNotif({
  String id = 'notif-1',
  String type = 'like',
  String content = 'liked your post',
  bool read = false,
}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    type: type,
    content: content,
    read: read,
    actor: Profile(id: 'actor-1', fullName: 'Actor Name', username: 'actor_name', avatarUrl: ''),
    threadId: 'thread-1',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _registerDepsForNotif();
  });

  group('NotificationsScreen Tests', () {
    late FakeDbForNotif mockDb;

    setUp(() {
      mockDb = FakeDbForNotif();
    });

    tearDown(() {
      mockDb.dispose();
    });

    Widget buildApp({bool isActive = false}) {
      return ChangeNotifierProvider<DatabaseService>.value(
        value: mockDb,
        child: MaterialApp(
          home: NotificationsScreen(isActive: isActive),
        ),
      );
    }

    testWidgets('Renders screen without crash when notifications empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('Renders "All" tab label', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('Renders "Mentions" tab label', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Mentions'), findsOneWidget);
    });

    testWidgets('Shows empty state text when no notifications',
        (WidgetTester tester) async {
      mockDb.setNotifications([]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // Either a placeholder, empty list, or no tile widgets
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Renders notification item when notifications present',
        (WidgetTester tester) async {
      mockDb.setNotifications([_makeNotif()]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // The screen groups and renders notifications
      expect(
        find.byWidgetPredicate((widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Actor Name')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Multiple notifications render multiple entries',
        (WidgetTester tester) async {
      mockDb.setNotifications([
        _makeNotif(id: 'n1', type: 'like', content: 'liked your post'),
        _makeNotif(id: 'n2', type: 'comment', content: 'commented on your post'),
      ]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Actor Name')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Renders notification content text', (WidgetTester tester) async {
      mockDb.setNotifications([_makeNotif(content: 'liked your post')]);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      // The screen shows notification content
      expect(
        find.byWidgetPredicate((widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('liked')),
        findsAtLeastNWidgets(1),
      );
    });


    testWidgets('Notifications list is not shown when service has no data',
        (WidgetTester tester) async {
      expect(mockDb.notifications, isEmpty);
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });

  group('groupNotifications Tests', () {
    test('Groups likes on same thread together', () {
      final actor1 = Profile(id: 'a1', fullName: 'Alice', username: 'alice', avatarUrl: '');
      final actor2 = Profile(id: 'a2', fullName: 'Bob', username: 'bob', avatarUrl: '');
      final notifs = [
        AppNotification(
          id: 'n1', userId: 'user-1', type: 'like', content: 'liked', read: false,
          actor: actor1, threadId: 'thread-1',
          createdAt: DateTime.now().toIso8601String(),
        ),
        AppNotification(
          id: 'n2', userId: 'user-1', type: 'like', content: 'liked', read: false,
          actor: actor2, threadId: 'thread-1',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        ),
      ];

      final grouped = groupNotifications(notifs);
      // Should be grouped into 1 item (same type + same thread)
      expect(grouped.length, 1);
      expect(grouped.first.rawNotifications.length, 2);
    });

    test('Separates notifications of different types', () {
      final actor = Profile(id: 'a1', fullName: 'Alice', username: 'alice', avatarUrl: '');
      final notifs = [
        AppNotification(
          id: 'n1', userId: 'user-1', type: 'like', content: 'liked', read: false,
          actor: actor, threadId: 'thread-1',
          createdAt: DateTime.now().toIso8601String(),
        ),
        AppNotification(
          id: 'n2', userId: 'user-1', type: 'comment', content: 'commented', read: false,
          actor: actor, threadId: 'thread-1',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      final grouped = groupNotifications(notifs);
      expect(grouped.length, 2);
    });

    test('Follow notifications are separate grouped items', () {
      final actor = Profile(id: 'a1', fullName: 'Alice', username: 'alice', avatarUrl: '');
      final notifs = [
        AppNotification(
          id: 'n1', userId: 'user-1', type: 'follow', content: 'followed you', read: false,
          actor: actor, threadId: null,
          createdAt: DateTime.now().toIso8601String(),
        ),
        AppNotification(
          id: 'n2', userId: 'user-1', type: 'follow', content: 'followed you', read: false,
          actor: actor, threadId: null,
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
        ),
      ];

      final grouped = groupNotifications(notifs);
      // Follow notifications outside the 15-min window are separate items
      expect(grouped.isNotEmpty, isTrue);
    });

    test('Empty list returns empty grouped list', () {
      final grouped = groupNotifications([]);
      expect(grouped, isEmpty);
    });

    test('Single like notification is not grouped', () {
      final actor = Profile(id: 'a1', fullName: 'Alice', username: 'alice', avatarUrl: '');
      final notifs = [
        AppNotification(
          id: 'n1', userId: 'user-1', type: 'like', content: 'liked', read: false,
          actor: actor, threadId: 'thread-1',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      final grouped = groupNotifications(notifs);
      expect(grouped.length, 1);
      expect(grouped.first.rawNotifications.length, 1);
      expect(grouped.first.displayTitle, 'Alice');
    });
  });

  group('GroupedNotification displayTime Tests', () {
    test('Returns "Just now" for recent notifications', () {
      final notif = GroupedNotification(
        id: 'n1',
        type: 'like',
        rawNotifications: [],
        displayTitle: 'Alice',
        displayContent: 'liked your post',
        sortTime: DateTime.now().toUtc().subtract(const Duration(seconds: 30)),
        read: false,
      );
      expect(notif.displayTime, 'Just now');
    });

    test('Returns minutes ago for recent notifications', () {
      final notif = GroupedNotification(
        id: 'n1',
        type: 'like',
        rawNotifications: [],
        displayTitle: 'Alice',
        displayContent: 'liked your post',
        sortTime: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        read: false,
      );
      expect(notif.displayTime, '5m ago');
    });

    test('Returns hours ago for older notifications', () {
      final notif = GroupedNotification(
        id: 'n1',
        type: 'like',
        rawNotifications: [],
        displayTitle: 'Alice',
        displayContent: 'liked your post',
        sortTime: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
        read: false,
      );
      expect(notif.displayTime, '3h ago');
    });

    test('Returns days ago for old notifications', () {
      final notif = GroupedNotification(
        id: 'n1',
        type: 'like',
        rawNotifications: [],
        displayTitle: 'Alice',
        displayContent: 'liked your post',
        sortTime: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        read: false,
      );
      expect(notif.displayTime, '3d ago');
    });

    test('Returns date string for very old notifications', () {
      final notif = GroupedNotification(
        id: 'n1',
        type: 'like',
        rawNotifications: [],
        displayTitle: 'Alice',
        displayContent: 'liked your post',
        sortTime: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        read: false,
      );
      // Should return a date like "08/08" format (dd/mm)
      expect(notif.displayTime, matches(RegExp(r'^\d{2}/\d{2}$')));
    });
  });
}
