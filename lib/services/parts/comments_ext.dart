part of '../database_service.dart';

extension CommentsExtension on DatabaseService {
  // --- Comment and Nested Replies Database CRUD ---

  Future<List<Map<String, dynamic>>> fetchComments(String threadId) async {
    final result = await sl<FetchCommentsUseCase>()(threadId);
    return result.fold(
      (failure) {
        debugPrint("Fetch comments error: ${failure.message}");
        return [];
      },
      (comments) => comments,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCommentReplies(String commentId) async {
    final result = await sl<IFeedRepository>().fetchCommentReplies(commentId);
    return result.fold(
      (failure) {
        debugPrint("Fetch comment replies error: ${failure.message}");
        return [];
      },
      (replies) => replies,
    );
  }

  Future<bool> addComment(String threadId, String content, {String? parentId, String? imageUrl, String? audioUrl}) async {
    if (audioUrl != null && audioUrl.isNotEmpty) {
      if (myProfile?.isPremium != true) {
        throw Exception("Voice comments are exclusively available for Premium members. Please upgrade your plan.");
      }
    }

    final now = DateTime.now();
    if (_lastCommentTime != null) {
      final difference = now.difference(_lastCommentTime!);
      if (difference < DatabaseService._cooldownDuration) {
        throw Exception("Please wait ${(DatabaseService._cooldownDuration - difference).inSeconds + 1}s before commenting again.");
      }
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isNotEmpty && _lastCommentContent == trimmedContent) {
      throw Exception("Duplicate comments are not allowed.");
    }

    _lastCommentTime = now;
    if (trimmedContent.isNotEmpty) {
      _lastCommentContent = trimmedContent;
    }
    final result = await sl<AddCommentUseCase>()(threadId, content, parentId: parentId, imageUrl: imageUrl, audioUrl: audioUrl);
    return result.fold(
      (failure) {
        debugPrint("Add comment error: ${failure.message}");
        return false;
      },
      (success) async {
        if (parentId == null) {
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(
              repliesCount: cached.repliesCount + 1,
            );
          }
        }
        await fetchFeed(silent: true);
        logUserInteraction(threadId, 'reply');
        return success;
      },
    );
  }

  Future<void> toggleSaveComment(String commentId) async {
    final wasAlreadySaved = _savedCommentIds.contains(commentId);
    if (wasAlreadySaved) {
      _savedCommentIds.remove(commentId);
      _savedComments.removeWhere((c) => c['id'] == commentId);
    } else {
      _savedCommentIds.add(commentId);
    }
    updateState();

    final result = await sl<IFeedRepository>().toggleSaveComment(commentId);
    result.fold(
      (failure) {
        debugPrint('Toggle save comment error: ${failure.message}');
        if (wasAlreadySaved) {
          _savedCommentIds.add(commentId);
        } else {
          _savedCommentIds.remove(commentId);
        }
        updateState();
      },
      (_) async {
        await fetchSavedComments();
      },
    );
  }

  Future<void> fetchSavedCommentIds() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_comments')
          .select('comment_id')
          .eq('user_id', _currentUid);
      final List<dynamic> data = response as List<dynamic>;
      _savedCommentIds = data.map((json) => json['comment_id'] as String).toSet();
      updateState();
    } catch (e) {
      debugPrint('Fetch saved comment ids error: $e');
    }
  }

  Future<void> fetchSavedComments() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_comments')
          .select('*, comments(*, profiles(*))')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);
          
      final List<dynamic> data = response as List<dynamic>;
      
      // Fetch user's comment likes for is_liked_by_me tracking
      Set<String> likedCommentIds = {};
      final likesRes = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', _currentUid);
      final List<dynamic> likesData = likesRes as List<dynamic>;
      likedCommentIds = likesData.map((l) => l['comment_id'] as String).toSet();

      final List<Map<String, dynamic>> comments = [];
      for (final row in data) {
        final commentMap = row['comments'] as Map<String, dynamic>?;
        if (commentMap != null) {
          final authorMap = commentMap['profiles'] as Map<String, dynamic>?;
          final author = authorMap != null 
              ? Profile.fromJson(authorMap) 
              : Profile(id: commentMap['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');
          
          comments.add({
            'id': commentMap['id'] as String,
            'thread_id': commentMap['thread_id'] as String,
            'author': author,
            'content': commentMap['content'] as String,
            'image_url': commentMap['image_url'] as String?,
            'audio_url': commentMap['audio_url'] as String?,
            'created_at': _getRelativeTime(DateTime.parse(commentMap['created_at'] as String)),
            'created_at_raw': commentMap['created_at'] as String,
            'likes_count': (commentMap['likes_count'] as int?) ?? 0,
            'saves_count': (commentMap['saves_count'] as int?) ?? 0,
            'shares_count': (commentMap['shares_count'] as int?) ?? 0,
            'replies_count': (commentMap['replies_count'] as int?) ?? 0,
            'parent_id': commentMap['parent_id'] as String?,
            'is_liked_by_me': likedCommentIds.contains(commentMap['id'] as String),
            'is_saved_by_me': true,
          });
        }
      }
      _savedComments = comments;
      _savedCommentIds = comments.map((c) => c['id'] as String).toSet();
      updateState();
    } catch (e) {
      debugPrint('Fetch saved comments error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSingleComment(String commentId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(*)')
          .eq('id', commentId)
          .single();
      final json = response;
      
      // Check if liked
      bool isLiked = false;
      if (_currentUid.isNotEmpty) {
        final likeRes = await _supabase
            .from('comment_likes')
            .select('comment_id')
            .eq('user_id', _currentUid)
            .eq('comment_id', commentId)
            .maybeSingle();
        isLiked = likeRes != null;
      }
      
      final authorMap = json['profiles'] as Map<String, dynamic>?;
      final author = authorMap != null 
          ? Profile.fromJson(authorMap) 
          : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

      return {
        'id': json['id'] as String,
        'author': author,
        'content': json['content'] as String,
        'image_url': json['image_url'] as String?,
        'audio_url': json['audio_url'] as String?,
        'created_at': _getRelativeTime(DateTime.parse(json['created_at'] as String)),
        'created_at_raw': json['created_at'] as String,
        'likes_count': (json['likes_count'] as int?) ?? 0,
        'saves_count': (json['saves_count'] as int?) ?? 0,
        'shares_count': (json['shares_count'] as int?) ?? 0,
        'replies_count': (json['replies_count'] as int?) ?? 0,
        'parent_id': json['parent_id'] as String?,
        'is_liked_by_me': isLiked,
        'is_saved_by_me': isCommentSaved(json['id'] as String),
      };
    } catch (e) {
      debugPrint("Fetch single comment error: $e");
      return null;
    }
  }

  Future<void> incrementCommentShareCount(String commentId) async {
    try {
      await _supabase.rpc('increment_comment_shares_count', params: {'c_id': commentId});
    } catch (e) {
      debugPrint("Error incrementing comment share count RPC: $e");
      // Fallback
      try {
        final currentRes = await _supabase.from('comments').select('shares_count').eq('id', commentId).single();
        final currentShares = (currentRes['shares_count'] as int?) ?? 0;
        await _supabase.from('comments').update({'shares_count': currentShares + 1}).eq('id', commentId);
      } catch (err) {
        debugPrint("Error manually updating comment shares count: $err");
      }
    }
  }

  Future<void> incrementShareCount(String threadId) async {
    try {
      await _supabase.rpc('increment_shares_count', params: {'thread_id': threadId});
      // Also update cached post if exists
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          sharesCount: cached.sharesCount + 1,
        );
        updateState();
      }
    } catch (e) {
      debugPrint("Error incrementing share count RPC: $e");
      // Fallback: manually update if RPC is missing
      try {
        final cached = _postsCache[threadId];
        if (cached != null) {
          final newShares = cached.sharesCount + 1;
          await _supabase.from('threads').update({'shares_count': newShares}).eq('id', threadId);
          _postsCache[threadId] = cached.copyWith(sharesCount: newShares);
          updateState();
        }
      } catch (err) {
        debugPrint("Error manually updating shares count: $err");
      }
    }
  }

  Future<void> toggleCommentLike(String commentId, bool shouldLike) async {
    final result = await sl<IFeedRepository>().toggleCommentLike(commentId, shouldLike);
    result.fold(
      (failure) => debugPrint("Toggle comment like error: ${failure.message}"),
      (_) => null,
    );
  }

  Future<bool> deleteComment(String commentId, String threadId, {String? parentId}) async {
    final result = await sl<IFeedRepository>().deleteComment(commentId);
    return result.fold(
      (failure) {
        debugPrint("Delete comment error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
          if (parentId == null) {
            final cached = _postsCache[threadId];
            if (cached != null) {
              _postsCache[threadId] = cached.copyWith(
                repliesCount: cached.repliesCount - 1 < 0 ? 0 : cached.repliesCount - 1,
              );
            }
          }
          fetchFeed(silent: true);
        }
        return success;
      },
    );
  }

  Future<bool> editComment(String commentId, String content) async {
    final result = await sl<IFeedRepository>().editComment(commentId, content);
    return result.fold(
      (failure) {
        debugPrint("Edit comment error: ${failure.message}");
        return false;
      },
      (success) => success,
    );
  }


}
