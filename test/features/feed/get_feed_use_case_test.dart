import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/core/error/failures.dart';

class FakeFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, List<ThreadPostEntity>>? fetchFeedResult;

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchFeed({bool silent = false}) async {
    return fetchFeedResult!;
  }
}

void main() {
  group('GetFeedUseCase Tests', () {
    late FakeFeedRepository repository;
    late GetFeedUseCase useCase;

    setUp(() {
      repository = FakeFeedRepository();
      useCase = GetFeedUseCase(repository);
    });

    test('returns Right with list of ThreadPostEntity on success', () async {
      final mockPost = ThreadPostEntity(
        id: 'post1',
        userId: 'user1',
        author: Profile(id: 'user1', username: 'john', fullName: 'John Doe'),
        content: 'Hello World',
        createdAt: '2025-08-12T10:00:00Z',
      );
      repository.fetchFeedResult = Right([mockPost]);

      final result = await useCase(silent: false);

      result.fold(
        (failure) => fail('Should not return failure'),
        (posts) {
          expect(posts.length, equals(1));
          expect(posts.first.id, equals('post1'));
          expect(posts.first.content, equals('Hello World'));
        },
      );
    });

    test('returns Left with ServerFailure on failure', () async {
      repository.fetchFeedResult = const Left(ServerFailure('Connection error'));

      final result = await useCase(silent: true);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Connection error'));
        },
        (posts) => fail('Should not return posts'),
      );
    });
  });
}
