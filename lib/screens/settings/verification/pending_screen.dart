import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/verification_request.dart';
import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../main_screen.dart';
import 'personal_details_screen.dart';
import 'verification_success_screen.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Refresh status automatically on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh(silent: true);
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _checking = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final controller = context.read<VerificationController>();
    final status = await controller.checkStatus(dbService);
    if (!silent) setState(() => _checking = false);

    if (!mounted) return;

    if (status == VerificationStatus.approved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerificationSuccessScreen()),
      );
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == VerificationStatus.rejected
                ? 'Your request has been rejected. Please review details.'
                : 'Still under review — check back later.',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<VerificationController>().request;
    final isRejected = request.status == VerificationStatus.rejected;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(AppLocalizations.of(context)!.verificationStatus,
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Header Illustration Banner (Full-Width, Edge-to-Edge)
              if (!isRejected)
                Container(
                  width: double.infinity,
                  height: 220,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF0F1123) : Colors.white,
                    border: Border(bottom: BorderSide(color: context.border, width: 0.5)),
                  ),
                  child: ClipRRect(
                    child: Image.asset(
                      'assets/under_review_illustration.png',
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                
                Text(
                  isRejected
                      ? 'Application Rejected'
                      : "Verification Under Review",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                      letterSpacing: -0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  isRejected
                      ? (request.rejectionReason ??
                          'There was an issue with your documents or payment. '
                              'Please check the details and try again.')
                      : 'Our team is currently validating your documents and bKash payment. '
                          'This usually takes 24–48 hours. We\'ll issue the Blue '
                          'Badge on your profile as soon as it is approved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: context.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),

                // 2. Timeline Step Progress Details (Facebook/Meta Verified Style)
                if (!isRejected) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.verificationTimeline,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTimelineRow('Step 1: Application Received', 'Completed', true, true),
                        _buildTimelineRow('Step 2: bKash Payment Check', 'Processing', false, true),
                        _buildTimelineRow('Step 3: Document Compliance Review', 'Pending', false, false),
                        _buildTimelineRow('Step 4: Badge Activation', 'Pending', false, false, isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Metadata Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _StatusRow(label: AppLocalizations.of(context)!.usernameHandle, value: '@${request.username}'),
                      _StatusRow(
                          label: AppLocalizations.of(context)!.bkashTrxid, value: request.bkashTrxId.isEmpty ? '-' : request.bkashTrxId),
                      _StatusRow(
                        label: AppLocalizations.of(context)!.statusCode,
                        value: isRejected ? 'Rejected' : 'Pending Review',
                        valueColor: isRejected ? Colors.red : context.primaryAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                if (isRejected)
                  PigeonPrimaryButton(
                    label: AppLocalizations.of(context)!.reapplyForBlueBadge,
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      final controller = context.read<VerificationController>();
                      controller.resetApplication();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PersonalDetailsScreen()),
                      );
                    },
                  )
                else
                  PigeonPrimaryButton(
                    label: AppLocalizations.of(context)!.checkStatusUpdate,
                    icon: Icons.refresh_rounded,
                    isLoading: _checking,
                    onPressed: () => _refresh(silent: false),
                  ),
                const SizedBox(height: 12),
                PigeonPrimaryButton(
                  label: AppLocalizations.of(context)!.backToFeedHome,
                  outlined: true,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildTimelineRow(String title, String status, bool isChecked, bool isActive, {bool isLast = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color stepColor = context.textMuted;
    if (isChecked) {
      stepColor = const Color(0xFF10B981);
    } else if (isActive) {
      stepColor = context.primaryAccent;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked 
                    ? const Color(0xFF10B981) 
                    : (isActive ? context.primaryAccent : Colors.transparent),
                border: Border.all(
                  color: isChecked 
                      ? const Color(0xFF10B981) 
                      : (isActive ? context.primaryAccent : context.border), 
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isChecked 
                  ? const Icon(Icons.check, size: 12, color: Colors.white) 
                  : (isActive ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)) : const SizedBox()),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 38,
                color: isChecked ? const Color(0xFF10B981) : context.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: stepColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(
                  color: valueColor ?? context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
