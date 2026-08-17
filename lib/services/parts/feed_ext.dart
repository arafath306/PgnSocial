part of '../database_service.dart';

extension FeedExtension on DatabaseService {
  // --- Feed / Threads Operations ---

  Future<void> fetchFeed({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      updateState();
    }
    LogService.database("Fetching home feed threads (silent: $silent)...");

    final result = await sl<GetFeedUseCase>()(silent: silent);
    result.fold(
      (failure) {
        if (!silent) {
          _isLoading = false;
        }
        updateState();
        LogService.error("Fetching home feed failed: ${failure.message}", tag: "DATABASE");
      },
      (entities) {
        _feed = entities.map((e) => _entityToModel(e)).toList();
        _feed.removeWhere((p) => p.author.isShadowbanned && p.author.id != _currentUid);
        _updateCache(_feed);
        LogService.database("Home feed loaded: ${_feed.length} threads fetched.");
        if (!silent) {
          _isLoading = false;
        }
        updateState();
      },
    );
  }

  Future<void> fetchMyThreads() async {
    if (_currentUid.isEmpty) return;
    final result = await sl<IFeedRepository>().fetchMyThreads();
    result.fold(
      (failure) => debugPrint("Fetch my threads error: ${failure.message}"),
      (entities) {
        _myThreads = entities.map((e) => _entityToModel(e)).toList();
        // No need to filter shadowbanned here since it's the user's own profile/threads
        _updateCache(_myThreads);
        updateState();
      },
    );
  }

  Future<bool> createThread(
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    String? audience,
    List<String>? pollOptions,
    Duration? pollDuration,
    String? communityId,
    bool isSubscriberOnly = false,
    bool isAnonymous = false,
  }) async {
    LogService.info("Attempting to create thread. Anonymous: $isAnonymous, Subscriber Only: $isSubscriberOnly, Images: ${imageUrls?.length ?? 0}");
    final now = DateTime.now();
    if (_lastPostTime != null) {
      final difference = now.difference(_lastPostTime!);
      if (difference < DatabaseService._cooldownDuration) {
        throw Exception("Please wait ${(DatabaseService._cooldownDuration - difference).inSeconds + 1}s before posting again.");
      }
    }
    _lastPostTime = now;
    DateTime? pollExpiresAt;
    if (pollDuration != null) {
      pollExpiresAt = DateTime.now().add(pollDuration);
    }
    final result = await sl<CreateThreadUseCase>()(
      content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      audience: audience,
      pollOptions: pollOptions,
      pollExpiresAt: pollExpiresAt,
      communityId: communityId,
      isSubscriberOnly: isSubscriberOnly,
      isAnonymous: isAnonymous,
    );
    return result.fold(
      (failure) {
        LogService.error("Thread creation failed: ${failure.message}");
        return false;
      },
      (success) async {
        LogService.info("Thread created successfully! Refreshing feed.");
        try {
          FirebaseAnalytics.instance.logEvent(
            name: 'post_create',
            parameters: {
              'has_images': (imageUrls?.isNotEmpty ?? false).toString(),
              'has_video': (videoUrl != null).toString(),
              'is_subscriber_only': isSubscriberOnly.toString(),
            },
          );
        } catch (e) {
          debugPrint('Error logging analytics event: $e');
        }
        await fetchFeed(silent: true);
        await fetchAIFeed(silent: true);
        await fetchMyThreads();
        return success;
      },
    );
  }


  Future<void> votePoll(String threadId, String optionId) async {
    if (_currentUid.isEmpty) return;
    
    // Play haptic/pop sound
    sl<PlaySoundUseCase>().call(SoundType.pop);

    // Optimistically update local state so the transition is instant
    final cached = _postsCache[threadId];
    if (cached != null && !cached.hasVotedPoll && !cached.isPollExpired) {
      // Find the option and increment its vote count
      final updatedOptions = cached.pollOptions?.map((opt) {
        if (opt.id == optionId) {
          return opt.copyWith(votesCount: opt.votesCount + 1);
        }
        return opt;
      }).toList();
      
      final updatedPost = cached.copyWith(
        hasVotedPoll: true,
        votedOptionId: optionId,
        pollOptions: updatedOptions,
      );
      
      _postsCache[threadId] = updatedPost;
      
      void updateInList(List<ThreadPost> list) {
        final idx = list.indexWhere((p) => p.id == threadId);
        if (idx != -1) {
          list[idx] = updatedPost;
        }
      }
      updateInList(_feed);
      updateInList(_myThreads);
      updateInList(_personalizedFeed);
      updateInList(_savedPosts);
      
      updateState();
    }

    try {
      await _supabase.from('poll_votes').insert({
        'user_id': _currentUid,
        'thread_id': threadId,
        'poll_option_id': optionId,
      });
      
      logUserInteraction(threadId, 'vote');
    } catch (e) {
      debugPrint('Error casting vote: $e');
      // Rollback on failure
      await _reloadThread(threadId);
    }
  }

}
