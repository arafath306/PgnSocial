// NOTE: [UNUSED / REFERENCE ONLY]
// This entity file is currently not active in the app.
// Active verification requests are managed directly via [VerificationRequest] in 'models/verification_request.dart'.
// Kept for future clean-architecture reference.

import 'package:image_picker/image_picker.dart';

enum VerificationStatusEntity {
  incomplete,
  pendingReview,
  approved,
  rejected,
}

class VerificationRequestEntity {
  String fullName;
  String username;
  DateTime? dateOfBirth;
  String bio;

  String nidNumber;
  XFile? nidFront;
  XFile? nidBack;

  XFile? faceImage;
  String? faceImageUrl;

  String phone;
  String email;

  String bkashSenderNumber;
  String bkashTrxId;
  String selectedPlanId;

  bool isRenewal;
  VerificationStatusEntity status;
  String? rejectionReason;

  VerificationRequestEntity({
    this.fullName = '',
    this.username = '',
    this.dateOfBirth,
    this.bio = '',
    this.nidNumber = '',
    this.nidFront,
    this.nidBack,
    this.faceImage,
    this.faceImageUrl,
    this.phone = '',
    this.email = '',
    this.bkashSenderNumber = '',
    this.bkashTrxId = '',
    this.selectedPlanId = 'monthly',
    this.isRenewal = false,
    this.status = VerificationStatusEntity.incomplete,
    this.rejectionReason,
  });

  bool get hasBothIdImages => nidFront != null && nidBack != null;
  bool get hasFaceImage => faceImage != null;
}
