import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class CreateThreadUseCase {
  final IFeedRepository repository;

  CreateThreadUseCase(this.repository);

  Future<Either<Failure, bool>> call(
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
  }) {
    return repository.createThread(
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
  }
}
