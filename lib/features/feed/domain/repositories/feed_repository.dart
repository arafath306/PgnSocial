import '../../../../core/error/failures.dart';
import '../entities/thread_post_entity.dart';

abstract class IFeedRepository {
  Future<Either<Failure, List<ThreadPostEntity>>> fetchFeed({bool silent = false});
  Future<Either<Failure, List<ThreadPostEntity>>> fetchMyThreads();
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserThreads(String userId);
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserRepliedThreads(String userId);
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchThreadReactors(String threadId);
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
  });
  Future<Either<Failure, void>> toggleLike(String threadId, bool shouldLike);
  Future<Either<Failure, bool>> togglePinPost(String threadId, bool isPinned);
  Future<Either<Failure, bool>> toggleMutePostNotifications(String threadId, bool mute);
  Future<Either<Failure, bool>> toggleHidePostFromProfile(String threadId, bool hide);
  
  // Comments operations
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchComments(String threadId);
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchCommentReplies(String commentId);
  Future<Either<Failure, bool>> addComment(String threadId, String content, {String? parentId, String? imageUrl});
  Future<Either<Failure, bool>> toggleCommentLike(String commentId, bool isLiked);
  Future<Either<Failure, bool>> toggleSaveComment(String commentId);
  Future<Either<Failure, bool>> deleteComment(String commentId);
  Future<Either<Failure, bool>> editComment(String commentId, String newContent);

  // Saved/Bookmarks operations
  Future<Either<Failure, List<ThreadPostEntity>>> fetchSavedPosts();
  Future<Either<Failure, void>> toggleSaveThread(String threadId, bool wasAlreadySaved);
}
