import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:dak/features/profile/domain/repositories/profile_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeProfileRepository implements IProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, bool>? updateProfileResult;

  @override
  Future<Either<Failure, bool>> updateProfile({
    required String fullName,
    required String username,
    required String bio,
    required String phone,
    required String country,
    String? division,
    String? city,
    String? village,
    String? zip,
    String? gender,
    String? birthdate,
  }) async {
    return updateProfileResult!;
  }
}

void main() {
  group('UpdateProfileUseCase Tests', () {
    late FakeProfileRepository repository;
    late UpdateProfileUseCase useCase;

    setUp(() {
      repository = FakeProfileRepository();
      useCase = UpdateProfileUseCase(repository);
    });

    test('returns Right(true) on successful update', () async {
      repository.updateProfileResult = const Right(true);

      final result = await useCase(
        fullName: 'New Name',
        username: 'new_username',
        bio: 'Updated bio info',
        phone: '01700000000',
        country: 'Bangladesh',
      );

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          expect(success, isTrue);
        },
      );
    });

    test('returns Left(ServerFailure) on error', () async {
      repository.updateProfileResult = const Left(ServerFailure('Failed to update profile'));

      final result = await useCase(
        fullName: 'New Name',
        username: 'new_username',
        bio: 'Updated bio info',
        phone: '01700000000',
        country: 'Bangladesh',
      );

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Failed to update profile'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
