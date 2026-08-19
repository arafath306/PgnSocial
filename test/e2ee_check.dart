// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase Table and Schema Verification', () async {
    final supabase = SupabaseClient(
      "https://lznxtbnqwaryqkyxfwgy.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6bnh0Ym5xd2FyeXFreXhmd2d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNTk1MjIsImV4cCI6MjA5NjkzNTUyMn0.PGQqRFmGjE5GncIs5Eeqf5fvgxQtDMgvggNLzNEGOJk",
    );

    print('\n--- CHECKING TABLES IN SUPABASE ---');

    final tables = [
      'profiles',
      'threads',
      'likes',
      'comments',
      'comment_likes',
      'follows',
      'messages',
      'notifications',
      'reports',
      'blocks',
      'mutes',
      'thread_hides',
      'reposts',
      'verification_requests',
      'saved_comments',
      'beta_bugs',
      'beta_features',
      'beta_feedback',
      'beta_known_issues',
      'beta_changelogs',
    ];

    for (final table in tables) {
      try {
        await supabase.from(table).select('id').limit(1).maybeSingle();
        print('  - Table "$table": EXISTS (Query success)');
      } catch (e) {
        print('  - Table "$table": ❌ ERROR/MISSING: $e');
      }
    }
  }, skip: 'Requires live Supabase database and network connectivity');
}
