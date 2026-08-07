part of '../database_service.dart';

extension FollowExtension on DatabaseService {
  // --- Follow Operations ---

  bool isFollowingUser(String targetUserId) {
    return _followingIds.contains(targetUserId);
  }

  Future<bool> doesUserFollowMe(String otherUserId) async {
    if (_currentUid.isEmpty) return false;
    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', otherUserId)
          .eq('following_id', _currentUid)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint("Check doesUserFollowMe error: $e");
      return false;
    }
  }

  Future<void> fetchFollowingList() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', _currentUid);
      final List<dynamic> data = response as List<dynamic>;
      _followingIds = data.map((json) => json['following_id'] as String).toSet();
      updateState();
    } catch (e) {
      debugPrint("Fetch following list error: $e");
    }
  }

  Future<void> toggleFollowUser(String targetUserId) async {
    if (_currentUid.isEmpty) return;
    try {
      final isCurrentlyFollowing = isFollowingUser(targetUserId);
      if (isCurrentlyFollowing) {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', _currentUid)
            .eq('following_id', targetUserId);
      } else {
        await _supabase.from('follows').insert({
          'follower_id': _currentUid,
          'following_id': targetUserId,
        });
      }
      await fetchFollowingList();
      await fetchMyProfile();
    } catch (e) {
      debugPrint("Toggle follow user error: $e");
    }
  }

  /// Fetch list of profiles who follow [userId]
  Future<List<Profile>> fetchUserFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('profiles!follower_id(id, username, full_name, avatar_url, bio, followers_count, following_count)')
          .eq('following_id', userId);
      final data = response as List<dynamic>;
      return data
          .map((row) => Profile.fromJson(row['profiles'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Fetch user followers error: $e");
      return [];
    }
  }

  /// Fetch list of profiles that [userId] follows
  Future<List<Profile>> fetchUserFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('profiles!following_id(id, username, full_name, avatar_url, bio, followers_count, following_count)')
          .eq('follower_id', userId);
      final data = response as List<dynamic>;
      return data
          .map((row) => Profile.fromJson(row['profiles'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Fetch user following error: $e");
      return [];
    }
  }

  /// Remove a follower (the [followerId] who follows the current user)
  Future<void> removeFollower(String followerId) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', _currentUid);
      await fetchMyProfile();
    } catch (e) {
      debugPrint("Remove follower error: $e");
    }
  }

  /// Report a user
  Future<bool> reportUser(String reportedUserId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reason': 'User Report (@$reportedUserId): $reason',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Report user error: $e");
      return false;
    }
  }

  Future<void> fetchBlockedMutedLists() async {
    if (_currentUid.isEmpty) return;
    try {
      final blockedRes = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', _currentUid);

      final blockedMeRes = await _supabase
          .from('blocks')
          .select('blocker_id')
          .eq('blocked_id', _currentUid);

      final mutedRes = await _supabase
          .from('mutes')
          .select('muted_id')
          .eq('muter_id', _currentUid);

      _blockedUserIds = {};
      _blockedByMeIds = {};
      for (var row in blockedRes) {
        final id = row['blocked_id'] as String;
        _blockedUserIds.add(id);
        _blockedByMeIds.add(id);
      }
      for (var row in blockedMeRes) {
        _blockedUserIds.add(row['blocker_id'] as String);
      }

      _mutedUserIds = {};
      for (var row in mutedRes) {
        _mutedUserIds.add(row['muted_id'] as String);
      }
      updateState();
    } catch (e) {
      debugPrint("Fetch blocked/muted lists error: $e");
    }
  }

  /// Fetch suggested profiles for the user to follow
  Future<List<Profile>> fetchSuggestedProfiles({int limit = 10}) async {
    try {
      final excludeId = _currentUid.isNotEmpty ? _currentUid : '00000000-0000-0000-0000-000000000000';
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', excludeId)
          .order('is_verified', ascending: false)
          .order('followers_count', ascending: false)
          .limit(25);

      final List<dynamic> data = response as List<dynamic>;

      final candidates = data
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .where((p) => !_followingIds.contains(p.id) && !_blockedUserIds.contains(p.id))
          .take(limit)
          .toList();

      return candidates;
    } catch (e) {
      debugPrint("Fetch suggested profiles error: $e");
      return [];
    }
  }
}
