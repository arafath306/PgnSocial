import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/error/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final sb.SupabaseClient supabaseClient;

  ProfileRepositoryImpl(this.remoteDataSource, this.supabaseClient);

  String get _currentUid => supabaseClient.auth.currentUser?.id ?? '';

  @override
  Future<Either<Failure, bool>> submitVerificationRequest(Map<String, dynamic> requestData) async {
    try {
      if (_currentUid.isEmpty) {
        return const Left(ServerFailure('User is not authenticated'));
      }
      final result = await remoteDataSource.submitVerificationRequest(_currentUid, requestData);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> fetchUserVerificationRequest() async {
    try {
      if (_currentUid.isEmpty) {
        return const Left(ServerFailure('User is not authenticated'));
      }
      final result = await remoteDataSource.fetchUserVerificationRequest(_currentUid);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> uploadVerificationImage(Uint8List bytes, String filename) async {
    try {
      if (_currentUid.isEmpty) {
        return const Left(ServerFailure('User is not authenticated'));
      }
      final result = await remoteDataSource.uploadVerificationImage(_currentUid, bytes, filename);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchAdminVerificationRequests() async {
    try {
      final list = await remoteDataSource.fetchAdminVerificationRequests();
      return Right(List<Map<String, dynamic>>.from(list));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateVerificationRequestStatus(String requestId, String status, {String? reason}) async {
    try {
      final result = await remoteDataSource.updateVerificationRequestStatus(requestId, status, reason: reason);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

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
    String? education,
    String? bloodGroup,
    String? occupation,
    String? website,
  }) async {
    try {
      if (_currentUid.isEmpty) {
        return const Left(ServerFailure('User is not authenticated'));
      }
      final profileData = {
        'full_name': fullName,
        'username': username,
        'bio': bio,
        'phone': phone,
        'country': country,
        'division': division,
        'city': city,
        'village': village,
        'zip': zip,
        'gender': gender,
        'birthdate': birthdate,
        'education': education,
        'blood_group': bloodGroup,
        'occupation': occupation,
        'website': website,
      };
      final result = await remoteDataSource.updateProfile(_currentUid, profileData);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateProfileImage(Uint8List bytes, bool isAvatar) async {
    try {
      if (_currentUid.isEmpty) {
        return const Left(ServerFailure('User is not authenticated'));
      }
      final result = await remoteDataSource.updateProfileImage(_currentUid, bytes, isAvatar);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchVerificationPlans() async {
    try {
      final list = await remoteDataSource.fetchVerificationPlans();
      return Right(List<Map<String, dynamic>>.from(list));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateVerificationPlanPrice(String planId, double price, {double? discountPrice}) async {
    try {
      final result = await remoteDataSource.updateVerificationPlanPrice(planId, price, discountPrice: discountPrice);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchUserExperiences(String userId) async {
    try {
      final res = await supabaseClient
          .from('user_experiences')
          .select('*')
          .eq('user_id', userId)
          .order('start_date', ascending: false);
      return Right(List<Map<String, dynamic>>.from(res));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> saveUserExperience(Map<String, dynamic> data, {String? id}) async {
    try {
      if (id != null && id.isNotEmpty) {
        final res = await supabaseClient
            .from('user_experiences')
            .update(data)
            .eq('id', id)
            .select()
            .single();
        return Right(Map<String, dynamic>.from(res));
      } else {
        final res = await supabaseClient
            .from('user_experiences')
            .insert(data)
            .select()
            .single();
        return Right(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUserExperience(String experienceId) async {
    try {
      await supabaseClient.from('user_experiences').delete().eq('id', experienceId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchUserEducations(String userId) async {
    try {
      final res = await supabaseClient
          .from('user_educations')
          .select('*')
          .eq('user_id', userId)
          .order('start_date', ascending: false);
      return Right(List<Map<String, dynamic>>.from(res));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> saveUserEducation(Map<String, dynamic> data, {String? id}) async {
    try {
      if (id != null && id.isNotEmpty) {
        final res = await supabaseClient
            .from('user_educations')
            .update(data)
            .eq('id', id)
            .select()
            .single();
        return Right(Map<String, dynamic>.from(res));
      } else {
        final res = await supabaseClient
            .from('user_educations')
            .insert(data)
            .select()
            .single();
        return Right(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUserEducation(String educationId) async {
    try {
      await supabaseClient.from('user_educations').delete().eq('id', educationId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
