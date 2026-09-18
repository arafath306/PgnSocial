import 'dart:typed_data';
import '../../../../core/error/failures.dart';

abstract class IProfileRepository {
  Future<Either<Failure, bool>> submitVerificationRequest(Map<String, dynamic> requestData);
  
  Future<Either<Failure, Map<String, dynamic>?>> fetchUserVerificationRequest();
  
  Future<Either<Failure, String?>> uploadVerificationImage(Uint8List bytes, String filename);
  
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchAdminVerificationRequests();
  
  Future<Either<Failure, bool>> updateVerificationRequestStatus(String requestId, String status, {String? reason});
  
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
    String? education,
    String? bloodGroup,
    String? occupation,
    String? website,
  });
  
  Future<Either<Failure, bool>> updateProfileImage(Uint8List bytes, bool isAvatar);
  
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchVerificationPlans();
  
  Future<Either<Failure, bool>> updateVerificationPlanPrice(String planId, double price, {double? discountPrice});
}
