import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/profile/domain/usecases/submit_verification_use_case.dart';
import 'package:dak/features/profile/domain/repositories/profile_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeProfileRepository implements IProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, bool>? submitVerificationRequestResult;

  @override
  Future<Either<Failure, bool>> submitVerificationRequest(Map<String, dynamic> requestData) async {
    return submitVerificationRequestResult!;
  }
}

void main() {
  group('SubmitVerificationUseCase Tests', () {
    late FakeProfileRepository repository;
    late SubmitVerificationUseCase useCase;

    setUp(() {
      repository = FakeProfileRepository();
      useCase = SubmitVerificationUseCase(repository);
    });

    test('returns Right(true) on successful submission', () async {
      repository.submitVerificationRequestResult = const Right(true);

      final result = await useCase({
        'plan_id': 'general_monthly_premium',
        'document_image': 'http://doc.jpg',
      });

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          expect(success, isTrue);
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.submitVerificationRequestResult = const Left(ServerFailure('Failed to submit request'));

      final result = await useCase({});

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to submit request'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
