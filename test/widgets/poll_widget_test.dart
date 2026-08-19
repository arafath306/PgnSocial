import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/widgets/poll_widget.dart';
import 'package:dak/models/poll_option.dart';
import 'package:dak/models/thread_post.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/services/database_service.dart';

class FakeDatabaseService extends Fake implements DatabaseService {
  Future<void> votePoll(String postId, String optionId) async {}
}

void main() {
  group('PollWidget Tests', () {
    testWidgets('Renders options correctly', (WidgetTester tester) async {
      final options = [
        PollOption(id: '1', threadId: 'p1', optionText: 'Option A', votesCount: 5),
        PollOption(id: '2', threadId: 'p1', optionText: 'Option B', votesCount: 10),
      ];

      final post = ThreadPost(
        id: 'p1',
        userId: 'u1',
        author: Profile(id: 'u1', username: 'test', fullName: 'Test'),
        content: 'Poll',
        createdAt: DateTime.now().toIso8601String(),
        pollOptions: options,
      );

      final fakeDb = FakeDatabaseService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PollWidget(
              post: post,
              dbService: fakeDb,
            ),
          ),
        ),
      );
      
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('15 votes'), findsOneWidget);
    });
  });
}
