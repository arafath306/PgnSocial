import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class AddCommentUseCase {
  final IFeedRepository repository;

  AddCommentUseCase(this.repository);

  Future<Either<Failure, bool>> call(String threadId, String content, {String? parentId, String? imageUrl, String? audioUrl}) {
    return repository.addComment(threadId, content, parentId: parentId, imageUrl: imageUrl, audioUrl: audioUrl);
  }
}
