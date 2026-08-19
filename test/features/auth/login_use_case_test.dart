import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/auth/domain/usecases/login_use_case.dart';
import 'package:dak/features/auth/domain/repositories/auth_repository.dart';
import 'package:dak/features/auth/domain/entities/user_entity.dart';
import 'package:dak/core/error/failures.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, UserEntity>? loginResult;

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    return loginResult!;
  }
}

void main() {
  group('LoginUseCase Tests', () {
    late FakeAuthRepository repository;
    late LoginUseCase useCase;

    setUp(() {
      repository = FakeAuthRepository();
      useCase = LoginUseCase(repository);
    });

    test('returns Right with UserEntity on success', () async {
      const user = UserEntity(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        username: 'testuser',
      );
      repository.loginResult = const Right(user);

      final result = await useCase('test@example.com', 'password123');

      result.fold(
        (failure) => fail('Should not return failure'),
        (userEntity) {
          expect(userEntity.id, equals('user123'));
          expect(userEntity.email, equals('test@example.com'));
        },
      );
    });

    test('returns Left with ServerFailure on login failure', () async {
      repository.loginResult = const Left(ServerFailure('Invalid credentials'));

      final result = await useCase('wrong@example.com', 'badpass');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Invalid credentials'));
        },
        (userEntity) => fail('Should not return user'),
      );
    });
  });
}
