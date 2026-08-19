import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/feed/domain/usecases/toggle_like_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, void>? toggleLikeResult;

  @override
  Future<Either<Failure, void>> toggleLike(String threadId, bool shouldLike) async {
    return toggleLikeResult!;
  }
}

void main() {
  group('ToggleLikeUseCase Tests', () {
    late FakeFeedRepository repository;
    late ToggleLikeUseCase useCase;

    setUp(() {
      repository = FakeFeedRepository();
      useCase = ToggleLikeUseCase(repository);
    });

    test('returns Right(null) on successful toggle', () async {
      repository.toggleLikeResult = const Right(null);

      final result = await useCase('thread123', true);

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          // Success
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.toggleLikeResult = const Left(ServerFailure('Failed to toggle like'));

      final result = await useCase('thread123', false);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to toggle like'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
