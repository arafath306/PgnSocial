import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:dak/features/auth/domain/repositories/auth_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, void>? signOutResult;

  @override
  Future<Either<Failure, void>> signOut() async {
    return signOutResult!;
  }
}

void main() {
  group('SignOutUseCase Tests', () {
    late FakeAuthRepository repository;
    late SignOutUseCase useCase;

    setUp(() {
      repository = FakeAuthRepository();
      useCase = SignOutUseCase(repository);
    });

    test('returns Right(null) on successful signout', () async {
      repository.signOutResult = const Right(null);

      final result = await useCase();

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          // Success
        },
      );
    });

    test('returns Left(ServerFailure) on signout repository error', () async {
      repository.signOutResult = const Left(ServerFailure('Sign out failed'));

      final result = await useCase();

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Sign out failed'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
