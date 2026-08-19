import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/feed/domain/usecases/fetch_comments_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, List<Map<String, dynamic>>>? fetchCommentsResult;

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchComments(String threadId) async {
    return fetchCommentsResult!;
  }
}

void main() {
  group('FetchCommentsUseCase Tests', () {
    late FakeFeedRepository repository;
    late FetchCommentsUseCase useCase;

    setUp(() {
      repository = FakeFeedRepository();
      useCase = FetchCommentsUseCase(repository);
    });

    test('returns Right list of comment maps on success', () async {
      final comment = {
        'id': 'comment123',
        'content': 'This is a comment',
        'user_id': 'user123',
      };
      repository.fetchCommentsResult = Right([comment]);

      final result = await useCase('thread123');

      result.fold(
        (failure) => fail('Should not return failure'),
        (comments) {
          expect(comments.length, equals(1));
          expect(comments.first['id'], equals('comment123'));
          expect(comments.first['content'], equals('This is a comment'));
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.fetchCommentsResult = const Left(ServerFailure('Failed to fetch comments'));

      final result = await useCase('thread123');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to fetch comments'));
        },
        (comments) => fail('Should not succeed'),
      );
    });
  });
}
