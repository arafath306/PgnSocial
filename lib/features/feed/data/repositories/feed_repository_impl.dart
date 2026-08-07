import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/error/failures.dart';
import '../../../../models/profile.dart';
import '../../../../models/poll_option.dart';
import '../../../../models/music_track.dart';
import '../../domain/entities/thread_post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements IFeedRepository {
  final FeedRemoteDataSource remoteDataSource;
  final sb.SupabaseClient supabaseClient;

  FeedRepositoryImpl(this.remoteDataSource, this.supabaseClient);

  // Use Supabase.instance.client for more reliable access during token refresh
  String get _currentUid =>
      sb.Supabase.instance.client.auth.currentUser?.id ??
      supabaseClient.auth.currentUser?.id ??
      '';

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchFeed({
    bool silent = false,
  }) async {
    try {
      final threadsRaw = await remoteDataSource.fetchFeedRaw();
      final repostsRaw = await remoteDataSource.fetchRepostsRaw();

      final List<Map<String, dynamic>> combinedRaw = [];
      for (final thread in threadsRaw) {
        combinedRaw.add({
          'type': 'thread',
          'created_at': thread['created_at'] as String,
          'data': thread,
        });
      }
      for (final repost in repostsRaw) {
        if (repost['threads'] != null) {
          combinedRaw.add({
            'type': 'repost',
            'created_at': repost['created_at'] as String,
            'data': repost,
          });
        }
      }

      combinedRaw.sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );

      final List<ThreadPostEntity> posts = [];
      for (final item in combinedRaw) {
        final type = item['type'] as String;
        final map = item['data'] as Map<String, dynamic>;
        if (type == 'thread') {
          posts.add(_mapToEntity(map));
        } else {
          final threadMap = map['threads'] as Map<String, dynamic>;
          final reposterProfileMap = map['profiles'] as Map<String, dynamic>?;
          final reposterProfile = reposterProfileMap != null
              ? Profile.fromJson(reposterProfileMap)
              : Profile(
                  id: map['user_id'] ?? '',
                  username: 'unknown',
                  fullName: 'Unknown User',
                );

          final originalPost = _mapToEntity(threadMap);

          posts.add(
            ThreadPostEntity(
              id: map['id'] as String,
              userId: map['user_id'] as String,
              author: reposterProfile,
              content: map['quote_text'] as String? ?? '',
              createdAt: _formatRelativeTime(map['created_at'] as String?),
              isRepost: true,
              repostedPost: originalPost,
              quoteText: map['quote_text'] as String?,
              likesCount: 0,
              repliesCount: 0,
              repostsCount: 0,
              viewsCount: 0,
            ),
          );
        }
      }

      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchMyThreads() async {
    try {
      final data = await remoteDataSource.fetchMyThreadsRaw(_currentUid);
      final posts = data
          .map((json) => _mapToEntity(json as Map<String, dynamic>))
          .toList();
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });
      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserThreads(
    String userId,
  ) async {
    try {
      final data = await remoteDataSource.fetchUserThreadsRaw(userId);
      final posts = data
          .map((json) => _mapToEntity(json as Map<String, dynamic>))
          .toList();
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });
      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserRepliedThreads(
    String userId,
  ) async {
    try {
      final data = await remoteDataSource.fetchUserRepliedThreadsRaw(userId);
      final posts = data
          .map((json) => _mapToEntity(json as Map<String, dynamic>))
          .toList();
      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchThreadReactors(
    String threadId,
  ) async {
    try {
      final data = await remoteDataSource.fetchThreadReactorsRaw(threadId);
      final List<Map<String, dynamic>> reactors = [];
      for (final item in data) {
        final profileMap = item['profiles'] as Map<String, dynamic>?;
        if (profileMap != null) {
          final profile = Profile.fromJson(profileMap);
          if (!reactors.any((r) => r['id'] == profile.id)) {
            reactors.add({
              'id': profile.id,
              'name': profile.fullName,
              'handle': '@${profile.username}',
              'avatar': profile.avatarUrl ?? '',
            });
          }
        }
      }
      return Right(reactors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> createThread(
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
    try {
      final result = await remoteDataSource.createThread(
        _currentUid,
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
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLike(
    String threadId,
    bool shouldLike,
  ) async {
    try {
      await remoteDataSource.toggleLike(_currentUid, threadId, shouldLike);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> togglePinPost(
    String threadId,
    bool isPinned,
  ) async {
    try {
      final result = await remoteDataSource.togglePinPost(threadId, isPinned);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleMutePostNotifications(
    String threadId,
    bool mute,
  ) async {
    try {
      final result = await remoteDataSource.toggleMutePostNotifications(
        threadId,
        mute,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleHidePostFromProfile(
    String threadId,
    bool hide,
  ) async {
    try {
      final result = await remoteDataSource.toggleHidePostFromProfile(
        threadId,
        hide,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchComments(
    String threadId,
  ) async {
    try {
      final commentsRaw = await remoteDataSource.fetchCommentsRaw(threadId);
      final likesRaw = await remoteDataSource.fetchCommentLikesRaw(_currentUid);
      final savedRaw = await remoteDataSource.fetchSavedCommentIdsRaw(
        _currentUid,
      );

      final Set<String> likedCommentIds = likesRaw
          .map((l) => l['comment_id'] as String)
          .toSet();
      final Set<String> savedCommentIds = savedRaw
          .map((s) => s['comment_id'] as String)
          .toSet();

      final List<Map<String, dynamic>> results = [];
      for (final json in commentsRaw) {
        final authorMap = json['profiles'] as Map<String, dynamic>?;
        final authorProfile = authorMap != null
            ? Profile.fromJson(authorMap)
            : Profile(
                id: json['user_id'] ?? '',
                username: 'unknown',
                fullName: 'Unknown User',
              );

        results.add({
          'id': json['id'],
          'thread_id': json['thread_id'],
          'user_id': json['user_id'],
          'content': json['content'],
          'image_url': json['image_url'],
          'parent_id': json['parent_id'],
          'created_at_raw': json['created_at'],
          'created_at': _formatRelativeTime(json['created_at'] as String?),
          'likes_count': json['likes_count'] ?? 0,
          'replies_count': json['replies_count'] ?? 0,
          'saves_count': json['saves_count'] ?? 0,
          'shares_count': json['shares_count'] ?? 0,
          'author': authorProfile,
          'is_liked_by_me': likedCommentIds.contains(json['id'] as String),
          'is_saved_by_me': savedCommentIds.contains(json['id'] as String),
        });
      }

      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchCommentReplies(
    String commentId,
  ) async {
    try {
      final repliesRaw = await remoteDataSource.fetchCommentRepliesRaw(
        commentId,
      );
      final likesRaw = await remoteDataSource.fetchCommentLikesRaw(_currentUid);
      final savedRaw = await remoteDataSource.fetchSavedCommentIdsRaw(
        _currentUid,
      );

      final Set<String> likedCommentIds = likesRaw
          .map((l) => l['comment_id'] as String)
          .toSet();
      final Set<String> savedCommentIds = savedRaw
          .map((s) => s['comment_id'] as String)
          .toSet();

      final List<Map<String, dynamic>> results = [];
      for (final json in repliesRaw) {
        final authorMap = json['profiles'] as Map<String, dynamic>?;
        final authorProfile = authorMap != null
            ? Profile.fromJson(authorMap)
            : Profile(
                id: json['user_id'] ?? '',
                username: 'unknown',
                fullName: 'Unknown User',
              );

        results.add({
          'id': json['id'],
          'thread_id': json['thread_id'],
          'user_id': json['user_id'],
          'content': json['content'],
          'image_url': json['image_url'],
          'parent_id': json['parent_id'],
          'created_at_raw': json['created_at'],
          'created_at': _formatRelativeTime(json['created_at'] as String?),
          'likes_count': json['likes_count'] ?? 0,
          'replies_count': json['replies_count'] ?? 0,
          'saves_count': json['saves_count'] ?? 0,
          'shares_count': json['shares_count'] ?? 0,
          'author': authorProfile,
          'is_liked_by_me': likedCommentIds.contains(json['id'] as String),
          'is_saved_by_me': savedCommentIds.contains(json['id'] as String),
        });
      }

      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> addComment(
    String threadId,
    String content, {
    String? parentId,
    String? imageUrl,
  }) async {
    try {
      final result = await remoteDataSource.addComment(
        _currentUid,
        threadId,
        content,
        parentId: parentId,
        imageUrl: imageUrl,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleCommentLike(
    String commentId,
    bool isLiked,
  ) async {
    try {
      final result = await remoteDataSource.toggleCommentLike(
        _currentUid,
        commentId,
        isLiked,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleSaveComment(String commentId) async {
    try {
      final savedRaw = await remoteDataSource.fetchSavedCommentIdsRaw(
        _currentUid,
      );
      final Set<String> savedCommentIds = savedRaw
          .map((s) => s['comment_id'] as String)
          .toSet();
      final isAlreadySaved = savedCommentIds.contains(commentId);
      final result = await remoteDataSource.toggleSaveComment(
        _currentUid,
        commentId,
        isAlreadySaved,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteComment(String commentId) async {
    try {
      final result = await remoteDataSource.deleteComment(commentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> editComment(
    String commentId,
    String newContent,
  ) async {
    try {
      final result = await remoteDataSource.editComment(commentId, newContent);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchSavedPosts() async {
    try {
      final savedRaw = await remoteDataSource.fetchSavedPostsRaw(_currentUid);
      final List<ThreadPostEntity> posts = [];
      for (final row in savedRaw) {
        if (row['threads'] != null) {
          posts.add(_mapToEntity(row['threads'] as Map<String, dynamic>));
        }
      }
      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleSaveThread(
    String threadId,
    bool wasAlreadySaved,
  ) async {
    try {
      await remoteDataSource.toggleSaveThread(
        _currentUid,
        threadId,
        wasAlreadySaved,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  ThreadPostEntity _mapToEntity(Map<String, dynamic> json) {
    final authorMap = json['profiles'] as Map<String, dynamic>?;
    final authorProfile = authorMap != null
        ? Profile.fromJson(authorMap)
        : Profile(
            id: json['user_id'] ?? '',
            username: 'unknown',
            fullName: 'Unknown User',
          );

    final likesList = json['likes'] as List<dynamic>?;
    final isLiked =
        _currentUid.isNotEmpty &&
        likesList != null &&
        likesList.any((like) => like['user_id'] == _currentUid);

    final hidesList = json['thread_hides'] as List<dynamic>?;
    final isHidden =
        _currentUid.isNotEmpty &&
        hidesList != null &&
        hidesList.any((hide) => hide['user_id'] == _currentUid);

    List<String>? parsedImages;
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        parsedImages = (json['image_urls'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['image_urls'] is String) {
        final str = json['image_urls'] as String;
        if (str.startsWith('{') && str.endsWith('}')) {
          parsedImages = str
              .substring(1, str.length - 1)
              .split(',')
              .map((e) => e.trim())
              .toList();
        } else {
          parsedImages = [str];
        }
      }
    }

    // Parse Poll Votes
    final votesList = json['poll_votes'] as List<dynamic>?;
    final isVoted =
        _currentUid.isNotEmpty &&
        votesList != null &&
        votesList.any((vote) => vote['user_id'] == _currentUid);
    final votedOptId = isVoted
        ? votesList.firstWhere(
                (vote) => vote['user_id'] == _currentUid,
              )['poll_option_id']
              as String?
        : null;

    // Parse Poll Options
    List<PollOption>? parsedPollOptions;
    if (json['poll_options'] != null) {
      parsedPollOptions = (json['poll_options'] as List)
          .map(
            (opt) => PollOption.fromJson(
              opt as Map<String, dynamic>,
              votesList: votesList,
            ),
          )
          .toList();
    }

    final expiresAtStr = json['poll_expires_at'] as String?;
    final expiresAt = expiresAtStr != null
        ? DateTime.parse(expiresAtStr).toLocal()
        : null;

    // Parse Music Suffix from Content (supports 🎵DakMusic🎵 and Mojibake variants)
    String cleanContent = json['content'] as String? ?? '';
    MusicTrack? parsedMusicTrack;
    if (cleanContent.contains('DakMusic')) {
      final musicRegExp = RegExp(r'(\uD83C\uDFB5|🎵|ðŸŽµ)?DakMusic(\uD83C\uDFB5|🎵|ðŸŽµ)?');
      final match = musicRegExp.firstMatch(cleanContent);
      if (match != null) {
        final rawJsonStr = cleanContent.substring(match.end).trim();
        cleanContent = cleanContent.substring(0, match.start).trim();
        if (rawJsonStr.isNotEmpty) {
          try {
            parsedMusicTrack = MusicTrack.fromJson(rawJsonStr);
          } catch (e) {
            // ignore
          }
        }
      }
    }

    return ThreadPostEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      author: authorProfile,
      content: cleanContent,
      imageUrls: parsedImages,
      videoUrl: json['video_url'] as String?,
      likesCount: (json['likes_count'] as int?) ?? 0,
      repliesCount: (json['replies_count'] as int?) ?? 0,
      repostsCount: (json['reposts_count'] as int?) ?? 0,
      savesCount: (json['saves_count'] as int?) ?? 0,
      sharesCount: (json['shares_count'] as int?) ?? 0,
      viewsCount: (json['views_count'] as int?) ?? 0,
      createdAt: _formatRelativeTime(json['created_at'] as String?),
      isLikedByMe: isLiked,
      reactionType: isLiked ? '❤️' : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      muteNotifications: json['mute_notifications'] as bool? ?? false,
      hideFromProfile: json['hide_from_profile'] as bool? ?? false,
      isHiddenFromMe: isHidden,
      isRepost: json['is_repost'] as bool? ?? false,
      repostedPost: json['reposted_post'] != null
          ? _mapToEntity(json['reposted_post'] as Map<String, dynamic>)
          : null,
      quoteText: json['quote_text'] as String?,
      pollOptions: parsedPollOptions,
      pollExpiresAt: expiresAt,
      hasVotedPoll: isVoted,
      votedOptionId: votedOptId,
      musicTrack: parsedMusicTrack,
    );
  }

  String _formatRelativeTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'now';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return 'now';
    }
  }
}
