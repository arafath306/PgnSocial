// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Debug Supabase feeds query details', () async {
    final supabase = SupabaseClient(
      "https://lznxtbnqwaryqkyxfwgy.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6bnh0Ym5xd2FyeXFreXhmd2d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNTk1MjIsImV4cCI6MjA5NjkzNTUyMn0.PGQqRFmGjE5GncIs5Eeqf5fvgxQtDMgvggNLzNEGOJk",
    );

    // Let's test for all three users found in profiles:
    // 1. 536aec0b-1173-42ce-8f42-747edefc1152
    // 2. 39d4c7c3-c791-403b-bf97-c719ea3fc68f
    // 3. f36440d9-ef49-462e-ad48-9f03273983a7

    final testUids = [
      '536aec0b-1173-42ce-8f42-747edefc1152',
      '39d4c7c3-c791-403b-bf97-c719ea3fc68f',
      'f36440d9-ef49-462e-ad48-9f03273983a7'
    ];

    for (final userId in testUids) {
      print("\n==============================================");
      print("TESTING FOR USER: $userId");
      print("==============================================");

      try {
        final response = await supabase.rpc(
          'get_personalized_feed',
          params: {
            'p_user_id': userId,
            'p_limit': 15,
            'p_offset': 0,
          },
        );

        final List<dynamic> data = response as List<dynamic>;
        print("RPC returned ${data.length} items.");

        if (data.isNotEmpty) {
          final List<String> threadIds = data.map((json) => json['id'] as String).toList();
          print("Thread IDs from RPC: $threadIds");

          final threadsRes = await supabase
              .from('threads')
              .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id)')
              .inFilter('id', threadIds);

          final List<dynamic> threadsData = threadsRes as List<dynamic>;
          print("Joined threads query returned ${threadsData.length} items.");
          
          for (var t in threadsData) {
            final threadId = t['id'];
            final isPrivate = t['profiles']?['is_private'];
            final authorId = t['user_id'];
            print("  - Thread ID: $threadId, Author: $authorId, Private Profile: $isPrivate");
          }
        }
      } catch (e, stack) {
        print("Error for user $userId: $e");
        print(stack);
      }
    }
  }, skip: 'Requires live Supabase database and network connectivity');
}
