import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/notifications/domain/usecases/show_notification_use_case.dart';
import 'package:dak/features/notifications/domain/repositories/notification_repository.dart';

class FakeNotificationRepository implements INotificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  String? lastCalledMethod;
  Map<String, dynamic> lastArgs = {};

  @override
  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String message,
    String? payload,
  }) async {
    lastCalledMethod = 'showMessageNotification';
    lastArgs = {'id': id, 'senderName': senderName, 'message': message, 'payload': payload};
  }

  @override
  Future<void> showLikeNotification({
    required int id,
    required String actorName,
    required String postSnippet,
    String? payload,
  }) async {
    lastCalledMethod = 'showLikeNotification';
    lastArgs = {'id': id, 'actorName': actorName, 'postSnippet': postSnippet, 'payload': payload};
  }

  @override
  Future<void> showFollowNotification({
    required int id,
    required String actorName,
    String? payload,
  }) async {
    lastCalledMethod = 'showFollowNotification';
    lastArgs = {'id': id, 'actorName': actorName, 'payload': payload};
  }

  @override
  Future<void> showMentionNotification({
    required int id,
    required String actorName,
    required String snippet,
    String? payload,
  }) async {
    lastCalledMethod = 'showMentionNotification';
    lastArgs = {'id': id, 'actorName': actorName, 'snippet': snippet, 'payload': payload};
  }

  @override
  Future<void> showActivityNotification({
    required int id,
    required String actorName,
    required String action,
    String? payload,
  }) async {
    lastCalledMethod = 'showActivityNotification';
    lastArgs = {'id': id, 'actorName': actorName, 'action': action, 'payload': payload};
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    lastCalledMethod = 'showNotification';
    lastArgs = {'id': id, 'title': title, 'body': body, 'payload': payload};
  }
}

void main() {
  group('ShowNotificationUseCase Tests', () {
    late FakeNotificationRepository repository;
    late ShowNotificationUseCase useCase;

    setUp(() {
      repository = FakeNotificationRepository();
      useCase = ShowNotificationUseCase(repository);
    });

    test('calls showMessageNotification on message type', () async {
      await useCase(
        type: NotificationType.message,
        id: 1,
        senderName: 'John',
        message: 'Hello!',
        payload: 'msg_payload',
      );

      expect(repository.lastCalledMethod, equals('showMessageNotification'));
      expect(repository.lastArgs['senderName'], equals('John'));
      expect(repository.lastArgs['message'], equals('Hello!'));
    });

    test('calls showLikeNotification on like type', () async {
      await useCase(
        type: NotificationType.like,
        id: 2,
        actorName: 'Alice',
        postSnippet: 'A great day...',
      );

      expect(repository.lastCalledMethod, equals('showLikeNotification'));
      expect(repository.lastArgs['actorName'], equals('Alice'));
      expect(repository.lastArgs['postSnippet'], equals('A great day...'));
    });

    test('calls showFollowNotification on follow type', () async {
      await useCase(
        type: NotificationType.follow,
        id: 3,
        actorName: 'Bob',
      );

      expect(repository.lastCalledMethod, equals('showFollowNotification'));
      expect(repository.lastArgs['actorName'], equals('Bob'));
    });

    test('calls showMentionNotification on mention type', () async {
      await useCase(
        type: NotificationType.mention,
        id: 4,
        actorName: 'Charlie',
        snippet: 'mentioned you in a post',
      );

      expect(repository.lastCalledMethod, equals('showMentionNotification'));
      expect(repository.lastArgs['actorName'], equals('Charlie'));
      expect(repository.lastArgs['snippet'], equals('mentioned you in a post'));
    });

    test('calls showActivityNotification on activity type', () async {
      await useCase(
        type: NotificationType.activity,
        id: 5,
        actorName: 'David',
        action: 'shared a photo',
      );

      expect(repository.lastCalledMethod, equals('showActivityNotification'));
      expect(repository.lastArgs['actorName'], equals('David'));
      expect(repository.lastArgs['action'], equals('shared a photo'));
    });

    test('calls showNotification on generic type', () async {
      await useCase(
        type: NotificationType.generic,
        id: 6,
        title: 'System Alert',
        body: 'Maintenance scheduled',
      );

      expect(repository.lastCalledMethod, equals('showNotification'));
      expect(repository.lastArgs['title'], equals('System Alert'));
      expect(repository.lastArgs['body'], equals('Maintenance scheduled'));
    });
  });
}
