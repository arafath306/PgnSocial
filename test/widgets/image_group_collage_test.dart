import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/screens/messenger/widgets/image_group_collage.dart';
import 'package:dak/screens/messenger/widgets/message_bubble.dart';
import 'package:dak/utils/chat_themes.dart';

void main() {
  // A 1x1 transparent PNG byte array for mock memory images
  final mockBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  group('WhatsApp-Style Image Group Collage Tests', () {
    testWidgets('Collage renders 2 images side-by-side',
        (WidgetTester tester) async {
      final messages = [
        {'id': '1', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '2', 'local_media_bytes': mockBytes, 'is_sending': false},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ImageGroupCollage(
                  groupMessages: messages,
                  isMe: true,
                  onOpenMedia: (items, idx) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify two Image widgets are present
      expect(find.byType(Image), findsNWidgets(2));
      // No overlay badge for 2 images
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('Collage renders 3 images with WhatsApp layout (1 left, 2 right)',
        (WidgetTester tester) async {
      final messages = [
        {'id': '1', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '2', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '3', 'local_media_bytes': mockBytes, 'is_sending': false},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ImageGroupCollage(
                  groupMessages: messages,
                  isMe: true,
                  onOpenMedia: (items, idx) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify three Image widgets are present
      expect(find.byType(Image), findsNWidgets(3));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('Collage renders 4 images in a 2x2 grid without overlay',
        (WidgetTester tester) async {
      final messages = [
        {'id': '1', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '2', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '3', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '4', 'local_media_bytes': mockBytes, 'is_sending': false},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ImageGroupCollage(
                  groupMessages: messages,
                  isMe: true,
                  onOpenMedia: (items, idx) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsNWidgets(4));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('Collage renders 5+ images with +N count overlay on 4th tile',
        (WidgetTester tester) async {
      final messages = [
        {'id': '1', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '2', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '3', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '4', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '5', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '6', 'local_media_bytes': mockBytes, 'is_sending': false},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ImageGroupCollage(
                  groupMessages: messages,
                  isMe: true,
                  onOpenMedia: (items, idx) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // For 6 images, the badge should show +3 (6 - 3)
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('Tapping an image tile triggers onOpenMedia with index',
        (WidgetTester tester) async {
      int clickedIndex = -1;
      List<dynamic>? receivedList;

      final messages = [
        {'id': '1', 'local_media_bytes': mockBytes, 'is_sending': false},
        {'id': '2', 'local_media_bytes': mockBytes, 'is_sending': false},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ImageGroupCollage(
                  groupMessages: messages,
                  isMe: true,
                  onOpenMedia: (list, idx) {
                    receivedList = list;
                    clickedIndex = idx;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap on second image
      final images = find.byType(Image);
      await tester.tap(images.at(1));
      await tester.pump();

      expect(clickedIndex, 1);
      expect(receivedList?.length, 2);
    });

    testWidgets('MessageBubble renders ImageGroupCollage for is_group message',
        (WidgetTester tester) async {
      final groupMsg = {
        'id': 'grp_first',
        'is_group': true,
        'isMe': true,
        'created_at': '2026-09-17T14:39:00Z',
        'time': '14:39',
        'group_messages': [
          {'id': '1', 'local_media_bytes': mockBytes, 'is_sending': false},
          {'id': '2', 'local_media_bytes': mockBytes, 'is_sending': false},
          {'id': '3', 'local_media_bytes': mockBytes, 'is_sending': false},
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              msg: groupMsg,
              activeTheme: availableChatThemes.first,
              onTap: (_) {},
              onReply: () {},
              onOpenMedia: (_, {initialIndex = 0, mediaList}) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ImageGroupCollage), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(3));
    });
  });
}
