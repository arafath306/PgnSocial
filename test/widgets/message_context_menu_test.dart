import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/screens/messenger/widgets/message_context_menu.dart';
import 'package:dak/screens/messenger/widgets/message_bubble.dart';
import 'package:dak/utils/chat_themes.dart';

void main() {
  group('Telegram Message Context Menu & Bubble Tests', () {
    testWidgets('MessageBubble renders clean text without inline timestamp',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_1',
        'text': 'How are you',
        'isMe': true,
        'created_at': '2026-09-17T14:39:00Z',
        'time': '2:39 PM',
        'is_read': true,
        'is_sending': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              msg: msg,
              activeTheme: availableChatThemes.first,
              onTap: (_) {},
              onReply: () {},
              onOpenMedia: (_, {initialIndex = 0, mediaList}) {},
            ),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.text('How are you'), findsOneWidget);

      // Verify timestamp string is NOT rendered inside the message bubble
      expect(find.text('2:39 PM'), findsNothing);
      expect(find.text('14:39'), findsNothing);
    });

    testWidgets('TelegramMessageContextMenu displays exact telegram layout & options',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_2',
        'text': 'How are you',
        'isMe': true,
        'created_at': '2026-09-17T14:39:00Z',
        'time': '14:39',
        'is_read': true,
        'is_sending': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onEdit: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header seen time
      expect(find.textContaining('Seen at'), findsOneWidget);

      // Verify all actions matching screenshot
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('Copy message text'), findsOneWidget);
      expect(find.text('Delete for me'), findsOneWidget);

      // Verify reaction emojis in floating pill
      expect(find.byIcon(Icons.add_rounded), findsWidgets);
    });

    testWidgets('Header displays "Seen at HH:mm" with double check when message is read',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_seen',
        'text': 'Test seen',
        'isMe': true,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': true,
        'is_sending': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Seen at'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsWidgets);
    });

    testWidgets('Header displays "Delivered at HH:mm" when is_delivered is true',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_deliv',
        'text': 'Test delivered',
        'isMe': true,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'is_delivered': true,
        'is_sending': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Delivered at'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsWidgets);
    });

    testWidgets('Header displays "Sent at HH:mm" with single check when not yet delivered',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_sent',
        'text': 'Test sent',
        'isMe': true,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'is_delivered': false,
        'is_sending': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            isOtherUserActive: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sent at'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('Header displays "Sending..." when is_sending is true',
        (WidgetTester tester) async {
      final msg = {
        'id': 'temp_sending',
        'text': 'Test sending',
        'isMe': true,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'is_sending': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sending...'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('Header formats time in 12-hour AM/PM format',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_12hr',
        'text': 'Test 12hr',
        'isMe': true,
        'created_at': '2026-09-17T15:45:00Z',
        'is_read': true,
        'is_sending': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that 12-hour period (AM or PM) is present
      final hasAmPm = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return widget.data!.contains('AM') || widget.data!.contains('PM');
        }
        return false;
      });
      expect(hasAmPm, findsOneWidget);
    });

    testWidgets('Header displays "Edited" on the other side when message is edited',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_edited',
        'text': 'This was edited',
        'isMe': true,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': true,
        'is_sending': false,
        'is_edited': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            isEdited: true,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both Seen at status and Edited status should be present
      expect(find.textContaining('Seen at'), findsOneWidget);
      expect(find.text('Edited'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });

    testWidgets('Header does NOT display "Edited" when message is not edited',
        (WidgetTester tester) async {
      final msg = {
        'id': 'msg_unedited',
        'text': 'Not edited',
        'isMe': true,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': true,
        'is_sending': false,
        'is_edited': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TelegramMessageContextMenu(
            msg: msg,
            bubbleRect: const Rect.fromLTWH(100, 200, 200, 48),
            activeTheme: availableChatThemes.first,
            currentUserId: 'user_1',
            isPinned: false,
            isEdited: false,
            onSelectReaction: (_) {},
            onOpenMoreEmojis: () {},
            onReply: () {},
            onTranslate: () {},
            onCopy: () {},
            onPin: () {},
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Seen at'), findsOneWidget);
      expect(find.text('Edited'), findsNothing);
    });
  });
}
