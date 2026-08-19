import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/chat/domain/usecases/get_active_chats_use_case.dart';
import 'package:dak/features/chat/domain/repositories/chat_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeChatRepository implements IChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, List<Map<String, dynamic>>>? fetchActiveChatsResult;

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchActiveChats() async {
    return fetchActiveChatsResult!;
  }
}

void main() {
  group('GetActiveChatsUseCase Tests', () {
    late FakeChatRepository repository;
    late GetActiveChatsUseCase useCase;

    setUp(() {
      repository = FakeChatRepository();
      useCase = GetActiveChatsUseCase(repository);
    });

    test('returns Right list of active chats on success', () async {
      final chat = {
        'id': 'chat123',
        'last_message': 'Hey',
        'unread_count': 2,
      };
      repository.fetchActiveChatsResult = Right([chat]);

      final result = await useCase();

      result.fold(
        (failure) => fail('Should not return failure'),
        (chats) {
          expect(chats.length, equals(1));
          expect(chats.first['id'], equals('chat123'));
          expect(chats.first['unread_count'], equals(2));
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.fetchActiveChatsResult = const Left(ServerFailure('Failed to fetch active chats'));

      final result = await useCase();

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to fetch active chats'));
        },
        (chats) => fail('Should not succeed'),
      );
    });
  });
}
