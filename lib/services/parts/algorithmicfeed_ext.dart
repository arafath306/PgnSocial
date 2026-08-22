part of '../database_service.dart';

extension AlgorithmicFeedExtension on DatabaseService {
  // --- Algorithmic Personalized Feed Operations ---

  Future<void> fetchAIFeed({bool silent = false, int limit = 15, bool loadMore = false}) async {
    if (_currentUid.isEmpty) return;
    if (loadMore && !_aiFeedHasMore) return;

    if (!loadMore) {
      _aiFeedPage = 0;
      _aiFeedHasMore = true;
    }

    if (!silent && !loadMore) {
      _isLoading = true;
      updateState();
    }

    final offset = _aiFeedPage * limit;
    final List<ThreadPost> fetchedPosts = [];

    try {
      final response = await _supabase.rpc(
        'get_personalized_feed',
        params: {
          'p_user_id': _currentUid,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>;

      if (data.isNotEmpty) {
        final List<String> threadIds = data.map((json) => json['id'] as String).toList();
        
        final threadsRes = await _supabase
            .from('threads')
            .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*), comments(profiles(avatar_url))')
            .inFilter('id', threadIds);

        final List<dynamic> threadsData = threadsRes as List<dynamic>;
        final List<ThreadPost> posts = [];
        for (final json in threadsData) {
          try {
            posts.add(ThreadPost.fromJson(json, currentUid: _currentUid));
          } catch (e, stacktrace) {
            debugPrint('Error parsing thread post in get_personalized_feed: $e\\n$stacktrace');
          }
        }
        
        final generalSettings = sl<GeneralSettingsProvider>();
        if (generalSettings.isAlgorithmicPriorityEnabled) {
          // Priority: Gold > Gray > Blue (Verified) > Unverified
          int getPriority(ThreadPost p) {
            if (p.author.badgeType == 'gold') return 3;
            if (p.author.badgeType == 'gray') return 2;
            if (p.author.isVerified) return 1;
            return 0;
          }
          posts.sort((a, b) {
            int pA = getPriority(a);
            int pB = getPriority(b);
            if (pA != pB) return pB.compareTo(pA); // higher priority first
            return threadIds.indexOf(a.id).compareTo(threadIds.indexOf(b.id));
          });
        } else {
          // Sort posts back into the ranked order returned by get_personalized_feed
          posts.sort((a, b) => threadIds.indexOf(a.id).compareTo(threadIds.indexOf(b.id)));
        }
        fetchedPosts.addAll(posts);
      }

      // Also fetch reposts from users we follow so they appear in the "For You" feed
      if (!loadMore) {
        try {
          final repostsRes = await _supabase
              .from('reposts')
              .select('*, profiles!user_id(*), threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*), comments(profiles(avatar_url)))' )
              .order('created_at', ascending: false)
              .limit(20);

          final List<dynamic> repostsData = repostsRes as List<dynamic>;
          for (final repost in repostsData) {
            if (repost['threads'] != null) {
              final threadMap = repost['threads'] as Map<String, dynamic>;
              final reposterProfileMap = repost['profiles'] as Map<String, dynamic>?;
              final reposterProfile = reposterProfileMap != null
                  ? Profile.fromJson(reposterProfileMap)
                  : Profile(id: repost['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

              final originalPost = ThreadPost.fromJson(threadMap, currentUid: _currentUid);
              final repostPost = ThreadPost(
                id: repost['id'] as String,
                userId: repost['user_id'] as String,
                author: reposterProfile,
                content: repost['quote_text'] as String? ?? '',
                createdAt: ThreadPost.formatRelativeTime(repost['created_at'] as String?),
                isRepost: true,
                repostedPost: originalPost,
                quoteText: repost['quote_text'] as String?,
                likesCount: 0,
                repliesCount: 0,
                repostsCount: 0,
                viewsCount: 0,
              );
              // Only add if not already in fetched posts
              if (!fetchedPosts.any((p) => p.id == repostPost.id)) {
                fetchedPosts.add(repostPost);
              }
            }
          }
        } catch (e) {
          debugPrint('Fetch reposts for AI feed error: $e');
        }
      }
    } catch (e) {
      debugPrint("Fetch personalized AI feed RPC error: $e. Falling back to direct fetch.");
    }

    // Fallback/Padding: If we couldn't load enough posts from RPC, fetch directly from threads to pad the feed
    if (fetchedPosts.length < limit) {
      
      try {
        var query = _supabase
            .from('threads')
            .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*), comments(profiles(avatar_url))');
            
        if (fetchedPosts.isNotEmpty) {
           final existingIds = fetchedPosts.map((p) => p.id).toList();
           // Avoid adding .not() on TransformBuilder. Just filter existingIds in memory later
           // Fetch a bit extra in case of overlaps
           final response = await query
               .order('created_at', ascending: false)
               .limit(limit + fetchedPosts.length);
               
           final List<dynamic> threadsData = response as List<dynamic>;
           for (final json in threadsData) {
             try {
               final post = ThreadPost.fromJson(json, currentUid: _currentUid);
               if (!existingIds.contains(post.id) && fetchedPosts.length < limit) {
                 fetchedPosts.add(post);
               }
             } catch (e, stacktrace) {
               debugPrint('Error parsing thread post in fallback: $e\\n$stacktrace');
             }
           }
        } else {
           // Normal paginated fetch
           final response = await query
               .order('created_at', ascending: false)
               .limit(limit)
               .range(offset, offset + limit - 1);
               
           final List<dynamic> threadsData = response as List<dynamic>;
           for (final json in threadsData) {
             try {
               fetchedPosts.add(ThreadPost.fromJson(json, currentUid: _currentUid));
             } catch (e, stacktrace) {
               debugPrint('Error parsing thread post in fallback: $e\\n$stacktrace');
             }
           }
        }
      } catch (fallbackError) {
        debugPrint("AI Feed fallback direct query failed: $fallbackError");
      }
    }

    // Apply privacy/mute/block filters
    fetchedPosts.removeWhere((post) {
      if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
        return true;
      }
      if (post.isHiddenFromMe) {
        return true;
      }
      if (post.author.isShadowbanned && post.userId != _currentUid) {
        return true;
      }
      if (post.userId != _currentUid && post.author.isPrivate) {
        return !isFollowingUser(post.userId);
      }
      return false;
    });

    if (loadMore) {
      final existingIds = _personalizedFeed.map((p) => p.id).toSet();
      fetchedPosts.removeWhere((p) => existingIds.contains(p.id));
      _personalizedFeed.addAll(fetchedPosts);
    } else {
      _personalizedFeed = fetchedPosts;
    }

    _updateCache(fetchedPosts);

    // Save to offline cache if this was the main fetch (not loadMore)
    if (!loadMore) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String jsonString = jsonEncode(_personalizedFeed.take(30).map((e) => e.toJson()).toList());
        await prefs.setString('cached_ai_feed_$_currentUid', jsonString);
      } catch (e) {
        debugPrint('Error saving cached feed: $e');
      }
    }

    if (fetchedPosts.length < limit) {
      _aiFeedHasMore = false;
    } else {
      _aiFeedPage++;
    }

    if (!silent && !loadMore) {
      _isLoading = false;
    }
    updateState();
  }

  Future<void> logUserInteraction(String threadId, String type, {int duration = 0}) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase.rpc('log_user_interaction', params: {
        'p_user_id': _currentUid,
        'p_thread_id': threadId,
        'p_type': type,
        'p_duration': duration,
      });
    } catch (e) {
      debugPrint('Log user interaction error: $e');
    }
  }

}
