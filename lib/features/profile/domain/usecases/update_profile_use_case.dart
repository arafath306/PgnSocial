import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final IProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, bool>> call({
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
    String? education,
    String? bloodGroup,
    String? occupation,
    String? website,
  }) {
    return repository.updateProfile(
      fullName: fullName,
      username: username,
      bio: bio,
      phone: phone,
      country: country,
      division: division,
      city: city,
      village: village,
      zip: zip,
      gender: gender,
      birthdate: birthdate,
      education: education,
      bloodGroup: bloodGroup,
      occupation: occupation,
      website: website,
    );
  }
}
