import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/chat/domain/usecases/send_message_use_case.dart';
import 'package:dak/features/chat/domain/repositories/chat_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeChatRepository implements IChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, void>? sendMessageResult;

  @override
  Future<Either<Failure, void>> sendMessage(
    String receiverId,
    String content, {
    String? mediaUrl,
    String? mediaType,
  }) async {
    return sendMessageResult!;
  }
}

void main() {
  group('SendMessageUseCase Tests', () {
    late FakeChatRepository repository;
    late SendMessageUseCase useCase;

    setUp(() {
      repository = FakeChatRepository();
      useCase = SendMessageUseCase(repository);
    });

    test('returns Right(null) on successful send', () async {
      repository.sendMessageResult = const Right(null);

      final result = await useCase('receiver123', 'Hello!', mediaUrl: 'http://img.jpg', mediaType: 'image');

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          // Success
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.sendMessageResult = const Left(ServerFailure('Failed to send message'));

      final result = await useCase('receiver123', 'Hello!');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to send message'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
