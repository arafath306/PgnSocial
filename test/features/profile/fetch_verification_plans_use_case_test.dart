import 'package:flutter_test/flutter_test.dart';
import 'package:dak/features/profile/domain/usecases/fetch_verification_plans_use_case.dart';
import 'package:dak/features/profile/domain/repositories/profile_repository.dart';
import 'package:dak/core/error/failures.dart';

class MockProfileRepository implements IProfileRepository {
  final Either<Failure, List<Map<String, dynamic>>> result;
  MockProfileRepository({required this.result});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #fetchVerificationPlans) {
      return Future.value(result);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('FetchVerificationPlansUseCase Tests', () {
    test('returns Right with plan list on success', () async {
      final mockPlans = [{'id': 'monthly', 'price': 5.0}];
      final repo = MockProfileRepository(result: Right(mockPlans));
      final useCase = FetchVerificationPlansUseCase(repo);
      
      final res = await useCase();
      expect(res, isA<Right>());
      res.fold((l) => fail('Should not be left'), (r) {
        expect(r.length, 1);
        expect(r.first['id'], 'monthly');
      });
    });

    test('returns Left(ServerFailure) on failure', () async {
      final repo = MockProfileRepository(result: const Left(ServerFailure('Failed to fetch')));
      final useCase = FetchVerificationPlansUseCase(repo);
      
      final res = await useCase();
      expect(res, isA<Left>());
      res.fold((l) => expect(l, isA<ServerFailure>()), (r) => fail('Should not be right'));
    });
  });
}
