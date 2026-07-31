import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/media_compressor.dart';
import '../models/community.dart';
import '../models/community_rule.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';

class CommunityService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Community> joinedCommunities = [];
  List<Community> recommendedCommunities = [];
  List<String> recentSearches = [];
  bool isLoadingJoined = false;
  bool isLoadingRecommended = false;
  
  String? get _currentUid => _supabase.auth.currentUser?.id;

  Future<void> fetchJoinedCommunities() async {
    if (_currentUid == null) return;
    isLoadingJoined = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('community_members')
          .select('role, communities(*)')
          .eq('user_id', _currentUid!)
          .order('joined_at', ascending: false);

      final List<Community> loaded = [];
      for (var row in response) {
        if (row['communities'] != null) {
          final communityMap = row['communities'] as Map<String, dynamic>;
          loaded.add(Community.fromJson(communityMap, myRole: row['role'] as String?));
        }
      }
      joinedCommunities = loaded;
    } catch (e) {
      debugPrint("Error fetching joined communities: $e");
    } finally {
      isLoadingJoined = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecommendedCommunities() async {
    if (_currentUid == null) return;
    isLoadingRecommended = true;
    notifyListeners();

    try {
      // Fetch joined community IDs directly from community_members table
      final joinedRes = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', _currentUid!);

      final Set<String> joinedIds = (joinedRes as List)
          .map((row) => row['community_id'].toString())
          .toSet();

      // Also include any IDs from in-memory joinedCommunities list
      joinedIds.addAll(joinedCommunities.map((c) => c.id));

      final response = await _supabase
          .from('communities')
          .select('*')
          .eq('privacy', 'public')
          .order('member_count', ascending: false)
          .limit(30);

      final List<Community> loaded = [];
      for (var row in response) {
        final c = Community.fromJson(row);
        if (!joinedIds.contains(c.id)) {
          loaded.add(c);
        }
      }
      recommendedCommunities = loaded;
    } catch (e) {
      debugPrint("Error fetching recommended communities: $e");
    } finally {
      isLoadingRecommended = false;
      notifyListeners();
    }
  }

  Future<void> refreshAllCommunities() async {
    await fetchJoinedCommunities();
    await fetchRecommendedCommunities();
  }

  Future<Community?> getCommunityDetails(String communityId) async {
    try {
      final response = await _supabase
          .from('communities')
          .select('*')
          .eq('id', communityId)
          .single();
          
      // Check user role
      String? role;
      if (_currentUid != null) {
        final roleResp = await _supabase
            .from('community_members')
            .select('role')
            .eq('community_id', communityId)
            .eq('user_id', _currentUid!)
            .maybeSingle();
        if (roleResp != null) {
          role = roleResp['role'] as String?;
        }
      }
      
      return Community.fromJson(response, myRole: role);
    } catch (e) {
      debugPrint("Error fetching community details: $e");
      return null;
    }
  }

  Future<List<CommunityRule>> fetchCommunityRules(String communityId) async {
    try {
      final response = await _supabase
          .from('community_rules')
          .select('*')
          .eq('community_id', communityId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((row) => CommunityRule.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error fetching community rules: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCommunityMembers(String communityId) async {
    try {
      // Return list of maps with profile and role
      final response = await _supabase
          .from('community_members')
          .select('role, joined_at, profiles!user_id(*)')
          .eq('community_id', communityId)
          .order('joined_at', ascending: false);
      
      List<Map<String, dynamic>> members = [];
      for (var row in response) {
        if (row['profiles'] != null) {
          members.add({
            'profile': Profile.fromJson(row['profiles'] as Map<String, dynamic>),
            'role': row['role'],
            'joined_at': row['joined_at'],
          });
        }
      }
      return members;
    } catch (e) {
      debugPrint("Error fetching community members: $e");
      return [];
    }
  }

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches = prefs.getStringList('community_recent_searches') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading recent searches: $e");
    }
  }

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > 10) {
        recentSearches = recentSearches.sublist(0, 10);
      }
      await prefs.setStringList('community_recent_searches', recentSearches);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding recent search: $e");
    }
  }
  
  Future<void> removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches.remove(query);
      await prefs.setStringList('community_recent_searches', recentSearches);
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing recent search: $e");
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('community_recent_searches');
      recentSearches = [];
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing recent searches: $e");
    }
  }

  Future<List<Community>> searchCommunities(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _supabase
          .from('communities')
          .select('*')
          .ilike('name', '%$query%')
          .order('member_count', ascending: false)
          .limit(20);

      return (response as List<dynamic>)
          .map((row) => Community.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error searching communities: $e");
      return [];
    }
  }

  Future<bool> joinCommunity(String communityId) async {
    if (_currentUid == null) return false;
    try {
      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': _currentUid!,
        'role': 'member',
      });
      // Increment count
      await _supabase.rpc('increment_community_member_count', params: {'c_id': communityId});
      
      await Future.wait([
        fetchJoinedCommunities(),
        fetchRecommendedCommunities(),
      ]);
      return true;
    } catch (e) {
      debugPrint("Error joining community: $e");
      return false;
    }
  }

  Future<bool> leaveCommunity(String communityId) async {
    if (_currentUid == null) return false;
    try {
      await _supabase
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', _currentUid!);
          
      // Decrement count
      await _supabase.rpc('decrement_community_member_count', params: {'c_id': communityId});
      
      await Future.wait([
        fetchJoinedCommunities(),
        fetchRecommendedCommunities(),
      ]);
      return true;
    } catch (e) {
      debugPrint("Error leaving community: $e");
      return false;
    }
  }

  Future<String?> createCommunity({
    required String name,
    required String handle,
    required String topic,
    String? description,
    required String privacy,
    File? avatarFile,
    File? bannerFile,
  }) async {
    if (_currentUid == null) return null;
    
    try {
      String? avatarUrl;
      String? bannerUrl;

      // Upload files if present
      if (avatarFile != null) {
        final compressed = await MediaCompressor.compressImageFile(avatarFile);
        final ext = compressed.path.split('.').last;
        final fileName = 'c_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('avatars').upload(fileName, compressed);
        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      if (bannerFile != null) {
        final compressed = await MediaCompressor.compressImageFile(bannerFile);
        final ext = compressed.path.split('.').last;
        final fileName = 'c_banner_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('avatars').upload('covers/$fileName', compressed);
        bannerUrl = _supabase.storage.from('avatars').getPublicUrl('covers/$fileName');
      }

      final res = await _supabase.from('communities').insert({
        'name': name,
        'handle': handle,
        'topic': topic,
        'description': description,
        'privacy': privacy,
        'avatar_url': avatarUrl,
        'banner_url': bannerUrl,
        'owner_id': _currentUid!,
        'member_count': 1, // Owner is the first member
      }).select('id').single();

      final newId = res['id'] as String;

      // Add owner to members
      await _supabase.from('community_members').insert({
        'community_id': newId,
        'user_id': _currentUid!,
        'role': 'owner',
      });

      await fetchJoinedCommunities();
      return newId;
    } catch (e) {
      debugPrint("Error creating community: $e");
      return null;
    }
  }

  Future<bool> isHandleAvailable(String handle) async {
    if (handle.isEmpty) return false;
    try {
      final res = await _supabase
          .from('communities')
          .select('id')
          .eq('handle', handle)
          .maybeSingle();
      return res == null;
    } catch (e) {
      debugPrint("Error checking handle availability: $e");
      return false; // Safest to assume it's unavailable if error
    }
  }

  Future<bool> addCommunityRule(String communityId, String title, String description) async {
    try {
      await _supabase.from('community_rules').insert({
        'community_id': communityId,
        'title': title,
        'description': description,
      });
      return true;
    } catch (e) {
      debugPrint("Error adding community rule: $e");
      return false;
    }
  }

  Future<bool> updateCommunityRule(String ruleId, String title, String description) async {
    try {
      await _supabase.from('community_rules').update({
        'title': title,
        'description': description,
      }).eq('id', ruleId);
      return true;
    } catch (e) {
      debugPrint("Error updating community rule: $e");
      return false;
    }
  }

  Future<bool> deleteCommunityRule(String ruleId) async {
    try {
      await _supabase.from('community_rules').delete().eq('id', ruleId);
      return true;
    } catch (e) {
      debugPrint("Error deleting community rule: $e");
      return false;
    }
  }

  Future<bool> updateCommunity({
    required String id,
    required String name,
    required String description,
    required String privacy,
    File? avatarFile,
    File? bannerFile,
  }) async {
    if (_currentUid == null) return false;
    
    try {
      String? avatarUrl;
      String? bannerUrl;

      if (avatarFile != null) {
        final compressed = await MediaCompressor.compressImageFile(avatarFile);
        final ext = compressed.path.split('.').last;
        final fileName = 'c_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('avatars').upload(fileName, compressed);
        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      if (bannerFile != null) {
        final compressed = await MediaCompressor.compressImageFile(bannerFile);
        final ext = compressed.path.split('.').last;
        final fileName = 'c_banner_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('avatars').upload('covers/$fileName', compressed);
        bannerUrl = _supabase.storage.from('avatars').getPublicUrl('covers/$fileName');
      }

      final Map<String, dynamic> updates = {
        'name': name,
        'description': description,
        'privacy': privacy,
      };

      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bannerUrl != null) updates['banner_url'] = bannerUrl;

      await _supabase.from('communities').update(updates).eq('id', id);
      await fetchJoinedCommunities();
      return true;
    } catch (e) {
      debugPrint("Error updating community: $e");
      return false;
    }
  }


  Future<bool> updateCommunityAvatar(String id, File avatarFile) async {
    if (_currentUid == null) return false;
    try {
      final compressed = await MediaCompressor.compressImageFile(avatarFile);
      final ext = compressed.path.split('.').last;
      final fileName = 'c_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from('avatars').upload(fileName, compressed);
      final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      await _supabase.from('communities').update({'avatar_url': avatarUrl}).eq('id', id);
      await fetchJoinedCommunities();
      return true;
    } catch (e) {
      debugPrint("Error updating community avatar: $e");
      return false;
    }
  }


  Future<bool> deleteCommunity(String id) async {
    if (_currentUid == null) return false;
    try {
      await _supabase.from('communities').delete().eq('id', id).eq('owner_id', _currentUid!);
      await fetchJoinedCommunities();
      return true;
    } catch (e) {
      debugPrint("Error deleting community: $e");
      return false;
    }
  }

  Future<bool> updateMemberRole(String communityId, String userId, String role) async {
    try {
      await _supabase
          .from('community_members')
          .update({'role': role})
          .eq('community_id', communityId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint("Error updating member role: $e");
      return false;
    }
  }

  Future<bool> removeMember(String communityId, String userId) async {
    try {
      await _supabase
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);
      
      // Update member count
      final res = await _supabase.from('communities').select('member_count').eq('id', communityId).single();
      final count = (res['member_count'] as int) - 1;
      await _supabase.from('communities').update({'member_count': count}).eq('id', communityId);
      
      return true;
    } catch (e) {
      debugPrint("Error removing member: $e");
      return false;
    }
  }

  Future<List<ThreadPost>> fetchCommunityPosts(String communityId) async {
    try {
      final response = await _supabase
          .from('threads')
          .select('''
            *,
            profiles!user_id(*),
            likes(user_id),
            thread_hides(user_id),
            poll_options(*),
            poll_votes(*)
          ''')
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .limit(30);

      final List<ThreadPost> posts = [];
      for (var row in response) {
        final post = ThreadPost.fromJson(row, currentUid: _currentUid);
        if (post.author.isShadowbanned && post.userId != _currentUid) {
          continue;
        }
        posts.add(post);
      }
      return posts;
    } catch (e) {
      debugPrint("Error fetching community posts: $e");
      return [];
    }
  }
}
