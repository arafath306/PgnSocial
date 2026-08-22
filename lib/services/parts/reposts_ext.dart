part of '../database_service.dart';

extension RepostsExtension on DatabaseService {
  // --- Reposts Operation ---

  Future<bool> repostThread(String threadId, {String? quoteText}) async {
    if (_currentUid.isEmpty) return false;

    final now = DateTime.now();
    if (_lastPostTime != null) {
      final difference = now.difference(_lastPostTime!);
      if (difference < DatabaseService._cooldownDuration) {
        throw Exception("Please wait ${(DatabaseService._cooldownDuration - difference).inSeconds + 1}s before posting again.");
      }
    }
    _lastPostTime = now;

    final wasReposted = _repostedThreadIds.contains(threadId);

    // Optimistic toggle for simple reposts (quoteText == null)
    if (quoteText == null) {
      if (wasReposted) {
        _repostedThreadIds.remove(threadId);
      } else {
        _repostedThreadIds.add(threadId);
      }

      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        final delta = wasReposted ? -1 : 1;
        _postsCache[threadId] = cached.copyWith(
          repostsCount: (cached.repostsCount + delta).clamp(0, 999999),
        );
      }

      void updatePostRepostsCount(List<ThreadPost> list) {
        final idx = list.indexWhere((p) => p.id == threadId);
        if (idx != -1) {
          final post = list[idx];
          final delta = wasReposted ? -1 : 1;
          list[idx] = post.copyWith(
            repostsCount: (post.repostsCount + delta).clamp(0, 999999),
          );
        }
      }
      updatePostRepostsCount(_feed);
      updatePostRepostsCount(_myThreads);
      updatePostRepostsCount(_personalizedFeed);
      updateState();
    }

    try {
      // Check if already reposted
      final existing = await _supabase
          .from('reposts')
          .select('id, quote_text')
          .eq('user_id', _currentUid)
          .eq('thread_id', threadId)
          .maybeSingle();

      if (existing != null && quoteText == null) {
        // Remove repost
        await _supabase
            .from('reposts')
            .delete()
            .eq('user_id', _currentUid)
            .eq('thread_id', threadId);
      } else if (existing != null && quoteText != null) {
        // Update quote repost
        await _supabase
            .from('reposts')
            .update({'quote_text': quoteText})
            .eq('user_id', _currentUid)
            .eq('thread_id', threadId);
      } else {
        // Create repost
        await _supabase.from('reposts').insert({
          'user_id': _currentUid,
          'thread_id': threadId,
          'quote_text': quoteText,
        });
      }
      fetchFeed(silent: true);
      fetchAIFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Repost thread error: $e");
      // Rollback optimistic update if simple repost failed
      if (quoteText == null) {
        if (wasReposted) {
          _repostedThreadIds.add(threadId);
        } else {
          _repostedThreadIds.remove(threadId);
        }

        final cached = _postsCache[threadId];
        if (cached != null) {
          final delta = wasReposted ? 1 : -1;
          _postsCache[threadId] = cached.copyWith(
            repostsCount: (cached.repostsCount + delta).clamp(0, 999999),
          );
        }

        void updatePostRepostsCount(List<ThreadPost> list) {
          final idx = list.indexWhere((p) => p.id == threadId);
          if (idx != -1) {
            final post = list[idx];
            final delta = wasReposted ? 1 : -1;
            list[idx] = post.copyWith(
              repostsCount: (post.repostsCount + delta).clamp(0, 999999),
            );
          }
        }
        updatePostRepostsCount(_feed);
        updatePostRepostsCount(_myThreads);
        updatePostRepostsCount(_personalizedFeed);
        updateState();
      }
      return false;
    }
  }

  Future<bool> editRepost(String repostId, String newQuoteText) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase
          .from('reposts')
          .update({'quote_text': newQuoteText})
          .eq('id', repostId)
          .eq('user_id', _currentUid);
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Edit repost error: $e");
      return false;
    }
  }

  Future<bool> deleteRepost(String repostId, String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase
          .from('reposts')
          .delete()
          .eq('id', repostId)
          .eq('user_id', _currentUid);
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Delete repost error: $e");
      return false;
    }
  }

  Future<List<ThreadPost>> fetchUserReposts(String userId) async {
    try {
      final response = await _supabase
          .from('reposts')
          .select('*, profiles!user_id(*), threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id), comments(profiles(avatar_url)))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> repostsData = response as List<dynamic>;
      final List<ThreadPost> repostPosts = [];
      for (final row in repostsData) {
        final threadMap = row['threads'] as Map<String, dynamic>?;
        if (threadMap != null) {
          final post = ThreadPost.fromJson(threadMap, currentUid: _currentUid);
          if (post.author.isShadowbanned && post.userId != _currentUid) continue;
          final reposterProfileMap = row['profiles'] as Map<String, dynamic>?;
          final reposterProfile = reposterProfileMap != null
              ? Profile.fromJson(reposterProfileMap)
              : Profile(id: row['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

          final originalPost = ThreadPost.fromJson(threadMap, currentUid: _currentUid);

          repostPosts.add(ThreadPost(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            author: reposterProfile,
            content: row['quote_text'] as String? ?? '',
            createdAt: ThreadPost.formatRelativeTime(row['created_at'] as String?),
            isRepost: true,
            repostedPost: originalPost,
            quoteText: row['quote_text'] as String?,
            likesCount: 0,
            repliesCount: 0,
            repostsCount: 0,
            viewsCount: 0,
          ));
        }
      }
      return repostPosts;
    } catch (e) {
      debugPrint("Fetch user reposts error: $e");
      return [];
    }
  }

  Future<bool> reportPost(String threadId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'thread_id': threadId,
        'reason': reason,
      });
      logUserInteraction(threadId, 'report');
      return true;
    } catch (e) {
      debugPrint("Report post error: $e");
      return false;
    }
  }

  Future<bool> reportProfile(String targetProfileId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reason': 'Profile Report (@$targetProfileId): $reason',
      });
      return true;
    } catch (e) {
      debugPrint("Report profile error: $e");
      return false;
    }
  }

  Future<bool> reportCommunity(String communityId, String communityName, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reason': 'Community Report ($communityName, ID: $communityId): $reason',
      });
      return true;
    } catch (e) {
      debugPrint("Report community error: $e");
      return false;
    }
  }


  Future<bool> hideThreadForCurrentUser(String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('thread_hides').upsert({
        'thread_id': threadId,
        'user_id': _currentUid,
      });
      fetchFeed(silent: true);
      logUserInteraction(threadId, 'hide');
      return true;
    } catch (e) {
      debugPrint("Hide thread for current user error: $e");
      return false;
    }
  }

  Future<bool> unhideThreadForCurrentUser(String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase
          .from('thread_hides')
          .delete()
          .eq('thread_id', threadId)
          .eq('user_id', _currentUid);
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Unhide thread for current user error: $e");
      return false;
    }
  }

  Future<bool> reportComment(String replyId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'comment_id': replyId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint("Report comment error (comment_id): $e");
      try {
        await _supabase.from('reports').insert({
          'user_id': _currentUid,
          'reply_id': replyId,
          'reason': reason,
        });
        return true;
      } catch (inner) {
        debugPrint("Report comment error (reply_id): $inner");
        return false;
      }
    }
  }


  Future<void> incrementThreadViews(String threadId) async {
    try {
      await _supabase.rpc('increment_thread_views', params: {'thread_id': threadId});
      logUserInteraction(threadId, 'click');
      
      // Update local cache views count optimistically
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          viewsCount: cached.viewsCount + 1,
        );
      }
    } catch (rpcError) {
      debugPrint("RPC increment_thread_views failed: $rpcError");
      try {
        final response = await _supabase.from('threads').select('views_count').eq('id', threadId).maybeSingle();
        if (response != null) {
          final int currentViews = response['views_count'] as int? ?? 0;
          await _supabase.from('threads').update({'views_count': currentViews + 1}).eq('id', threadId);
          
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(
              viewsCount: currentViews + 1,
            );
          }
        }
      } catch (e) {
        debugPrint("Direct update views count failed: $e");
      }
    }
  }

}
