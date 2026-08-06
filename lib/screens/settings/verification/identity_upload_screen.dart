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

class IdentityUploadScreen extends StatefulWidget {
  const IdentityUploadScreen({super.key});

  @override
  State<IdentityUploadScreen> createState() => _IdentityUploadScreenState();
}

class _IdentityUploadScreenState extends State<IdentityUploadScreen> {
  final _nidController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _front;
  XFile? _back;
  bool _isStudent = false;

  static const _steps = [
    'Personal',
    'Identity',
    'Face',
    'Review',
    'Payment'
  ];

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<VerificationController>(context, listen: false);
    _nidController.text = controller.request.nidNumber;
    _front = controller.request.nidFront;
    _back = controller.request.nidBack;
    _isStudent = controller.request.isStudent;
  }

  @override
  void dispose() {
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isFront}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        color: context.cardBg,
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: context.primaryAccent),
                title: Text(AppLocalizations.of(context)!.takeAPhoto, style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: context.primaryAccent),
                title: Text(AppLocalizations.of(context)!.chooseFromGallery, style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600)),
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

  void _onContinue() {
    if (_nidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isStudent ? 'Please enter your Student ID or Roll number' : AppLocalizations.of(context)!.pleaseEnterYourNidNumber)),
      );
      return;
    }
    if (_front == null || _back == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isStudent ? 'Please upload both front & back or 2 proof images of your Student ID / Document' : AppLocalizations.of(context)!.pleaseUploadBothSidesOfYourNidCard)),
      );
      return;
    }

    context.read<VerificationController>().updateIdentity(
          nidNumber: _nidController.text.trim(),
          front: _front,
          back: _back,
          isStudent: _isStudent,
          idType: _isStudent ? 'student_id' : 'nid',
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = VerificationController.getSteps();

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
        title: Text(AppLocalizations.of(context)!.applyForBlueBadge,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            StepProgressBar(currentStep: 2, labels: steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.confirmYourIdentity,
                        style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Text(
                      _isStudent 
                          ? 'Provide clear photos of your Student ID card, Admission letter, or academic proof document.' 
                          : AppLocalizations.of(context)!.provideAGovernmentissuedPhotoIdMakeSureT,
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- I don't have an NID / Student Verification Selector ---
                    GestureDetector(
                      onTap: () => setState(() => _isStudent = !_isStudent),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isStudent ? const Color(0xFF6366F1).withValues(alpha: 0.08) : context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isStudent ? const Color(0xFF6366F1) : context.border,
                            width: _isStudent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isStudent ? const Color(0xFF6366F1).withValues(alpha: 0.15) : context.scaffoldBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isStudent ? Icons.school_rounded : Icons.badge_outlined,
                                size: 20,
                                color: _isStudent ? const Color(0xFF6366F1) : context.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isStudent ? "Student Verification Selected" : "I don't have an NID (Student Verification)",
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _isStudent ? const Color(0xFF6366F1) : context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isStudent 
                                        ? "Uploading Student ID card / Admission letter" 
                                        : "Tap here if you are a student without NID card",
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isStudent,
                              onChanged: (val) => setState(() => _isStudent = val),
                              activeColor: const Color(0xFF6366F1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    PigeonTextField(
                      label: _isStudent ? 'Student ID / Roll Number' : AppLocalizations.of(context)!.nationalIdNidNumber,
                      hint: _isStudent ? 'Enter your Student ID or Roll number' : 'Enter your 10 or 17 digit NID number',
                      controller: _nidController,
                      keyboardType: _isStudent ? TextInputType.text : TextInputType.number,
                      prefixIcon: Icon(
                        _isStudent ? Icons.school_outlined : Icons.badge_outlined,
                        size: 18, 
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                      _isStudent ? 'Upload Student Documents' : AppLocalizations.of(context)!.uploadIdDocuments,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: context.textPrimary,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isStudent 
                          ? 'Upload Student ID front & back, or ID front & admission letter / proof'
                          : AppLocalizations.of(context)!.takeClearPhotosOfBothTheFrontAndBackOfYo,
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: IdUploadCard(
                            title: _isStudent ? 'Student Card Front' : AppLocalizations.of(context)!.frontSide,
                            subtitle: _isStudent ? 'Tap to upload Student ID or Admission Letter' : AppLocalizations.of(context)!.tapToUploadNidFront,
                            file: _front,
                            onTap: () => _pickImage(isFront: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: IdUploadCard(
                            title: _isStudent ? 'Student Card Back' : AppLocalizations.of(context)!.backSide,
                            subtitle: _isStudent ? 'Tap to upload Back Side or Proof Document' : AppLocalizations.of(context)!.tapToUploadNidBack,
                            file: _back,
                            onTap: () => _pickImage(isFront: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isStudent ? const Color(0xFF6366F1).withValues(alpha: 0.05) : Colors.amber.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isStudent ? const Color(0xFF6366F1).withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_isStudent ? Icons.school : Icons.info_outline_rounded, color: _isStudent ? const Color(0xFF6366F1) : Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isStudent 
                                  ? 'Ensure all text on your Student ID or document is clear and readable. You will proceed to Face Verification next.' 
                                  : AppLocalizations.of(context)!.ensureThereAreNoReflectionsOrGlaresOnThe,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: context.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
