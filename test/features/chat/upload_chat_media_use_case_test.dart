import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/chat/domain/usecases/upload_chat_media_use_case.dart';
import 'package:dak/features/chat/domain/repositories/chat_repository.dart';
import 'package:dak/core/error/failures.dart';

class MockChatRepository implements IChatRepository {
  final Either<Failure, String?> result;
  MockChatRepository({required this.result});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #uploadChatMedia) {
      return Future.value(result);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('UploadChatMediaUseCase Tests', () {
    test('returns Right(url) on successful image upload', () async {
      final repo = MockChatRepository(result: const Right('https://example.com/image.jpg'));
      final useCase = UploadChatMediaUseCase(repo);
      
      final res = await useCase(Uint8List(10));
      expect(res, isA<Right>());
      res.fold((l) => fail('Should not be left'), (r) => expect(r, equals('https://example.com/image.jpg')));
    });

    test('returns Left(ServerFailure) on failure', () async {
      final repo = MockChatRepository(result: const Left(ServerFailure('Upload failed')));
      final useCase = UploadChatMediaUseCase(repo);
      
      final res = await useCase(Uint8List(10));
      expect(res, isA<Left>());
      res.fold((l) => expect(l, isA<ServerFailure>()), (r) => fail('Should not be right'));
    });
  });
}
