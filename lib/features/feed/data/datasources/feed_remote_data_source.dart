import 'package:supabase_flutter/supabase_flutter.dart' as sb;

abstract class FeedRemoteDataSource {
  Future<List<dynamic>> fetchFeedRaw();
  Future<List<dynamic>> fetchRepostsRaw();
  Future<List<dynamic>> fetchMyThreadsRaw(String userId);
  Future<List<dynamic>> fetchUserThreadsRaw(String userId);
  Future<List<dynamic>> fetchUserRepliedThreadsRaw(String userId);
  Future<List<dynamic>> fetchThreadReactorsRaw(String threadId);
  Future<bool> createThread(
    String userId,
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    String? audience,
    List<String>? pollOptions,
    DateTime? pollExpiresAt,
    String? communityId,
    bool isSubscriberOnly = false,
    bool isAnonymous = false,
  });
  Future<void> toggleLike(String userId, String threadId, bool shouldLike);
  Future<bool> togglePinPost(String threadId, bool isPinned);
  Future<bool> toggleMutePostNotifications(String threadId, bool mute);
  Future<bool> toggleHidePostFromProfile(String threadId, bool hide);

  // Comments operations
  Future<List<dynamic>> fetchCommentsRaw(String threadId);
  Future<List<dynamic>> fetchCommentLikesRaw(String userId);
  Future<List<dynamic>> fetchCommentRepliesRaw(String commentId);
  Future<bool> addComment(String userId, String threadId, String content, {String? parentId, String? imageUrl});
  Future<bool> toggleCommentLike(String userId, String commentId, bool isLiked);
  Future<bool> toggleSaveComment(String userId, String commentId, bool isAlreadySaved);
  Future<List<dynamic>> fetchSavedCommentIdsRaw(String userId);
  Future<List<dynamic>> fetchSavedCommentsRaw(String userId);
  Future<bool> deleteComment(String commentId);
  Future<bool> editComment(String commentId, String newContent);

  // Saved/Bookmarks operations
  Future<List<dynamic>> fetchSavedPostsRaw(String userId);
  Future<void> toggleSaveThread(String userId, String threadId, bool wasAlreadySaved);
  Future<List<dynamic>> fetchSavedThreadIdsRaw(String userId);
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final sb.SupabaseClient supabaseClient;

  FeedRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<dynamic>> fetchFeedRaw() async {
    final response = await supabaseClient
        .from('threads')
        .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
        .isFilter('community_id', null)
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchRepostsRaw() async {
    final response = await supabaseClient
        .from('reposts')
        .select('*, profiles!user_id(*), threads(*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*))')
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchMyThreadsRaw(String userId) async {
    final response = await supabaseClient
        .from('threads')
        .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchUserThreadsRaw(String userId) async {
    final response = await supabaseClient
        .from('threads')
        .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchUserRepliedThreadsRaw(String userId) async {
    final commentsRes = await supabaseClient
        .from('comments')
        .select('thread_id')
        .eq('user_id', userId);
    final List<dynamic> commentsData = commentsRes as List<dynamic>;
    final threadIds = commentsData.map((c) => c['thread_id'] as String).toSet().toList();

    if (threadIds.isEmpty) return [];

    final response = await supabaseClient
        .from('threads')
        .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
        .inFilter('id', threadIds)
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchThreadReactorsRaw(String threadId) async {
    final response = await supabaseClient
        .from('likes')
        .select('user_id, profiles!user_id(*)')
        .eq('thread_id', threadId);
    return response as List<dynamic>;
  }

  @override
  Future<bool> createThread(
    String userId,
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    String? audience,
    List<String>? pollOptions,
    DateTime? pollExpiresAt,
    String? communityId,
    bool isSubscriberOnly = false,
    bool isAnonymous = false,
  }) async {
    final Map<String, dynamic> insertData = {
      'user_id': userId,
      'content': content,
      'is_subscriber_only': isSubscriberOnly,
      'is_anonymous': isAnonymous,
    };

    // Only add optional fields if they have values (avoid sending null keys to Supabase)
    if (imageUrls != null && imageUrls.isNotEmpty) {
      insertData['image_urls'] = imageUrls;
    }
    if (videoUrl != null && videoUrl.isNotEmpty) {
      insertData['video_url'] = videoUrl;
    }
    if (audioUrl != null && audioUrl.isNotEmpty) {
      insertData['audio_url'] = audioUrl;
    }
    if (audience != null && audience.isNotEmpty) {
      insertData['audience'] = audience;
    }
    if (communityId != null && communityId.isNotEmpty) {
      insertData['community_id'] = communityId;
    }
    if (pollExpiresAt != null) {
      insertData['poll_expires_at'] = pollExpiresAt.toUtc().toIso8601String();
    }

    final threadRes = await supabaseClient
        .from('threads')
        .insert(insertData)
        .select('id')
        .single();

    final threadId = threadRes['id'] as String;

    if (pollOptions != null && pollOptions.isNotEmpty) {
      final List<Map<String, dynamic>> optionsToInsert = pollOptions.map((opt) => {
        'thread_id': threadId,
        'option_text': opt,
      }).toList();

      await supabaseClient.from('poll_options').insert(optionsToInsert);
    }
    return true;
  }

  @override
  Future<void> toggleLike(String userId, String threadId, bool shouldLike) async {
    if (shouldLike) {
      await supabaseClient.from('likes').insert({
        'user_id': userId,
        'thread_id': threadId,
      });
    } else {
      await supabaseClient
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('thread_id', threadId);
    }
  }

  @override
  Future<bool> togglePinPost(String threadId, bool isPinned) async {
    await supabaseClient.from('threads').update({'is_pinned': isPinned}).eq('id', threadId);
    return true;
  }

  @override
  Future<bool> toggleMutePostNotifications(String threadId, bool mute) async {
    await supabaseClient.from('threads').update({'mute_notifications': mute}).eq('id', threadId);
    return true;
  }

  @override
  Future<bool> toggleHidePostFromProfile(String threadId, bool hide) async {
    await supabaseClient.from('threads').update({'hide_from_profile': hide}).eq('id', threadId);
    return true;
  }

  @override
  Future<List<dynamic>> fetchCommentsRaw(String threadId) async {
    final response = await supabaseClient
        .from('comments')
        .select('*, profiles!user_id(*)')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchCommentLikesRaw(String userId) async {
    final response = await supabaseClient
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', userId);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchCommentRepliesRaw(String commentId) async {
    final response = await supabaseClient
        .from('comments')
        .select('*, profiles!user_id(*)')
        .eq('parent_id', commentId)
        .order('created_at', ascending: true);
    return response as List<dynamic>;
  }

  @override
  Future<bool> addComment(String userId, String threadId, String content, {String? parentId, String? imageUrl}) async {
    await supabaseClient.from('comments').insert({
      'user_id': userId,
      'thread_id': threadId,
      'content': content,
      'parent_id': ?parentId,
      'image_url': ?imageUrl,
    });
    return true;
  }

  @override
  Future<bool> toggleCommentLike(String userId, String commentId, bool isLiked) async {
    if (isLiked) {
      await supabaseClient.from('comment_likes').upsert({
        'user_id': userId,
        'comment_id': commentId,
      });
    } else {
      await supabaseClient
          .from('comment_likes')
          .delete()
          .eq('user_id', userId)
          .eq('comment_id', commentId);
    }
    return true;
  }

  @override
  Future<bool> toggleSaveComment(String userId, String commentId, bool isAlreadySaved) async {
    if (isAlreadySaved) {
      await supabaseClient
          .from('saved_comments')
          .delete()
          .eq('user_id', userId)
          .eq('comment_id', commentId);
    } else {
      await supabaseClient.from('saved_comments').upsert({
        'user_id': userId,
        'comment_id': commentId,
      });
    }
    return true;
  }

  @override
  Future<List<dynamic>> fetchSavedCommentIdsRaw(String userId) async {
    final response = await supabaseClient
        .from('saved_comments')
        .select('comment_id')
        .eq('user_id', userId);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchSavedCommentsRaw(String userId) async {
    final response = await supabaseClient
        .from('saved_comments')
        .select('*, comments(*, profiles!user_id(*))')
        .eq('user_id', userId);
    return response as List<dynamic>;
  }

  @override
  Future<bool> deleteComment(String commentId) async {
    await supabaseClient.from('comments').delete().eq('id', commentId);
    return true;
  }

  @override
  Future<bool> editComment(String commentId, String newContent) async {
    await supabaseClient.from('comments').update({'content': newContent}).eq('id', commentId);
    return true;
  }

  @override
  Future<List<dynamic>> fetchSavedPostsRaw(String userId) async {
    final response = await supabaseClient
        .from('saved_posts')
        .select('*, threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*))')
        .eq('user_id', userId);
    return response as List<dynamic>;
  }

  @override
  Future<void> toggleSaveThread(String userId, String threadId, bool wasAlreadySaved) async {
    if (wasAlreadySaved) {
      await supabaseClient
          .from('saved_posts')
          .delete()
          .eq('user_id', userId)
          .eq('thread_id', threadId);
    } else {
      await supabaseClient.from('saved_posts').upsert({
        'user_id': userId,
        'thread_id': threadId,
      });
    }
  }

  @override
  Future<List<dynamic>> fetchSavedThreadIdsRaw(String userId) async {
    final response = await supabaseClient
        .from('saved_posts')
        .select('thread_id')
        .eq('user_id', userId);
    return response as List<dynamic>;
  }
}
