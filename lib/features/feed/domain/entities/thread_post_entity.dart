import '../../../../models/profile.dart';
import '../../../../models/poll_option.dart';
import '../../../../models/music_track.dart';

class ThreadPostEntity {
  final String id;
  final String userId;
  final Profile author;
  final String content;
  final List<String>? imageUrls;
  final String? videoUrl;
  final int likesCount;
  final int repliesCount;
  final int repostsCount;
  final int savesCount;
  final int sharesCount;
  final int viewsCount;
  final String createdAt;
  final bool isLikedByMe;
  final String? reactionType;
  final bool isPinned;
  final bool muteNotifications;
  final bool hideFromProfile;
  final bool isHiddenFromMe;
  final List<String>? commenterAvatars;

  final bool isRepost;
  final ThreadPostEntity? repostedPost;
  final String? quoteText;
  final bool isSubscriberOnly;

  // Poll Fields
  final List<PollOption>? pollOptions;
  final DateTime? pollExpiresAt;
  final bool hasVotedPoll;
  final String? votedOptionId;

  // Music Field
  final MusicTrack? musicTrack;

  ThreadPostEntity({
    required this.id,
    required this.userId,
    required this.author,
    required this.content,
    this.imageUrls,
    this.videoUrl,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.repostsCount = 0,
    this.savesCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    this.isLikedByMe = false,
    this.reactionType,
    this.isPinned = false,
    this.muteNotifications = false,
    this.hideFromProfile = false,
    this.isHiddenFromMe = false,
    this.commenterAvatars,
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

  ThreadPostEntity copyWith({
    String? id,
    String? userId,
    Profile? author,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    int? likesCount,
    int? repliesCount,
    int? repostsCount,
    int? savesCount,
    int? sharesCount,
    int? viewsCount,
    String? createdAt,
    bool? isLikedByMe,
    String? reactionType,
    bool? isPinned,
    bool? muteNotifications,
    bool? hideFromProfile,
    bool? isHiddenFromMe,
    List<String>? commenterAvatars,
    bool? isRepost,
    ThreadPostEntity? repostedPost,
    String? quoteText,
    bool? isSubscriberOnly,
    List<PollOption>? pollOptions,
    DateTime? pollExpiresAt,
    bool? hasVotedPoll,
    String? votedOptionId,
    MusicTrack? musicTrack,
  }) {
    return ThreadPostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      author: author ?? this.author,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      savesCount: savesCount ?? this.savesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      reactionType: reactionType ?? this.reactionType,
      isPinned: isPinned ?? this.isPinned,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      hideFromProfile: hideFromProfile ?? this.hideFromProfile,
      isHiddenFromMe: isHiddenFromMe ?? this.isHiddenFromMe,
      commenterAvatars: commenterAvatars ?? this.commenterAvatars,
      isRepost: isRepost ?? this.isRepost,
      repostedPost: repostedPost ?? this.repostedPost,
      quoteText: quoteText ?? this.quoteText,
      isSubscriberOnly: isSubscriberOnly ?? this.isSubscriberOnly,
      pollOptions: pollOptions ?? this.pollOptions,
      pollExpiresAt: pollExpiresAt ?? this.pollExpiresAt,
      hasVotedPoll: hasVotedPoll ?? this.hasVotedPoll,
      votedOptionId: votedOptionId ?? this.votedOptionId,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }
}

