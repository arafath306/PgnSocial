import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/profile/domain/usecases/get_verification_status_use_case.dart';
import 'package:dak/features/profile/domain/repositories/profile_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeProfileRepository implements IProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, Map<String, dynamic>?>? fetchUserVerificationRequestResult;

  @override
  Future<Either<Failure, Map<String, dynamic>?>> fetchUserVerificationRequest() async {
    return fetchUserVerificationRequestResult!;
  }
}

void main() {
  group('GetVerificationStatusUseCase Tests', () {
    late FakeProfileRepository repository;
    late GetVerificationStatusUseCase useCase;

    setUp(() {
      repository = FakeProfileRepository();
      useCase = GetVerificationStatusUseCase(repository);
    });

    test('returns Right with map on success', () async {
      final request = {
        'id': 'req123',
        'status': 'pending',
        'plan_id': 'general_weekly_basic',
      };
      repository.fetchUserVerificationRequestResult = Right(request);

      final result = await useCase();

      result.fold(
        (failure) => fail('Should not return failure'),
        (statusMap) {
          expect(statusMap, isNotNull);
          expect(statusMap!['id'], equals('req123'));
          expect(statusMap['status'], equals('pending'));
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.fetchUserVerificationRequestResult = const Left(ServerFailure('Failed to fetch verification status'));

      final result = await useCase();

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to fetch verification status'));
        },
        (statusMap) => fail('Should not succeed'),
      );
    });
  });
}
