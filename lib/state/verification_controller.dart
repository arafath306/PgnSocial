import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/verification_request.dart';
import '../services/database_service.dart';
import '../core/injection.dart';
import '../features/profile/domain/usecases/submit_verification_use_case.dart';
import '../features/profile/domain/usecases/get_verification_status_use_case.dart';
import '../features/profile/domain/usecases/upload_verification_image_use_case.dart';

/// Single source of truth for the verification flow, powered by DatabaseService.
class VerificationController extends ChangeNotifier {
  VerificationRequest request = VerificationRequest();
  bool isSubmitting = false;

  static List<String> getSteps() {
    return const [
      'Personal',
      'Identity',
      'Face',
      'Review',
      'Payment',
    ];
  }

  void updatePersonalDetails({
    required String fullName,
    required String username,
    required DateTime dateOfBirth,
    required String bio,
  }) {
    request.fullName = fullName;
    request.username = username;
    request.dateOfBirth = dateOfBirth;
    request.bio = bio;
    notifyListeners();
  }

  void updateIdentity({
    required String nidNumber,
    XFile? front,
    XFile? back,
    bool isStudent = false,
    String idType = 'nid',
  }) {
    request.nidNumber = nidNumber;
    if (front != null) request.nidFront = front;
    if (back != null) request.nidBack = back;
    request.isStudent = isStudent;
    request.idType = idType;
    notifyListeners();
  }

  void updateFaceImage(XFile? face) {
    if (face != null) request.faceImage = face;
    notifyListeners();
  }

  void updateContactInfo({required String phone, required String email}) {
    request.phone = phone;
    request.email = email;
    notifyListeners();
  }

  void updatePaymentInfo({
    required String bkashSenderNumber,
    required String bkashTrxId,
  }) {
    request.bkashSenderNumber = bkashSenderNumber;
    request.bkashTrxId = bkashTrxId;
    notifyListeners();
  }

  void selectPlan(String planId) {
    request.selectedPlanId = planId;
    notifyListeners();
  }

  /// Sends the complete application (files upload + database entry) to Supabase.
  Future<void> submitApplication(DatabaseService dbService) async {
    isSubmitting = true;
    notifyListeners();

    try {
      String? frontUrl;
      String? backUrl;

      // 1. Upload NID Front image
      if (request.nidFront != null) {
        final frontBytes = await request.nidFront!.readAsBytes();
        final ext = request.nidFront!.name.split('.').last;
        final res = await sl<UploadVerificationImageUseCase>().call(
          frontBytes,
          'nid_front_${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
        frontUrl = res.fold((l) => throw Exception(l.message), (r) => r);
      }

      // 2. Upload NID Back image
      if (request.nidBack != null) {
        final backBytes = await request.nidBack!.readAsBytes();
        final ext = request.nidBack!.name.split('.').last;
        final res = await sl<UploadVerificationImageUseCase>().call(
          backBytes,
          'nid_back_${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
        backUrl = res.fold((l) => throw Exception(l.message), (r) => r);
      }

      // 3. Upload Face image
      String? faceUrl;
      if (request.faceImage != null) {
        final faceBytes = await request.faceImage!.readAsBytes();
        final ext = request.faceImage!.name.split('.').last;
        final res = await sl<UploadVerificationImageUseCase>().call(
          faceBytes,
          'face_${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
        faceUrl = res.fold((l) => throw Exception(l.message), (r) => r);
      }

      if (frontUrl == null || backUrl == null) {
        throw Exception("Failed to upload NID document images to storage");
      }

      // 4. Submit request metadata to database
      final res = await sl<SubmitVerificationUseCase>().call({
        'full_name': request.fullName,
        'username': request.username,
        'date_of_birth': request.dateOfBirth?.toIso8601String().split('T').first, // yyyy-MM-dd
        'bio': request.bio,
        'nid_number': request.nidNumber,
        'nid_front_url': frontUrl,
        'nid_back_url': backUrl,
        'face_image_url': faceUrl,
        'phone': request.phone,
        'email': request.email,
        'bkash_sender_number': request.bkashSenderNumber,
        'bkash_trx_id': request.bkashTrxId,
        'plan_id': request.selectedPlanId,
        'is_renewal': request.isRenewal,
        'is_student': request.isStudent,
        'id_type': request.idType,
      });

      final success = res.fold((l) => throw Exception(l.message), (r) => r);
      if (!success) {
        throw Exception("Failed to save verification request details to the database");
      }

      request.status = VerificationStatus.pendingReview;
    } catch (e) {
      debugPrint("Verification submit application error: $e");
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Pulls the latest database request status for this user.
  Future<VerificationStatus> checkStatus(DatabaseService dbService) async {
    try {
      final res = await sl<GetVerificationStatusUseCase>().call();
      final reqMap = res.fold((l) => throw Exception(l.message), (r) => r);
      if (reqMap == null) {
        request.status = VerificationStatus.incomplete;
      } else {
        request.fullName = reqMap['full_name'] ?? '';
        request.username = reqMap['username'] ?? '';
        if (reqMap['date_of_birth'] != null) {
          request.dateOfBirth = DateTime.tryParse(reqMap['date_of_birth']);
        }
        request.bio = reqMap['bio'] ?? '';
        request.nidNumber = reqMap['nid_number'] ?? '';
        request.phone = reqMap['phone'] ?? '';
        request.email = reqMap['email'] ?? '';
        request.bkashSenderNumber = reqMap['bkash_sender_number'] ?? '';
        request.bkashTrxId = reqMap['bkash_trx_id'] ?? '';
        request.selectedPlanId = reqMap['plan_id'] ?? 'monthly';
        request.faceImageUrl = reqMap['face_image_url'];
        request.isRenewal = reqMap['is_renewal'] ?? false;
        request.rejectionReason = reqMap['rejection_reason'];

        final statusStr = reqMap['status'] ?? 'pending';
        if (statusStr == 'approved') {
          request.status = VerificationStatus.approved;
        } else if (statusStr == 'rejected') {
          request.status = VerificationStatus.rejected;
        } else {
          request.status = VerificationStatus.pendingReview;
        }
      }
      notifyListeners();
      return request.status;
    } catch (e) {
      debugPrint("Verification check status error: $e");
      return request.status;
    }
  }

  void resetApplication() {
    request = VerificationRequest();
    notifyListeners();
  }
}
