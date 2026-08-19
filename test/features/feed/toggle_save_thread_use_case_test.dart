import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/feed/domain/usecases/toggle_save_thread_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, void>? toggleSaveThreadResult;

  @override
  Future<Either<Failure, void>> toggleSaveThread(String threadId, bool wasAlreadySaved) async {
    return toggleSaveThreadResult!;
  }
}

void main() {
  group('ToggleSaveThreadUseCase Tests', () {
    late FakeFeedRepository repository;
    late ToggleSaveThreadUseCase useCase;

    setUp(() {
      repository = FakeFeedRepository();
      useCase = ToggleSaveThreadUseCase(repository);
    });

    test('returns Right(null) on successful toggle', () async {
      repository.toggleSaveThreadResult = const Right(null);

      final result = await useCase('thread123', true);

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          // Success
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.toggleSaveThreadResult = const Left(ServerFailure('Failed to toggle save'));

      final result = await useCase('thread123', false);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to toggle save'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
