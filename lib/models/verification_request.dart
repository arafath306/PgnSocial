import 'package:image_picker/image_picker.dart';

/// Lifecycle of a verification application.
enum VerificationStatus {
  incomplete,
  pendingReview,
  approved,
  rejected,
}

class VerificationRequest {
  // Step 1 — Personal details
  String fullName;
  String username;
  DateTime? dateOfBirth;
  String bio;

  // Step 2 — Identity
  String nidNumber;
  XFile? nidFront;
  XFile? nidBack;
  bool isStudent;
  String idType;

  // Step 3 — Face Verification
  XFile? faceImage;
  String? faceImageUrl;

  // Step 4 — Contact
  String phone;
  String email;

  // Step 5 — Payment (manual bKash, verified by backend afterwards)
  String bkashSenderNumber;
  String bkashTrxId;
  String selectedPlanId;

  bool isRenewal;

  VerificationStatus status;
  String? rejectionReason;

  VerificationRequest({
    this.fullName = '',
    this.username = '',
    this.dateOfBirth,
    this.bio = '',
    this.nidNumber = '',
    this.nidFront,
    this.nidBack,
    this.isStudent = false,
    this.idType = 'nid',
    this.faceImage,
    this.faceImageUrl,
    this.phone = '',
    this.email = '',
    this.bkashSenderNumber = '',
    this.bkashTrxId = '',
    this.selectedPlanId = 'monthly',
    this.isRenewal = false,
    this.status = VerificationStatus.incomplete,
    this.rejectionReason,
  });

  bool get hasBothIdImages => nidFront != null && nidBack != null;
  bool get hasFaceImage => faceImage != null;
}
