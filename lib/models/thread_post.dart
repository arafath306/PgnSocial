import 'package:flutter/foundation.dart';
import 'profile.dart';
import 'poll_option.dart';
import 'music_track.dart';
import 'community.dart';

class ThreadPost {
  final String id;
  final String userId;
  final Profile author;
  final String content;
  final List<String>? imageUrls;
  final String? videoUrl;
  final String? audioUrl;
  final int likesCount;
  final int repliesCount;
  final int repostsCount;
  final int savesCount;
  final int sharesCount;
  final String createdAt;
  final bool isLikedByMe;
  final String? reactionType;
  final bool isPinned;
  final bool muteNotifications;
  final bool hideFromProfile;
  final bool isHiddenFromMe;
  final int viewsCount;
  final String? communityId;
  final Community? community;

  final bool isRepost;
  final ThreadPost? repostedPost;
  final String? quoteText;
  final bool isSubscriberOnly;

  // Poll Fields
  final List<PollOption>? pollOptions;
  final DateTime? pollExpiresAt;
  final bool hasVotedPoll;
  final String? votedOptionId;

  // Music Field
  final MusicTrack? musicTrack;

  ThreadPost({
    required this.id,
    required this.userId,
    required this.author,
    required this.content,
    this.imageUrls,
    this.videoUrl,
    this.audioUrl,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.repostsCount = 0,
    this.savesCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.communityId,
    this.community,
    required this.createdAt,
    this.isLikedByMe = false,
    this.reactionType,
    this.isPinned = false,
    this.muteNotifications = false,
    this.hideFromProfile = false,
    this.isHiddenFromMe = false,
    this.isRepost = false,
    this.repostedPost,
    this.quoteText,
    this.isSubscriberOnly = false,
    this.pollOptions,
    this.pollExpiresAt,
    this.hasVotedPoll = false,
    this.votedOptionId,
    this.musicTrack,
  });

  int get totalPollVotes {
    if (pollOptions == null) return 0;
    return pollOptions!.fold(0, (sum, option) => sum + option.votesCount);
  }

  bool get isPollExpired {
    if (pollExpiresAt == null) return false;
    return DateTime.now().isAfter(pollExpiresAt!);
  }

  bool get isAnonymous => (author.id == 'anonymous' || author.username == 'anonymous');

  static String formatRelativeTime(String? isoString) {
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

  factory ThreadPost.fromJson(Map<String, dynamic> json, {String? currentUid}) {
    final bool isAnon = (json['is_anonymous'] as bool?) ?? false;
    final authorMap = json['profiles'] as Map<String, dynamic>?;
    final Profile authorProfile = isAnon
        ? Profile(
            id: 'anonymous',
            username: 'anonymous',
            fullName: 'Anonymous User',
            avatarUrl: null,
          )
        : (authorMap != null 
            ? Profile.fromJson(authorMap) 
            : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User'));

    // Likes check logic
    final likesList = json['likes'] as List<dynamic>?;
    final isLiked = currentUid != null && likesList != null && 
        likesList.any((like) => like['user_id'] == currentUid);

    // Hidden visibility check logic
    final hidesList = json['thread_hides'] as List<dynamic>?;
    final isHidden = currentUid != null && hidesList != null &&
        hidesList.any((hide) => hide['user_id'] == currentUid);

    // Dynamic Image URLs mapping (Supabase stores it as text[] or string)
    List<String>? parsedImages;
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        parsedImages = (json['image_urls'] as List).map((e) => e.toString()).toList();
      } else if (json['image_urls'] is String) {
        final str = json['image_urls'] as String;
        if (str.startsWith('{') && str.endsWith('}')) {
          parsedImages = str.substring(1, str.length - 1).split(',').map((e) => e.trim()).toList();
        } else {
          parsedImages = [str];
        }
      }
    }

    // Parse Poll Votes
    final votesList = json['poll_votes'] as List<dynamic>?;
    final isVoted = currentUid != null && votesList != null &&
        votesList.any((vote) => vote['user_id'] == currentUid);
    final votedOptId = isVoted
        ? votesList.firstWhere((vote) => vote['user_id'] == currentUid)['poll_option_id'] as String?
        : null;

    // Parse Poll Options
    List<PollOption>? parsedPollOptions;
    if (json['poll_options'] != null) {
      parsedPollOptions = (json['poll_options'] as List)
          .map((opt) => PollOption.fromJson(opt as Map<String, dynamic>, votesList: votesList))
          .toList();
    }

    final expiresAtStr = json['poll_expires_at'] as String?;
    final expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr).toLocal() : null;

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
            debugPrint("Error parsing music track from post JSON: $e");
          }
        }
      }
    }

    Community? parsedCommunity;
    if (json['communities'] != null) {
      parsedCommunity = Community.fromJson(json['communities'] as Map<String, dynamic>);
    }

    return ThreadPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      author: authorProfile,
      content: cleanContent,
      imageUrls: parsedImages,
      videoUrl: json['video_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      likesCount: (json['likes_count'] as int?) ?? 0,
      repliesCount: (json['replies_count'] as int?) ?? 0,
      repostsCount: (json['reposts_count'] as int?) ?? 0,
      savesCount: (json['saves_count'] as int?) ?? 0,
      sharesCount: (json['shares_count'] as int?) ?? 0,
      viewsCount: (json['views_count'] as int?) ?? 0,
      communityId: json['community_id'] as String?,
      community: parsedCommunity,
      createdAt: formatRelativeTime(json['created_at'] as String?),
      isLikedByMe: isLiked,
      reactionType: isLiked ? '❤️' : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      muteNotifications: json['mute_notifications'] as bool? ?? false,
      hideFromProfile: json['hide_from_profile'] as bool? ?? false,
      isHiddenFromMe: isHidden,
      isRepost: json['is_repost'] as bool? ?? false,
      repostedPost: json['reposted_post'] != null 
          ? ThreadPost.fromJson(json['reposted_post'] as Map<String, dynamic>, currentUid: currentUid)
          : null,
      quoteText: json['quote_text'] as String?,
      isSubscriberOnly: json['is_subscriber_only'] ?? false,
      pollOptions: parsedPollOptions,
      pollExpiresAt: expiresAt,
      hasVotedPoll: isVoted,
      votedOptionId: votedOptId,
      musicTrack: parsedMusicTrack,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profiles': author.toJson(),
      'content': content,
      'image_urls': imageUrls,
      'video_url': videoUrl,
      'likes_count': likesCount,
      'replies_count': repliesCount,
      'reposts_count': repostsCount,
      'saves_count': savesCount,
      'shares_count': sharesCount,
      'views_count': viewsCount,
      'community_id': communityId,
      'communities': community?.toJson(),
      'created_at': createdAt, // This is a formatted string, we save it back directly
      'is_pinned': isPinned,
      'mute_notifications': muteNotifications,
      'hide_from_profile': hideFromProfile,
      'is_repost': isRepost,
      'reposted_post': repostedPost?.toJson(),
      'quote_text': quoteText,
      'is_subscriber_only': isSubscriberOnly,
      'poll_options': pollOptions?.map((e) => e.toJson()).toList(),
      'poll_expires_at': pollExpiresAt?.toIso8601String(),
      'likes': isLikedByMe ? [{'user_id': userId}] : null, // Simulate like for current user mapping
      'thread_hides': isHiddenFromMe ? [{'user_id': userId}] : null,
      'poll_votes': hasVotedPoll && votedOptionId != null ? [{'user_id': userId, 'poll_option_id': votedOptionId}] : null,
      if (musicTrack != null) 'content': '$content🎵DakMusic🎵${musicTrack!.toJson()}', // Restore original payload for music
    };
  }

  ThreadPost copyWith({
    String? id,
    String? userId,
    Profile? author,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    int? likesCount,
    int? repliesCount,
    int? repostsCount,
    int? savesCount,
    int? sharesCount,
    int? viewsCount,
    String? communityId,
    Community? community,
    String? createdAt,
    bool? isLikedByMe,
    String? reactionType,
    bool? isPinned,
    bool? muteNotifications,
    bool? hideFromProfile,
    bool? isHiddenFromMe,
    bool? isRepost,
    ThreadPost? repostedPost,
    String? quoteText,
    List<PollOption>? pollOptions,
    DateTime? pollExpiresAt,
    bool? hasVotedPoll,
    String? votedOptionId,
    MusicTrack? musicTrack,
  }) {
    return ThreadPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      author: author ?? this.author,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      savesCount: savesCount ?? this.savesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      communityId: communityId ?? this.communityId,
      community: community ?? this.community,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      reactionType: reactionType ?? this.reactionType,
      isPinned: isPinned ?? this.isPinned,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      hideFromProfile: hideFromProfile ?? this.hideFromProfile,
      isHiddenFromMe: isHiddenFromMe ?? this.isHiddenFromMe,
      isRepost: isRepost ?? this.isRepost,
      repostedPost: repostedPost ?? this.repostedPost,
      quoteText: quoteText ?? this.quoteText,
      pollOptions: pollOptions ?? this.pollOptions,
      pollExpiresAt: pollExpiresAt ?? this.pollExpiresAt,
      hasVotedPoll: hasVotedPoll ?? this.hasVotedPoll,
      votedOptionId: votedOptionId ?? this.votedOptionId,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }
}

