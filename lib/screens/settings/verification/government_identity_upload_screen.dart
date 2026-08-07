import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/id_upload_card.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'face_verification_screen.dart';

class GovernmentIdentityUploadScreen extends StatefulWidget {
  const GovernmentIdentityUploadScreen({super.key});

  @override
  State<GovernmentIdentityUploadScreen> createState() => _GovernmentIdentityUploadScreenState();
}

class _GovernmentIdentityUploadScreenState extends State<GovernmentIdentityUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _ministryController;
  late TextEditingController _designationController;
  late TextEditingController _govEmailController;
  late TextEditingController _govWebsiteController;

  @override
  void initState() {
    super.initState();
    final req = context.read<VerificationController>().request;
    _ministryController = TextEditingController(text: req.govMinistryName);
    _designationController = TextEditingController(text: req.govDesignation);
    _govEmailController = TextEditingController(text: req.govEmail);
    _govWebsiteController = TextEditingController(text: req.govWebsiteUrl);
  }

  @override
  void dispose() {
    _ministryController.dispose();
    _designationController.dispose();
    _govEmailController.dispose();
    _govWebsiteController.dispose();
    super.dispose();
  }

  Future<void> _pickDocumentImage(Function(XFile) onPicked) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        onPicked(image);
      });
    }
  }

  void _onNext() {
    final controller = context.read<VerificationController>();
    final req = controller.request;
    final isPremium = req.isPremiumPlan;

    // Validate Gov ID Card
    if (req.govIdCardImage == null) {
      _showErrorSnackBar("Official Government Employee ID / Badge photo is required.");
      return;
    }

    if (_ministryController.text.trim().isEmpty) {
      _showErrorSnackBar("Ministry / Department Name is required.");
      return;
    }

    if (_designationController.text.trim().isEmpty) {
      _showErrorSnackBar("Official Designation / Post is required.");
      return;
    }

    // Premium Specific Validations
    if (isPremium) {
      if (req.govAuthorizationLetterImage == null) {
        _showErrorSnackBar("Government Authorization Letter / Official GO Order photo is required for Premium.");
        return;
      }
      if (_govEmailController.text.trim().isEmpty) {
        _showErrorSnackBar("Official Gov Email Address is required for Premium.");
        return;
      }
      if (_govWebsiteController.text.trim().isEmpty) {
        _showErrorSnackBar("Official Government Portal / Website URL is required for Premium.");
        return;
      }
    }

    // Personal NID Validation
    if (req.nidFront == null || req.nidBack == null) {
      _showErrorSnackBar("Applicant Personal NID Card (Front & Back) is required.");
      return;
    }

    // Save fields
    req.govMinistryName = _ministryController.text.trim();
    req.govDesignation = _designationController.text.trim();
    req.govEmail = _govEmailController.text.trim();
    req.govWebsiteUrl = _govWebsiteController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final req = controller.request;
    final steps = VerificationController.getSteps(req.category);
    final isPremium = req.isPremiumPlan;
    final isDark = context.isDarkMode;

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
          "Apply for Gray Badge 🏛️",
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏛️', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              isPremium ? 'Government Premium (Ministry / Agency)' : 'Government Basic (Officer)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        "Official Credentials & ID",
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPremium
                            ? "Provide official GO order authorization, gov employee ID, ministry portal & NID."
                            : "Upload your official government employee ID, department info & personal NID.",
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SECTION 1: GOVERNMENT CREDENTIALS
                      Text(
                        "1. Official Government ID & Credentials",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Gov Employee ID Card
                      IdUploadCard(
                        title: "Government Employee ID Card",
                        subtitle: "Official Department Badge or Service ID photo",
                        file: req.govIdCardImage,
                        onTap: () => _pickDocumentImage((img) => req.govIdCardImage = img),
                      ),
                      const SizedBox(height: 14),

                      // Gov Authorization Letter (Premium Only)
                      if (isPremium) ...[
                        IdUploadCard(
                          title: "Government Authorization Letter (GO)",
                          subtitle: "Official Government Order / Memo authorization photo",
                          file: req.govAuthorizationLetterImage,
                          onTap: () => _pickDocumentImage((img) => req.govAuthorizationLetterImage = img),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Ministry / Department Name
                      Text(
                        "Ministry / Department Name",
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _ministryController,
                        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: "e.g. Ministry of Public Administration",
                          prefixIcon: Icon(Icons.account_balance_rounded, color: context.primaryAccent, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Designation / Official Title
                      Text(
                        "Official Designation / Post",
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _designationController,
                        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: "e.g. Assistant Director / Executive Engineer",
                          prefixIcon: Icon(Icons.badge_rounded, color: context.primaryAccent, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Official Gov Email (Required for Premium, Optional for Basic)
                      Text(
                        isPremium ? "Official Gov Email Address (Required)" : "Official Gov Email Address (Optional)",
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _govEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: "officer@gov.bd",
                          prefixIcon: Icon(Icons.mark_email_read_rounded, color: context.primaryAccent, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Official Gov Portal Website (Premium Only)
                      if (isPremium) ...[
                        Text(
                          "Official Gov Portal / Website URL",
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _govWebsiteController,
                          keyboardType: TextInputType.url,
                          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: "https://bangladesh.gov.bd",
                            prefixIcon: Icon(Icons.language_rounded, color: context.primaryAccent, size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 20),

                      // SECTION 2: APPLICANT PERSONAL NID
                      Text(
                        "2. Authorized Applicant Personal NID",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "National ID card photo of the official representative submitting this application.",
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: IdUploadCard(
                              title: "NID Front",
                              subtitle: "Front side photo",
                              file: req.nidFront,
                              onTap: () => _pickDocumentImage((img) => req.nidFront = img),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: IdUploadCard(
                              title: "NID Back",
                              subtitle: "Back side photo",
                              file: req.nidBack,
                              onTap: () => _pickDocumentImage((img) => req.nidBack = img),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // TRUST BANNER
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Official Government Verification. Gray Badge 🏛️ is reserved for official state entities, public officers, and government departments.",
                                style: GoogleFonts.inter(
                                  color: context.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.4,
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: PigeonPrimaryButton(
            label: "Continue to Selfie Scan",
            icon: Icons.arrow_forward_rounded,
            onPressed: _onNext,
          ),
        ),
      ),
    );
  }
}
