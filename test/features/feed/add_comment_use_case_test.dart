import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/feed/domain/usecases/add_comment_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, bool>? addCommentResult;

  @override
  Future<Either<Failure, bool>> addComment(
    String threadId,
    String content, {
    String? parentId,
    String? imageUrl,
  }) async {
    return addCommentResult!;
  }
}

void main() {
  group('AddCommentUseCase Tests', () {
    late FakeFeedRepository repository;
    late AddCommentUseCase useCase;

    setUp(() {
      repository = FakeFeedRepository();
      useCase = AddCommentUseCase(repository);
    });

    test('returns Right(true) on successful comment addition', () async {
      repository.addCommentResult = const Right(true);

      final result = await useCase('thread123', 'My comment', parentId: 'parent123');

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          expect(success, isTrue);
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.addCommentResult = const Left(ServerFailure('Failed to add comment'));

      final result = await useCase('thread123', 'My comment');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to add comment'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
