import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/auth/domain/usecases/signup_use_case.dart';
import 'package:dak/features/auth/domain/repositories/auth_repository.dart';
import 'package:dak/core/error/failures.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Either<Failure, bool>? signupResult;

  @override
  Future<Either<Failure, bool>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String birthdate,
    String? username,
    String? division,
    String? city,
    String? village,
    String? zip,
  }) async {
    return signupResult!;
  }
}

void main() {
  group('SignupUseCase Tests', () {
    late FakeAuthRepository repository;
    late SignupUseCase useCase;

    setUp(() {
      repository = FakeAuthRepository();
      useCase = SignupUseCase(repository);
    });

    test('returns Right(true) on successful signup', () async {
      repository.signupResult = const Right(true);

      final result = await useCase(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
        phone: '01712345678',
        gender: 'Male',
        birthdate: '1995-05-15',
      );

      result.fold(
        (failure) => fail('Should not return failure'),
        (success) {
          expect(success, isTrue);
        },
      );
    });

    test('returns Left(ServerFailure) on signup error (e.g. email exists)', () async {
      repository.signupResult = const Left(ServerFailure('Email already registered'));

      final result = await useCase(
        email: 'existing@example.com',
        password: 'password123',
        fullName: 'Existing User',
        phone: '01712345678',
        gender: 'Female',
        birthdate: '1990-01-01',
      );

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Email already registered'));
        },
        (success) => fail('Should not succeed'),
      );
    });
  });
}
