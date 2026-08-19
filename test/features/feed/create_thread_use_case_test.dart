import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/feed/domain/usecases/create_thread_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, bool>? createThreadResult;

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
    return createThreadResult!;
  }
}

void main() {
  group('CreateThreadUseCase Tests', () {
    late FakeFeedRepository repository;
    late CreateThreadUseCase useCase;

    setUp(() {
      repository = FakeFeedRepository();
      useCase = CreateThreadUseCase(repository);
    });

    test('returns Right(true) on successful thread creation', () async {
      repository.createThreadResult = const Right(true);

      final result = await useCase(
        'Testing use case content',
        imageUrls: ['img1.png'],
        isAnonymous: true,
      );

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          expect(success, isTrue);
        },
      );
    });

    test('returns Left(ServerFailure) on repository failure', () async {
      repository.createThreadResult = const Left(ServerFailure('Failed to insert thread'));

      final result = await useCase('Hello world');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to insert thread'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
