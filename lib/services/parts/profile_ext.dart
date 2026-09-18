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
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*), comments(profiles(avatar_url))')
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
    String? education,
    String? bloodGroup,
    String? occupation,
    String? website,
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
        education: education,
        bloodGroup: bloodGroup,
        occupation: occupation,
        website: website,
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

  Future<bool> deactivateAccount(Duration duration) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    updateState();

    try {
      final deactivatedUntil = DateTime.now().add(duration);
      
      await _supabase.from('profiles').update({
        'deactivated_until': deactivatedUntil.toUtc().toIso8601String(),
      }).eq('id', _currentUid);

      _isLoading = false;
      updateState();
      return true;
    } catch (e) {
      debugPrint("Deactivate account error: $e");
      _isLoading = false;
      updateState();
      return false;
    }
  }

  // --- Experience & Education Operations (LinkedIn & Life Event) ---

  Future<List<UserExperience>> fetchUserExperiences(String userId) async {
    try {
      final res = await sl<IProfileRepository>().fetchUserExperiences(userId);
      return res.fold(
        (failure) {
          debugPrint("Failed to fetch experiences: ${failure.message}");
          return [];
        },
        (data) {
          final list = data.map((e) => UserExperience.fromJson(e)).toList();
          if (userId == _currentUid) {
            _myExperiences = list;
          } else {
            _userExperiencesCache[userId] = list;
          }
          updateState();
          return list;
        },
      );
    } catch (e) {
      debugPrint("Error fetching experiences: $e");
      return [];
    }
  }

  Future<bool> saveUserExperience(
    UserExperience exp, {
    bool shareAsMilestone = false,
    String? milestoneNote,
  }) async {
    try {
      final repo = sl<IProfileRepository>();
      final isNew = exp.id.isEmpty;
      final data = Map<String, dynamic>.from(exp.toJson());
      data['user_id'] = _currentUid;
      if (isNew) data.remove('id');

      final res = await repo.saveUserExperience(data, id: isNew ? null : exp.id);
      return await res.fold(
        (failure) {
          debugPrint("Failed to save experience: ${failure.message}");
          return false;
        },
        (savedData) async {
          final savedExp = UserExperience.fromJson(savedData);
          await fetchUserExperiences(_currentUid);

          // If this is user's current role, auto-sync profiles.occupation headline
          if (savedExp.isCurrent) {
            try {
              final headline = '${savedExp.title} at ${savedExp.company}';
              await _supabase.from('profiles').update({'occupation': headline}).eq('id', _currentUid);
              await fetchMyProfile();
            } catch (_) {}
          }

          // Optional: Share milestone as celebratory Life Event post
          if (shareAsMilestone) {
            final lifeEvent = LifeEvent(
              type: 'work',
              title: savedExp.title,
              organization: savedExp.company,
              subtitle: '${savedExp.employmentType} · ${savedExp.locationType}',
              startDate: savedExp.startDate,
              endDate: savedExp.endDate,
              isCurrent: savedExp.isCurrent,
              location: savedExp.location,
              employmentType: savedExp.employmentType,
              customNote: milestoneNote,
            );

            final caption = (milestoneNote != null && milestoneNote.trim().isNotEmpty)
                ? milestoneNote.trim()
                : "I'm excited to share that I'm starting a new position as ${savedExp.title} at ${savedExp.company}! 🎉";

            final fullContent = '$caption\n\n🎉DakLifeEvent🎉${lifeEvent.toJson()}';
            await createThread(fullContent);
          }

          updateState();
          return true;
        },
      );
    } catch (e) {
      debugPrint("Error saving experience: $e");
      return false;
    }
  }

  Future<bool> deleteUserExperience(String experienceId) async {
    try {
      final res = await sl<IProfileRepository>().deleteUserExperience(experienceId);
      return res.fold(
        (failure) => false,
        (success) {
          _myExperiences.removeWhere((e) => e.id == experienceId);
          updateState();
          return true;
        },
      );
    } catch (e) {
      debugPrint("Error deleting experience: $e");
      return false;
    }
  }

  Future<List<UserEducation>> fetchUserEducations(String userId) async {
    try {
      final res = await sl<IProfileRepository>().fetchUserEducations(userId);
      return res.fold(
        (failure) {
          debugPrint("Failed to fetch educations: ${failure.message}");
          return [];
        },
        (data) {
          final list = data.map((e) => UserEducation.fromJson(e)).toList();
          if (userId == _currentUid) {
            _myEducations = list;
          } else {
            _userEducationsCache[userId] = list;
          }
          updateState();
          return list;
        },
      );
    } catch (e) {
      debugPrint("Error fetching educations: $e");
      return [];
    }
  }

  Future<bool> saveUserEducation(
    UserEducation edu, {
    bool shareAsMilestone = false,
    String? milestoneNote,
  }) async {
    try {
      final repo = sl<IProfileRepository>();
      final isNew = edu.id.isEmpty;
      final data = Map<String, dynamic>.from(edu.toJson());
      data['user_id'] = _currentUid;
      if (isNew) data.remove('id');

      final res = await repo.saveUserEducation(data, id: isNew ? null : edu.id);
      return await res.fold(
        (failure) {
          debugPrint("Failed to save education: ${failure.message}");
          return false;
        },
        (savedData) async {
          final savedEdu = UserEducation.fromJson(savedData);
          await fetchUserEducations(_currentUid);

          // Auto-sync profiles.education headline
          try {
            final headline = savedEdu.degreeWithField.isNotEmpty
                ? '${savedEdu.degreeWithField}, ${savedEdu.school}'
                : savedEdu.school;
            await _supabase.from('profiles').update({'education': headline}).eq('id', _currentUid);
            await fetchMyProfile();
          } catch (_) {}

          // Optional: Share milestone as celebratory Life Event post
          if (shareAsMilestone) {
            final lifeEvent = LifeEvent(
              type: 'education',
              title: savedEdu.degreeWithField.isNotEmpty ? savedEdu.degreeWithField : savedEdu.school,
              organization: savedEdu.school,
              subtitle: savedEdu.degreeWithField,
              startDate: savedEdu.startDate,
              endDate: savedEdu.endDate,
              isCurrent: savedEdu.isCurrent,
              customNote: milestoneNote,
            );

            final caption = (milestoneNote != null && milestoneNote.trim().isNotEmpty)
                ? milestoneNote.trim()
                : (savedEdu.isCurrent
                    ? "Excited to share that I've started studying at ${savedEdu.school}! 🎓"
                    : "Proud to share that I have graduated from ${savedEdu.school}! 🎓");

            final fullContent = '$caption\n\n🎉DakLifeEvent🎉${lifeEvent.toJson()}';
            await createThread(fullContent);
          }

          updateState();
          return true;
        },
      );
    } catch (e) {
      debugPrint("Error saving education: $e");
      return false;
    }
  }

  Future<bool> deleteUserEducation(String educationId) async {
    try {
      final res = await sl<IProfileRepository>().deleteUserEducation(educationId);
      return res.fold(
        (failure) => false,
        (success) {
          _myEducations.removeWhere((e) => e.id == educationId);
          updateState();
          return true;
        },
      );
    } catch (e) {
      debugPrint("Error deleting education: $e");
      return false;
    }
  }
}
