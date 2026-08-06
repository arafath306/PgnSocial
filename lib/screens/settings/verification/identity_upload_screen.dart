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
  student('student_id', 'Student Card', Icons.school_outlined, 'Student ID / Academic Proof'),
  passport('passport', 'Passport', Icons.flight_takeoff_outlined, 'Passport Bio Page'),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: context.primaryAccent, size: 20),
                ),
                title: Text(
                  AppLocalizations.of(context)!.takeAPhoto,
                  style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_outlined, color: context.primaryAccent, size: 20),
                ),
                title: Text(
                  AppLocalizations.of(context)!.chooseFromGallery,
                  style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600),
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

  void _onContinue() {
    final numberText = _idNumberController.text.trim();
    if (numberText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your ${_selectedType.title} number / details')),
      );
      return;
    }

    if (_front == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a clear photo of your ${_selectedType.title}')),
      );
      return;
    }

    if (_selectedType != IdentityDocType.passport && _back == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload both Front and Back sides of your ${_selectedType.title}')),
      );
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
      case IdentityDocType.nid:
        return AppLocalizations.of(context)!.nationalIdNidNumber;
      case IdentityDocType.student:
        return 'Student ID / Roll Number';
      case IdentityDocType.passport:
        return 'Passport Number';
      case IdentityDocType.drivingLicense:
        return 'Driving License Number';
      case IdentityDocType.taxToken:
        return 'Tax Token / TIN Number';
    }
  }

  String get _idNumberHint {
    switch (_selectedType) {
      case IdentityDocType.nid:
        return 'Enter your 10 or 17 digit NID number';
      case IdentityDocType.student:
        return 'Enter your Student ID or Roll number';
      case IdentityDocType.passport:
        return 'Enter Passport number (e.g. A12345678)';
      case IdentityDocType.drivingLicense:
        return 'Enter Driving License reference number';
      case IdentityDocType.taxToken:
        return 'Enter Tax Token or TIN certificate number';
    }
  }

  String get _frontCardTitle {
    switch (_selectedType) {
      case IdentityDocType.nid:
        return AppLocalizations.of(context)!.frontSide;
      case IdentityDocType.student:
        return 'Student ID Front / Admission Letter';
      case IdentityDocType.passport:
        return 'Passport Info Page';
      case IdentityDocType.drivingLicense:
        return 'License Front Side';
      case IdentityDocType.taxToken:
        return 'Tax Token / TIN Front';
    }
  }

  String get _backCardTitle {
    switch (_selectedType) {
      case IdentityDocType.nid:
        return AppLocalizations.of(context)!.backSide;
      case IdentityDocType.student:
        return 'Student ID Back / Proof Document';
      case IdentityDocType.passport:
        return 'Visa / Back Page (Optional)';
      case IdentityDocType.drivingLicense:
        return 'License Back Side';
      case IdentityDocType.taxToken:
        return 'Document Back Side';
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = VerificationController.getSteps();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.applyForBlueBadge,
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.confirmYourIdentity,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please choose how you want to verify your identity. You can submit your NID, Student Document, Passport, Driving License, or Tax Token.',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- SELECT YOUR DOCUMENT TYPE HEADER ---
                    Row(
                      children: [
                        Icon(Icons.style_outlined, size: 18, color: context.primaryAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Select Document Type',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- ELEGANT DOCUMENT TYPE DROPDOWN SELECTOR ---
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IdentityDocType>(
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.primaryAccent,
                            size: 24,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          onChanged: (newType) {
                            if (newType != null && newType != _selectedType) {
                              setState(() {
                                _selectedType = newType;
                                _front = null;
                                _back = null;
                              });
                            }
                          },
                          items: IdentityDocType.values.map((type) {
                            final isSelected = type == _selectedType;
                            return DropdownMenuItem<IdentityDocType>(
                              value: type,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.primaryAccent.withValues(alpha: 0.15)
                                          : context.scaffoldBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      type.icon,
                                      size: 18,
                                      color: isSelected
                                          ? context.primaryAccent
                                          : context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          type.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          type.subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- ID / DOCUMENT NUMBER TEXTFIELD ---
                    PigeonTextField(
                      label: _idNumberLabel,
                      hint: _idNumberHint,
                      controller: _idNumberController,
                      keyboardType: _selectedType == IdentityDocType.nid
                          ? TextInputType.number
                          : TextInputType.text,
                      prefixIcon: Icon(
                        _selectedType.icon,
                        size: 18,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- UPLOAD SECTION HEADER ---
                    Text(
                      'Upload Document Photos',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedType == IdentityDocType.passport
                          ? 'Upload a clear photo of your Passport biographical info page.'
                          : 'Take or upload clear photos of both Front & Back of your ${_selectedType.title}.',
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 16),

                    // --- FILE PICKER CARDS ---
                    Row(
                      children: [
                        Expanded(
                          child: IdUploadCard(
                            title: _frontCardTitle,
                            subtitle: 'Tap to upload ${_selectedType.title} front photo',
                            file: _front,
                            onTap: () => _pickImage(isFront: true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: IdUploadCard(
                            title: _backCardTitle,
                            subtitle: _selectedType == IdentityDocType.passport
                                ? 'Optional back page'
                                : 'Tap to upload ${_selectedType.title} back photo',
                            file: _back,
                            onTap: () => _pickImage(isFront: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- GUIDANCE BANNER ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.primaryAccent.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.primaryAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: context.primaryAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Make sure all information and text on your ${_selectedType.title} are completely visible and clear. Reflection or blur may delay review.',
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
