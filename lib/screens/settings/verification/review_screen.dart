import 'package:dak/l10n/generated/app_localizations.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../models/verification_plan_pricing.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'payment_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final request = controller.request;
    final steps = VerificationController.getSteps(request.category);

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
          request.isBusiness
              ? "Apply for Gold Badge 👑"
              : (request.isGovernment ? "Apply for Gray Badge 🏛️" : "Apply for Blue Badge 🔵"),
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
            StepProgressBar(currentStep: 4, labels: steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.reviewApplication,
                        style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Text(AppLocalizations.of(context)!.verifyThatAllInformationMatchesYourOffic,
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, request.isBusiness ? 'Applicant Personal Details' : 'Personal Details'),
                          _buildDetailRow(context, 'Full Name', request.fullName),
                          _buildDetailRow(context, 'Username', '@${request.username}'),
                          _buildDetailRow(context, 'Date of Birth', request.dateOfBirth == null ? '-' : '${request.dateOfBirth!.day.toString().padLeft(2, '0')}/${request.dateOfBirth!.month.toString().padLeft(2, '0')}/${request.dateOfBirth!.year}'),
                          _buildDetailRow(context, 'Phone Number', request.phone),
                          _buildDetailRow(context, 'Email Address', request.email),
                          
                          if (request.isBusiness) ...[
                            _buildSectionHeader(context, 'Business Credentials'),
                            if (request.nidNumber.isNotEmpty)
                              _buildDetailRow(context, 'Applicant NID Number', request.nidNumber),
                            if (request.websiteUrl.isNotEmpty)
                              _buildDetailRow(context, 'Website Link', request.websiteUrl),
                            if (request.businessEmail.isNotEmpty)
                              _buildDetailRow(context, 'Business Email', request.businessEmail),
                          ] else if (request.isGovernment) ...[
                            _buildSectionHeader(context, 'Government Credentials'),
                            if (request.nidNumber.isNotEmpty)
                              _buildDetailRow(context, 'Applicant NID Number', request.nidNumber),
                            if (request.govMinistryName.isNotEmpty)
                              _buildDetailRow(context, 'Ministry / Department', request.govMinistryName),
                            if (request.govDesignation.isNotEmpty)
                              _buildDetailRow(context, 'Designation', request.govDesignation),
                            if (request.govEmail.isNotEmpty)
                              _buildDetailRow(context, 'Gov Email', request.govEmail),
                            if (request.govWebsiteUrl.isNotEmpty)
                              _buildDetailRow(context, 'Gov Portal Website', request.govWebsiteUrl),
                          ],

                          _buildSectionHeader(context, 'Selected Subscription & Pricing'),
                          _buildDetailRow(
                            context,
                            'Selected Plan',
                            '${request.isGovernment ? "🏛️ Government Gray Badge" : (request.isBusiness ? "👑 Business Gold" : (request.selectedPlanId.contains("premium") ? "👑 Premium Plan" : "🔵 Basic Plan"))} (${request.selectedPlanId.contains("weekly") ? "Weekly" : request.selectedPlanId.contains("yearly") ? "Yearly" : request.selectedPlanId.contains("lifetime") ? "Lifetime" : "Monthly"})',
                          ),
                          _buildDetailRow(
                            context,
                            'Subscription Price',
                            _getFormattedPrice(request.selectedPlanId),
                          ),

                          _buildSectionHeader(
                            context,
                            request.isGovernment
                                ? 'Government Documents & NID'
                                : (request.isBusiness
                                    ? 'Business Documents & NID'
                                    : (request.isStudent ? 'Student Identity Documents' : 'Documents & Biometrics')),
                          ),
                          if (!request.isBusiness && !request.isGovernment)
                            _buildDetailRow(context, request.isStudent ? 'Student ID / Roll No' : 'NID Card Number', request.nidNumber),
                          
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (request.isBusiness) ...[
                                  if (request.tradeLicenseImage != null)
                                    SizedBox(width: 90, child: _buildImageThumb(context, 'Trade License', request.tradeLicenseImage?.path)),
                                  if (request.tinCertificateImage != null)
                                    SizedBox(width: 90, child: _buildImageThumb(context, 'TIN Certificate', request.tinCertificateImage?.path)),
                                  if (request.companyRegCertificateImage != null)
                                    SizedBox(width: 90, child: _buildImageThumb(context, 'Company Reg', request.companyRegCertificateImage?.path)),
                                ] else if (request.isGovernment) ...[
                                  if (request.govIdCardImage != null)
                                    SizedBox(width: 90, child: _buildImageThumb(context, 'Gov Employee ID', request.govIdCardImage?.path)),
                                  if (request.govAuthorizationLetterImage != null)
                                    SizedBox(width: 90, child: _buildImageThumb(context, 'Gov GO Order', request.govAuthorizationLetterImage?.path)),
                                ],
                                SizedBox(width: 90, child: _buildImageThumb(context, request.isStudent ? 'Student Front' : 'NID Front', request.nidFront?.path)),
                                SizedBox(width: 90, child: _buildImageThumb(context, request.isStudent ? 'Student Back' : 'NID Back', request.nidBack?.path)),
                                SizedBox(width: 90, child: _buildImageThumb(context, 'Selfie Scan', request.faceImage?.path)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () => setState(() => _confirmed = !_confirmed),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _confirmed
                              ? context.primaryAccent.withValues(alpha: 0.04)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _confirmed ? context.primaryAccent : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _confirmed,
                                activeColor: context.primaryAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) =>
                                    setState(() => _confirmed = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(AppLocalizations.of(context)!.iConfirmAllDocumentsAndCredentialsBelong,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, 
                                      color: context.textPrimary, 
                                      height: 1.45,
                                      fontWeight: _confirmed ? FontWeight.w600 : FontWeight.normal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: AppLocalizations.of(context)!.proceedToPayment,
                icon: Icons.arrow_forward_rounded,
                onPressed: _confirmed
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentScreen()),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.primaryAccent.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: context.border, width: 0.5)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
          color: context.primaryAccent,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: context.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageThumb(BuildContext context, String label, String? path) {
    return Column(
      children: [
        Container(
          height: 70,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF10132A) : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 0.8),
          ),
          child: path != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(path), fit: BoxFit.cover),
                )
              : Center(child: Icon(Icons.broken_image_outlined, size: 20, color: context.textMuted)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getFormattedPrice(String planId) {
    final plans = context.read<DatabaseService>().verificationPlans;
    final found = plans.firstWhere((p) => p['id'] == planId, orElse: () => {});
    if (found.isNotEmpty) {
      final priceNum = found['discount_price'] ?? found['price'];
      if (priceNum != null) {
        final double amount = (priceNum is num) ? priceNum.toDouble() : (double.tryParse(priceNum.toString()) ?? 0);
        String unit = 'Month';
        if (planId.contains('weekly')) unit = 'Week';
        if (planId.contains('yearly')) unit = 'Year';
        if (planId.contains('lifetime')) unit = 'Lifetime';
        return '৳${amount.toStringAsFixed(0)} / $unit (Incl. VAT)';
      }
    }

    final pricing = VerificationPlanPricing.getPlan(planId);
    String unit = 'Month';
    if (pricing.duration == 'weekly') unit = 'Week';
    if (pricing.duration == 'yearly') unit = 'Year';
    if (pricing.duration == 'lifetime') unit = 'Lifetime';
    return '৳${pricing.discountPrice.toStringAsFixed(0)} / $unit (Incl. VAT)';
  }
}
