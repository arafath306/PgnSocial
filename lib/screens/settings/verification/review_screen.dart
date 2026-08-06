import 'package:dak/l10n/generated/app_localizations.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
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
            StepProgressBar(currentStep: 4, labels: steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                          _buildSectionHeader(context, 'Personal Details'),
                          _buildDetailRow(context, 'Full Name', request.fullName),
                          _buildDetailRow(context, 'Username', '@${request.username}'),
                          _buildDetailRow(context, 'Date of Birth', request.dateOfBirth == null ? '-' : '${request.dateOfBirth!.day.toString().padLeft(2, '0')}/${request.dateOfBirth!.month.toString().padLeft(2, '0')}/${request.dateOfBirth!.year}'),
                          _buildDetailRow(context, 'Phone Number', request.phone),
                          _buildDetailRow(context, 'Email Address', request.email),
                          
                          _buildSectionHeader(context, request.isStudent ? 'Student Identity Documents' : 'Documents & Biometrics'),
                          _buildDetailRow(context, request.isStudent ? 'Student ID / Roll No' : 'NID Card Number', request.nidNumber),
                          
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            child: Row(
                              children: [
                                Expanded(child: _buildImageThumb(context, request.isStudent ? 'Student Front' : 'NID Front', request.nidFront?.path)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildImageThumb(context, request.isStudent ? 'Student Back' : 'NID Back', request.nidBack?.path)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildImageThumb(context, 'Selfie Scan', request.faceImage?.path)),
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
}
