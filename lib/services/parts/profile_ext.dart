part of '../database_service.dart';

extension ProfileExtension on DatabaseService {
  // --- Profile Operations ---

  Future<Profile?> fetchProfile(String userId) async {
    if (userId.startsWith('mock-')) {
      if (userId == 'mock-tamim') {
        return Profile(
          id: 'mock-tamim',
          username: 'tamim_hossain',
          fullName: 'Tamim Hossain',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&fit=crop',
          bio: 'Tech enthusiast, developer, and open-source contributor from Dhaka.',
          followersCount: 1200,
          followingCount: 340,
        );
      } else if (userId == 'mock-nusrat') {
        return Profile(
          id: 'mock-nusrat',
          username: 'nusrat.jahan',
          fullName: 'Nusrat Jahan',
          avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&fit=crop',
          bio: 'Designer, photographer, and travel enthusiast. Capturing life one frame at a time.',
          followersCount: 2500,
          followingCount: 890,
        );
      } else if (userId == 'mock-mehedi') {
        return Profile(
          id: 'mock-mehedi',
          username: 'mehedi.hasan',
          fullName: 'Mehedi Hasan',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&fit=crop',
          bio: 'Digital content creator, explorer, and coffee lover.',
          followersCount: 950,
          followingCount: 150,
        );
      }
    }
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = Profile.fromJson(response);
        if (userId == _currentUid) {
          _myProfile = profile;
          _saveProfileToCache(profile);
          updateState();
        }
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint("Fetch profile error: $e");
      return null;
    }
  }

  /// Fetches a single thread by ID. Used for notification tap navigation.
  Future<ThreadPost?> fetchSingleThread(String threadId) async {
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
          .eq('id', threadId)
          .maybeSingle();
      if (response == null) return null;
      return ThreadPost.fromJson(response, currentUid: _currentUid);
    } catch (e) {
      debugPrint('fetchSingleThread error: $e');
      return null;
    }
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('cached_profile_$_currentUid');
      if (cachedJson != null) {
        final decodedMap = jsonDecode(cachedJson) as Map<String, dynamic>;
        _myProfile = Profile.fromJson(decodedMap);
        updateState();
      }
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
    }
  }

  Future<void> _saveProfileToCache(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_profile_$_currentUid', jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Error saving profile to cache: $e');
    }
  }

  Future<void> fetchMyProfile() async {
    if (_currentUid.isEmpty) return;
    final result = await fetchProfile(_currentUid);
    if (result != null) {
      _myProfile = result;
      await _saveProfileToCache(result);
      _checkBadgeExpiration();
      updateState();
    }
  }

  void _checkBadgeExpiration() {
    if (_myProfile?.isVerified == true && _myProfile?.verifiedExpiresAt != null) {
      final expiresAt = _myProfile!.verifiedExpiresAt!;
      final now = DateTime.now();
      final diff = expiresAt.difference(now);
      
      // If within 12 hours of expiration and not already expired
      if (diff.inHours <= 12 && diff.isNegative == false) {
        sl<ShowNotificationUseCase>().call(
          type: NotificationType.generic,
          id: 9999,
          title: 'Badge Expiring Soon',
          body: 'Your Pigeon Blue Badge expires in ${diff.inHours} hours. Tap to renew!',
          payload: 'badge_renewal',
        );
      }
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String bio,
    required String phone,
    required String country,
    String? division,
    String? city,
    String? village,
    String? zip,
    String? gender,
    String? birthdate,
  }) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    updateState();

    try {
      final res = await sl<UpdateProfileUseCase>().call(
        fullName: fullName,
        username: username,
        bio: bio,
        phone: phone,
        country: country,
        division: division,
        city: city,
        village: village,
        zip: zip,
        gender: gender,
        birthdate: birthdate,
      );

      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
      }
      _isLoading = false;
      updateState();
      return success;
    } catch (e) {
      _isLoading = false;
      updateState();
      debugPrint("Update profile error: $e");
      return false;
    }
  }



}
