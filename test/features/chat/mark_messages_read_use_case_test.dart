import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/chat/domain/usecases/mark_messages_as_read_use_case.dart';
import 'package:dak/features/chat/domain/repositories/chat_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeChatRepository implements IChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, void>? markMessagesAsReadResult;

  @override
  Future<Either<Failure, void>> markMessagesAsRead(String otherUserId) async {
    return markMessagesAsReadResult!;
  }
}

void main() {
  group('MarkMessagesAsReadUseCase Tests', () {
    late FakeChatRepository repository;
    late MarkMessagesAsReadUseCase useCase;

    setUp(() {
      repository = FakeChatRepository();
      useCase = MarkMessagesAsReadUseCase(repository);
    });

    test('returns Right(null) on successful mark', () async {
      repository.markMessagesAsReadResult = const Right(null);

      final result = await useCase('otherUser123');

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          // Success
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.markMessagesAsReadResult = const Left(ServerFailure('Failed to mark messages as read'));

      final result = await useCase('otherUser123');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to mark messages as read'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
