import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/chat/domain/usecases/delete_conversation_use_case.dart';
import 'package:dak/features/chat/domain/repositories/chat_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeChatRepository implements IChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, bool>? deleteConversationResult;

  @override
  Future<Either<Failure, bool>> deleteConversation(String otherUserId) async {
    return deleteConversationResult!;
  }
}

void main() {
  group('DeleteConversationUseCase Tests', () {
    late FakeChatRepository repository;
    late DeleteConversationUseCase useCase;

    setUp(() {
      repository = FakeChatRepository();
      useCase = DeleteConversationUseCase(repository);
    });

    test('returns Right(true) on successful delete', () async {
      repository.deleteConversationResult = const Right(true);

      final result = await useCase('otherUser123');

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          expect(success, isTrue);
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.deleteConversationResult = const Left(ServerFailure('Failed to delete conversation'));

      final result = await useCase('otherUser123');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to delete conversation'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
