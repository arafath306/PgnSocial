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

class BusinessIdentityUploadScreen extends StatefulWidget {
  const BusinessIdentityUploadScreen({super.key});

  @override
  State<BusinessIdentityUploadScreen> createState() => _BusinessIdentityUploadScreenState();
}

class _BusinessIdentityUploadScreenState extends State<BusinessIdentityUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _websiteController;
  late TextEditingController _businessEmailController;
  late TextEditingController _tinNumberController;

  @override
  void initState() {
    super.initState();
    final req = context.read<VerificationController>().request;
    _websiteController = TextEditingController(text: req.websiteUrl);
    _businessEmailController = TextEditingController(text: req.businessEmail);
    _tinNumberController = TextEditingController(text: req.tinNumber);
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _businessEmailController.dispose();
    _tinNumberController.dispose();
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

    // Validate Trade License
    if (req.tradeLicenseImage == null) {
      _showErrorSnackBar("Trade License document photo is required.");
      return;
    }

    // Premium specific validations
    if (isPremium) {
      if (req.tinCertificateImage == null) {
        _showErrorSnackBar("TIN Certificate document photo is required for Business Premium.");
        return;
      }
      if (req.companyRegCertificateImage == null) {
        _showErrorSnackBar("Company Registration Certificate (RJSC) photo is required for Business Premium.");
        return;
      }
      if (_websiteController.text.trim().isEmpty) {
        _showErrorSnackBar("Official Website Link is required for Business Premium.");
        return;
      }
    }

    // NID Validation
    if (req.nidFront == null || req.nidBack == null) {
      _showErrorSnackBar("Applicant NID Card (Front & Back) is required.");
      return;
    }

    // Save fields
    req.websiteUrl = _websiteController.text.trim();
    req.businessEmail = _businessEmailController.text.trim();
    req.tinNumber = _tinNumberController.text.trim();

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
          "Apply for Gold Badge 👑",
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
                          color: const Color(0xFFD97706).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              isPremium ? 'Business Premium (Corporate)' : 'Business Basic (Standard)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        "Business Identity & Documents",
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
                            ? "Provide corporate registration, trade license, TIN, website and applicant NID."
                            : "Upload your business Trade License, optional TIN & applicant NID.",
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SECTION 1: BUSINESS DOCUMENTS
                      Text(
                        "1. Business Credentials",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Trade License Card
                      IdUploadCard(
                        title: "Trade License Document",
                        subtitle: "Government issued Trade License photo",
                        file: req.tradeLicenseImage,
                        onTap: () => _pickDocumentImage((img) => req.tradeLicenseImage = img),
                      ),
                      const SizedBox(height: 14),

                      // TIN Certificate Card (Required for Premium, Optional for Basic)
                      IdUploadCard(
                        title: isPremium ? "TIN Certificate (Required)" : "TIN Certificate (Optional)",
                        subtitle: isPremium
                            ? "Official Tax Identification Certificate"
                            : "Upload TIN certificate if available",
                        file: req.tinCertificateImage,
                        onTap: () => _pickDocumentImage((img) => req.tinCertificateImage = img),
                      ),
                      const SizedBox(height: 14),

                      // Company Reg Certificate (Premium Only)
                      if (isPremium) ...[
                        IdUploadCard(
                          title: "Company Registration (RJSC)",
                          subtitle: "Certificate of Incorporation / Partnership Deed",
                          file: req.companyRegCertificateImage,
                          onTap: () => _pickDocumentImage((img) => req.companyRegCertificateImage = img),
                        ),
                        const SizedBox(height: 14),

                        // Official Website Field
                        Text(
                          "Official Website Link",
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _websiteController,
                          keyboardType: TextInputType.url,
                          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: "https://yourcompany.com",
                            prefixIcon: Icon(Icons.language_rounded, color: context.primaryAccent, size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Business Email (Optional for both)
                      Text(
                        "Business Email Address (Optional)",
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _businessEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: "info@company.com",
                          prefixIcon: Icon(Icons.business_center_rounded, color: context.primaryAccent, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF10132A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // SECTION 2: APPLICANT PERSONAL NID
                      Text(
                        "2. Applicant Personal NID",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Photo of National ID card of the person submitting on behalf of the company.",
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
                            const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Corporate Security & Encryption. Your business documents are encrypted and kept strictly confidential.",
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
