import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/services/community_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://mock.supabase.co', publishableKey: 'mock');
    } catch (e) {
      // Already initialized
    }
  });

  group('CommunityService Tests', () {
    test('Initial state is correct', () {
      final service = CommunityService();
      expect(service.joinedCommunities, isEmpty);
      expect(service.recommendedCommunities, isEmpty);
      expect(service.recentSearches, isEmpty);
      expect(service.isLoadingJoined, isFalse);
      expect(service.isLoadingRecommended, isFalse);
    });

    test('Recent searches can be added and removed', () async {
      final service = CommunityService();
      await service.loadRecentSearches();
      expect(service.recentSearches, isEmpty);

      await service.addRecentSearch('flutter');
      expect(service.recentSearches, ['flutter']);

      await service.addRecentSearch('dart');
      expect(service.recentSearches, ['dart', 'flutter']); // recent first

      await service.removeRecentSearch('flutter');
      expect(service.recentSearches, ['dart']);

      await service.clearRecentSearches();
      expect(service.recentSearches, isEmpty);
    });

    test('isHandleAvailable returns safely on error', () async {
      final service = CommunityService();
      final res = await service.isHandleAvailable('test');
      expect(res, isFalse); // mock returns error or null, defaults to false
    });
  });
}
