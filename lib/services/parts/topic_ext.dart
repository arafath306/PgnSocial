part of '../database_service.dart';

extension TopicExtension on DatabaseService {
  // --- Topic System Fetch Methods ---

  Future<List<Map<String, dynamic>>> fetchTrendingTopics() async {
    try {
      final response = await _supabase.rpc('get_trending_topics', params: {'limit_val': 10});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Fetch trending topics error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRisingTopics() async {
    try {
      final response = await _supabase.rpc('get_rising_topics', params: {'limit_val': 10});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Fetch rising topics error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMostDiscussedTopics() async {
    try {
      final response = await _supabase.rpc('get_most_discussed_topics', params: {'limit_val': 10});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Fetch most discussed topics error: $e");
      return [];
    }
  }

  Future<List<ThreadPost>> fetchTopicThreads(String topicName) async {
    try {
      final name = topicName.trim().toLowerCase();
      final nameWithHash = name.startsWith('#') ? name : '#$name';
      final nameWithoutHash = name.startsWith('#') ? name.substring(1) : name;

      var response = await _supabase.rpc('get_topic_threads', params: {'topic_name': nameWithHash});
      var data = response as List<dynamic>;

      if (data.isEmpty) {
        response = await _supabase.rpc('get_topic_threads', params: {'topic_name': nameWithoutHash});
        data = response;
      }
      
      final List<String> threadIds = data.map((json) => json['id'] as String).toList();
      if (threadIds.isEmpty) return [];

      final threadsRes = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id)')
          .inFilter('id', threadIds);
      
      final List<dynamic> threadsData = threadsRes as List<dynamic>;
      final List<ThreadPost> posts = [];
      for (final json in threadsData) {
        try {
          posts.add(ThreadPost.fromJson(json, currentUid: _currentUid));
        } catch (e, stacktrace) {
          debugPrint('Error parsing thread post in fetchFeed: $e\\n$stacktrace');
        }
      }
      
      posts.sort((a, b) => threadIds.indexOf(a.id).compareTo(threadIds.indexOf(b.id)));
      
      _updateCache(posts);
      return posts;
    } catch (e) {
      debugPrint("Fetch topic threads error: $e");
      return [];
    }
  }

  // ── Beta Center & Admin Control Panel State & Methods ──

  bool get isAdmin => myProfile != null && (myProfile!.role == 'Admin' || myProfile!.role == 'Moderator');

  Future<bool> submitBetaBug({
    required String title,
    required String desc,
    required String severity,
    required String screen,
    String? screenshotUrl,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('beta_bugs').insert({
        'user_id': _currentUid,
        'title': title,
        'description': desc,
        'severity': severity,
        'screen_name': screen,
        'screenshot_url': screenshotUrl,
      });
      return true;
    } catch (e) {
      debugPrint("DB Beta bug insert failed: $e");
      return false;
    }
  }

  Future<bool> submitBetaFeature({
    required String title,
    required String desc,
    required String expectedBenefit,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('beta_features').insert({
        'user_id': _currentUid,
        'title': title,
        'description': desc,
        'expected_benefit': expectedBenefit,
      });
      return true;
    } catch (e) {
      debugPrint("DB Beta feature insert failed: $e");
      return false;
    }
  }

  Future<bool> submitBetaFeedback({
    required int rating,
    required String liked,
    required String improved,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('beta_feedback').insert({
        'user_id': _currentUid,
        'rating': rating,
        'liked': liked,
        'improved': improved,
      });
      return true;
    } catch (e) {
      debugPrint("DB Beta feedback insert failed: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBetaKnownIssues() async {
    try {
      final response = await _supabase.from('beta_known_issues').select('*').order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("DB Fetch known issues failed: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchBetaChangelogs() async {
    try {
      final response = await _supabase.from('beta_changelogs').select('*').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("DB Fetch changelogs failed: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyBetaReports() async {
    if (_currentUid.isEmpty) return [];
    List<Map<String, dynamic>> results = [];

    // Bugs
    try {
      final bugRes = await _supabase.from('beta_bugs').select('*').eq('user_id', _currentUid);
      for (var r in (bugRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Bug';
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Fetch my bugs error: $e");
    }

    // Features
    try {
      final featRes = await _supabase.from('beta_features').select('*').eq('user_id', _currentUid);
      for (var r in (featRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Feature';
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Fetch my features error: $e");
    }

    // Sort by created_at descending
    results.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return results;
  }

  Future<List<Map<String, dynamic>>> fetchAdminBetaReports() async {
    List<Map<String, dynamic>> results = [];

    // Fetch bugs
    try {
      final bugRes = await _supabase.from('beta_bugs').select('*, profiles(id, username, full_name, avatar_url)');
      for (var r in (bugRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Bug';
        m['user'] = r['profiles'];
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Admin fetch bugs error: $e");
    }

    // Fetch features
    try {
      final featRes = await _supabase.from('beta_features').select('*, profiles(id, username, full_name, avatar_url)');
      for (var r in (featRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Feature';
        m['user'] = r['profiles'];
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Admin fetch features error: $e");
    }

    // Fetch feedback
    try {
      final feedRes = await _supabase.from('beta_feedback').select('*, profiles(id, username, full_name, avatar_url)');
      for (var r in (feedRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Feedback';
        m['user'] = r['profiles'];
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Admin fetch feedback error: $e");
    }

    results.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return results;
  }

  Future<bool> updateBetaReportStatus(String reportId, String type, String newStatus) async {
    try {
      final table = type == 'Bug' ? 'beta_bugs' : 'beta_features';
      await _supabase.from(table).update({'status': newStatus}).eq('id', reportId);
      return true;
    } catch (e) {
      debugPrint("DB Update status error: $e");
      return false;
    }
  }

  Future<bool> addBetaKnownIssue(String title, String desc, String status) async {
    try {
      await _supabase.from('beta_known_issues').insert({
        'title': title,
        'description': desc,
        'status': status,
      });
      return true;
    } catch (e) {
      debugPrint("DB Add known issue error: $e");
      return false;
    }
  }

  Future<bool> updateBetaKnownIssue(String issueId, String newStatus) async {
    try {
      await _supabase.from('beta_known_issues').update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()}).eq('id', issueId);
      return true;
    } catch (e) {
      debugPrint("DB Update known issue status error: $e");
      return false;
    }
  }

  Future<bool> addBetaChangelog(String version, String newFeatures, String improvements, String bugFixes) async {
    try {
      await _supabase.from('beta_changelogs').insert({
        'version': version,
        'new_features': newFeatures,
        'improvements': improvements,
        'bug_fixes': bugFixes,
      });
      return true;
    } catch (e) {
      debugPrint("DB Add changelog error: $e");
      return false;
    }
  }

  Future<bool> notifyBetaTester({
    required String targetUserId,
    required String title,
    required String body,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('notifications').insert({
        'user_id': targetUserId,
        'actor_id': _currentUid,
        'type': 'SYSTEM',
        'content': '$title: $body',
        'is_read': false,
      });
      return true;
    } catch (e) {
      debugPrint("DB Send notification error: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchHashtags(String query) async {
    try {
      final res = await _supabase
          .from('topics')
          .select('topic_name, post_count')
          .ilike('topic_name', '%$query%')
          .order('post_count', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint("Search hashtags error: $e");
      try {
        final response = await _supabase.rpc('get_trending_topics', params: {'limit_val': 100});
        final allTrending = List<Map<String, dynamic>>.from(response as List);
        final filtered = allTrending.where((t) {
          final name = (t['topic_name'] as String).toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
        filtered.sort((a, b) => (b['post_count'] as int).compareTo(a['post_count'] as int));
        return filtered.take(10).toList();
      } catch (e2) {
        debugPrint("Hashtag search fallback error: $e2");
        return [];
      }
    }
  }

}
