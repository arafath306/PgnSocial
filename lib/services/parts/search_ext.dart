part of '../database_service.dart';

extension SearchExtension on DatabaseService {
  // --- Search & Recommendations ---

  Future<List<Profile>> searchProfiles(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);
      final List<dynamic> data = response as List<dynamic>;
      final List<Profile> results = data.map((json) => Profile.fromJson(json)).toList();
      
      // Filter out blocked profiles
      results.removeWhere((profile) => _blockedUserIds.contains(profile.id));
      
      results.sort((a, b) {
        final aUser = a.username.toLowerCase();
        final bUser = b.username.toLowerCase();
        final q = query.toLowerCase();
        
        final aExact = aUser == q;
        final bExact = bUser == q;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        
        final aStart = aUser.startsWith(q);
        final bStart = bUser.startsWith(q);
        if (aStart && !bStart) return -1;
        if (!aStart && bStart) return 1;
        
        return 0;
      });
      
      return results;
    } catch (e) {
      debugPrint("Search profiles error: $e");
      return [];
    }
  }

  Future<List<ThreadPost>> searchThreads(
    String query, {
    String? communityId,
    List<String>? categories,
    String? timeframe,
    String? sortBy,
  }) async {
    final hasQuery = query.trim().isNotEmpty;
    final hasCategories = categories != null && categories.isNotEmpty;
    final hasTimeframe = timeframe != null && timeframe.isNotEmpty;
    
    if (!hasQuery && !hasCategories && !hasTimeframe) return [];
    
    try {
      dynamic dbQuery = _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), comments(profiles(avatar_url))');
          
      if (hasQuery) {
        dbQuery = dbQuery.ilike('content', '%$query%');
      }
      
      if (hasCategories) {
        // Match posts containing any of the selected category hashtags (case-insensitive)
        final orFilters = categories.map((c) => 'content.ilike.%#${c.trim()}%').join(',');
        dbQuery = dbQuery.or(orFilters);
      }
      
      if (hasTimeframe) {
        final now = DateTime.now().toUtc();
        DateTime? startDate;
        if (timeframe == 'Today') {
          startDate = now.subtract(const Duration(days: 1));
        } else if (timeframe == 'This Week') {
          startDate = now.subtract(const Duration(days: 7));
        } else if (timeframe == 'This Month') {
          startDate = now.subtract(const Duration(days: 30));
        }
        if (startDate != null) {
          dbQuery = dbQuery.gte('created_at', startDate.toIso8601String());
        }
      }
      
      if (communityId != null) {
        dbQuery = dbQuery.eq('community_id', communityId);
      }
      
      if (sortBy == 'Recent') {
        dbQuery = dbQuery.order('created_at', ascending: false);
      } else if (sortBy == 'Popular') {
        dbQuery = dbQuery.order('likes_count', ascending: false);
      } else {
        dbQuery = dbQuery.order('created_at', ascending: false);
      }
      
      final response = await dbQuery.limit(20);
 
      final List<dynamic> data = response as List<dynamic>;
      final List<ThreadPost> results = [];
      for (final json in data) {
        try {
          results.add(ThreadPost.fromJson(json, currentUid: _currentUid));
        } catch (e, stacktrace) {
          debugPrint('Error parsing thread post in searchThreads: $e\n$stacktrace');
        }
      }
      
      // Filter out blocked/muted users, private users we don't follow, and posts hidden from current user
      results.removeWhere((post) {
        if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
          return true;
        }
        if (post.isHiddenFromMe) {
          return true;
        }
        if (post.userId != _currentUid && post.author.isPrivate) {
          return !isFollowingUser(post.userId);
        }
        return false;
      });

      _updateCache(results);
      return results;
    } catch (e) {
      debugPrint("Search threads error: $e");
      return [];
    }
  }

  Future<List<Profile>> getRecommendedProfiles() async {
    if (_currentUid.isEmpty) return [];
    try {
      // Recommend newly created users, excluding oneself
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', _currentUid)
          .order('created_at', ascending: false)
          .limit(10);
      final List<dynamic> data = response as List<dynamic>;
      final List<Profile> results = data.map((json) => Profile.fromJson(json)).toList();
      
      // Filter out blocked profiles
      results.removeWhere((profile) => _blockedUserIds.contains(profile.id));
      return results;
    } catch (e) {
      debugPrint("Get recommended profiles error: $e");
      return [];
    }
  }

}
