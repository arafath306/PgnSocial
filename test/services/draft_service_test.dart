import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/services/draft_service.dart';
import 'package:dak/models/draft_post.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DraftService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      
      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      });
    });

    test('saveDraft stores to local storage and getDrafts returns it', () async {
      final service = DraftService();
      
      final draft = DraftPost(
        id: 'draft1',
        content: 'Hello Draft',
        audience: 'everyone',
        updatedAt: DateTime.now(),
      );

      await service.saveDraft(draft, null);
      
      final drafts = await service.getDrafts();
      expect(drafts.length, 1);
      expect(drafts.first.id, 'draft1');
      expect(drafts.first.content, 'Hello Draft');
    });

    test('deleteDrafts removes correctly', () async {
      final service = DraftService();
      
      final draft = DraftPost(
        id: 'draft1',
        content: 'Hello Draft',
        audience: 'everyone',
        updatedAt: DateTime.now(),
      );

      await service.saveDraft(draft, null);
      var count = await service.getDraftCount();
      expect(count, 1);

      await service.deleteDrafts(['draft1']);
      count = await service.getDraftCount();
      expect(count, 0);
    });
  });
}
