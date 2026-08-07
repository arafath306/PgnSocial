import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/id_upload_card.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/pigeon_text_field.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'face_verification_screen.dart';

enum IdentityDocType {
  nid('nid', 'National ID (NID)', Icons.badge_outlined, 'NID Card Front & Back'),
  student('student_id', 'Student ID Card', Icons.school_outlined, 'Student Card or Academic Proof'),
  passport('passport', 'Passport', Icons.flight_takeoff_outlined, 'Passport Biographical Page'),
  drivingLicense('driving_license', 'Driving License', Icons.directions_car_outlined, 'License Card Front & Back'),
  taxToken('tax_token', 'Tax Token / TIN', Icons.receipt_long_outlined, 'Tax Token or TIN Certificate');

  final String keyName;
  final String title;
  final IconData icon;
  final String subtitle;

  const IdentityDocType(this.keyName, this.title, this.icon, this.subtitle);
}

class IdentityUploadScreen extends StatefulWidget {
  const IdentityUploadScreen({super.key});

  @override
  State<IdentityUploadScreen> createState() => _IdentityUploadScreenState();
}

class _IdentityUploadScreenState extends State<IdentityUploadScreen> {
  final _idNumberController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _front;
  XFile? _back;
  IdentityDocType _selectedType = IdentityDocType.nid;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<VerificationController>(context, listen: false);
    _idNumberController.text = controller.request.nidNumber;
    _front = controller.request.nidFront;
    _back = controller.request.nidBack;

    final existingTypeKey = controller.request.idType;
    if (controller.request.isStudent) {
      _selectedType = IdentityDocType.student;
    } else {
      _selectedType = IdentityDocType.values.firstWhere(
        (e) => e.keyName == existingTypeKey,
        orElse: () => IdentityDocType.nid,
      );
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _showDocumentTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: context.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Select Document Type',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the type of document you want to use for verification.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ...IdentityDocType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        if (_selectedType != type) {
                          setState(() {
                            _selectedType = type;
                            _front = null;
                            _back = null;
                          });
                        }
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? context.primaryAccent.withValues(alpha: 0.08) : context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? context.primaryAccent : context.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.primaryAccent.withValues(alpha: 0.2)
                                    : context.scaffoldBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                type.icon,
                                size: 24,
                                color: isSelected ? context.primaryAccent : context.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? context.primaryAccent : context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.subtitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 16, color: Colors.white),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.border, width: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage({required bool isFront}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: context.primaryAccent, size: 22),
                ),
                title: Text(
                  AppLocalizations.of(context)!.takeAPhoto,
                  style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: context.primaryAccent, size: 22),
                ),
                title: Text(
                  AppLocalizations.of(context)!.chooseFromGallery,
                  style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      if (isFront) {
        _front = picked;
      } else {
        _back = picked;
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onContinue() {
    final numberText = _idNumberController.text.trim();
    if (numberText.isEmpty) {
      _showSnackBar('Please enter your ${_selectedType.title} number / details');
      return;
    }

    if (_front == null) {
      _showSnackBar('Please upload a clear photo of your ${_selectedType.title}');
      return;
    }

    if (_selectedType != IdentityDocType.passport && _back == null) {
      _showSnackBar('Please upload both Front and Back sides of your ${_selectedType.title}');
      return;
    }

    context.read<VerificationController>().updateIdentity(
          nidNumber: numberText,
          front: _front,
          back: _back ?? _front,
          isStudent: _selectedType == IdentityDocType.student,
          idType: _selectedType.keyName,
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
  }

  String get _idNumberLabel {
    switch (_selectedType) {
      case IdentityDocType.nid: return AppLocalizations.of(context)!.nationalIdNidNumber;
      case IdentityDocType.student: return 'Student ID / Roll Number';
      case IdentityDocType.passport: return 'Passport Number';
      case IdentityDocType.drivingLicense: return 'Driving License Number';
      case IdentityDocType.taxToken: return 'Tax Token / TIN Number';
    }
  }

  String get _idNumberHint {
    switch (_selectedType) {
      case IdentityDocType.nid: return 'Enter your 10 or 17 digit NID number';
      case IdentityDocType.student: return 'Enter your Student ID or Roll number';
      case IdentityDocType.passport: return 'Enter Passport number (e.g. A12345678)';
      case IdentityDocType.drivingLicense: return 'Enter Driving License reference number';
      case IdentityDocType.taxToken: return 'Enter Tax Token or TIN certificate number';
    }
  }

  String get _frontCardTitle {
    switch (_selectedType) {
      case IdentityDocType.nid: return '${AppLocalizations.of(context)!.frontSide} (NID)';
      case IdentityDocType.student: return 'Student ID Front / Admission Letter';
      case IdentityDocType.passport: return 'Passport Biographical Page';
      case IdentityDocType.drivingLicense: return 'Driving License Front Side';
      case IdentityDocType.taxToken: return 'Tax Token / TIN Front';
    }
  }

  String get _backCardTitle {
    switch (_selectedType) {
      case IdentityDocType.nid: return '${AppLocalizations.of(context)!.backSide} (NID)';
      case IdentityDocType.student: return 'Student ID Back / Proof Document';
      case IdentityDocType.passport: return 'Visa / Endorsement Page (Optional)';
      case IdentityDocType.drivingLicense: return 'Driving License Back Side';
      case IdentityDocType.taxToken: return 'Document Back Side';
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = context.watch<VerificationController>().request;
    final steps = VerificationController.getSteps(req.category);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Apply for Blue Badge 🔵",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            StepProgressBar(currentStep: 2, labels: steps),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                physics: const ClampingScrollPhysics(),
                children: [
                  // Beautiful Screen Header
                  Text(
                    'Verify Your Identity',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a government-issued document or student ID to verify your identity. Your data is securely encrypted and never shared.',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section Title: Document Details
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.article_rounded, size: 18, color: context.primaryAccent),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Document Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Premium Document Selector Tile
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showDocumentTypePicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.primaryAccent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_selectedType.icon, color: context.primaryAccent, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Document Type',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedType.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.scaffoldBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.border),
                              ),
                              child: Icon(Icons.unfold_more_rounded, color: context.textPrimary, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ID Number TextField
                  PigeonTextField(
                    label: _idNumberLabel,
                    hint: _idNumberHint,
                    controller: _idNumberController,
                    keyboardType: _selectedType == IdentityDocType.nid ? TextInputType.number : TextInputType.text,
                    prefixIcon: Icon(_selectedType.icon, size: 20, color: context.textMuted),
                  ),
                  const SizedBox(height: 40),

                  // Section Title: Upload Photos
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.cloud_upload_rounded, size: 18, color: context.primaryAccent),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Upload Photos',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Subtitle optimization
                  Text(
                    'Clear, well-lit photos ensure faster automated review and approval.',
                    style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Vertically Stacked High-Quality Upload Cards
                  IdUploadCard(
                    title: _frontCardTitle,
                    subtitle: 'Tap to capture or upload',
                    file: _front,
                    onTap: () => _pickImage(isFront: true),
                  ),
                  const SizedBox(height: 16),
                  
                  // Show Back Card
                  IdUploadCard(
                    title: _backCardTitle,
                    subtitle: 'Tap to capture or upload',
                    file: _back,
                    onTap: () => _pickImage(isFront: false),
                  ),

                  const SizedBox(height: 36),

                  // Corporate Security & Privacy Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.primaryAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.primaryAccent.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.shield_rounded, color: context.primaryAccent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Privacy & Security',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your identity documents are encrypted end-to-end and strictly used for verification purposes.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: context.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PigeonPrimaryButton(
                label: AppLocalizations.of(context)!.saveContinue,
                icon: Icons.arrow_forward_rounded,
                onPressed: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
