import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../models/verification_plan_pricing.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/pigeon_text_field.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'pending_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _trxController = TextEditingController();

  static const _bkashNumber = '01313961899';

  @override
  void dispose() {
    _senderController.dispose();
    _trxController.dispose();
    super.dispose();
  }

  void _copyNumber() {
    Clipboard.setData(const ClipboardData(text: _bkashNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.bkashNumberCopiedToClipboard,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final controller = context.read<VerificationController>();
    controller.updatePaymentInfo(
      bkashSenderNumber: _senderController.text.trim(),
      bkashTrxId: _trxController.text.trim().toUpperCase(),
    );

    try {
      await controller.submitApplication(dbService);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PendingScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submission failed: $e',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final req = controller.request;
    final steps = VerificationController.getSteps(req.category);

    final isSubmitting = controller.isSubmitting;
    final selectedPlanId = controller.request.selectedPlanId;
    final isDark = context.isDarkMode;

    final pricing = VerificationPlanPricing.getPlan(selectedPlanId);

    final verificationPlans = context.select<DatabaseService, List<Map<String, dynamic>>>((db) => db.verificationPlans);

    final dbPlan = verificationPlans.firstWhere(
      (p) => p['id'] == selectedPlanId,
      orElse: () => {},
    );

    final String planName = (dbPlan['name'] != null && dbPlan['name'].toString().isNotEmpty)
        ? dbPlan['name'].toString()
        : pricing.name;

    final double basePrice = dbPlan['price'] != null
        ? (dbPlan['price'] as num).toDouble()
        : pricing.basePrice;

    final double payableAmount = dbPlan['discount_price'] != null
        ? (dbPlan['discount_price'] as num).toDouble()
        : (dbPlan['price'] != null ? (dbPlan['price'] as num).toDouble() : pricing.discountPrice);

    final double discount = basePrice > payableAmount ? (basePrice - payableAmount) : 0.0;
    final double vatAmount = (payableAmount * 0.05) / 1.05;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          req.isBusiness
              ? "Apply for Gold Badge 👑"
              : (req.isGovernment ? "Apply for Gray Badge 🏛️" : "Apply for Blue Badge 🔵"),
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
            StepProgressBar(currentStep: 5, labels: steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.verifyPay,
                          style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 6),
                      Text(AppLocalizations.of(context)!.completeYourVerificationBySendingTheBkas,
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 20),

                      // 1. Premium Invoice Statement Receipt Card
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
                          children: [
                            // Invoice header banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: context.primaryAccent.withValues(alpha: 0.06),
                                border: Border(bottom: BorderSide(color: context.border, width: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.membershipInvoice,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: context.primaryAccent,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: context.primaryAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      selectedPlanId.split('_').take(3).join(' ').toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        color: context.primaryAccent,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Line Items
                            _buildInvoiceRow('Subscription Plan', planName, false),
                            _buildInvoiceRow('Base Price', '৳${basePrice.toStringAsFixed(0)}', false),
                            _buildInvoiceRow('Promo Discount', '-৳${discount.toStringAsFixed(0)}', false, valueColor: const Color(0xFF10B981)),
                            _buildInvoiceRow('Govt. VAT (5% Incl.)', '৳${vatAmount.toStringAsFixed(2)}', false, valueColor: const Color(0xFF64748B)),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildInvoiceRow('Total Payable (BDT)', '৳${payableAmount.toStringAsFixed(0)}', true, valueColor: context.primaryAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. bKash payment box
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2136E).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2136E).withValues(alpha: 0.15), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE2136E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.sendBkashPayment,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFE2136E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Send ৳${payableAmount.toStringAsFixed(0)} to this personal bKash number:',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textPrimary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF10132A) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.border, width: 0.8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _bkashNumber,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _copyNumber,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE2136E).withValues(alpha: 0.1),
                                      foregroundColor: const Color(0xFFE2136E),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: Text(AppLocalizations.of(context)!.copy,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Inputs section
                      Text(AppLocalizations.of(context)!.enterPaymentDetails,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: context.textPrimary,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 12),
                      
                      PigeonTextField(
                        label: AppLocalizations.of(context)!.senderBkashAccountNumber,
                        hint: '01XXXXXXXXX',
                        controller: _senderController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icon(
                          Icons.phone_iphone,
                          size: 18,
                          color: context.textMuted,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter the number you paid from';
                          }
                          final phoneRegExp = RegExp(r'^(?:\+88|88)?(01[3-9]\d{8})$');
                          if (!phoneRegExp.hasMatch(v.trim())) {
                            return 'Enter a valid Bangladeshi phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      PigeonTextField(
                        label: AppLocalizations.of(context)!.bkashTransactionIdTrxid,
                        hint: 'e.g. 9F7K2L1A0B',
                        controller: _trxController,
                        prefixIcon: Icon(
                          Icons.confirmation_number_outlined,
                          size: 18,
                          color: context.textMuted,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter the TrxID from your bKash SMS';
                          }
                          final trxRegExp = RegExp(r'^[A-Z0-9]{8,12}$');
                          if (!trxRegExp.hasMatch(v.trim().toUpperCase())) {
                            return 'Enter a valid bKash transaction ID';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: AppLocalizations.of(context)!.submitVerification,
                icon: Icons.check_circle_outline_rounded,
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : _onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, bool isTotal, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTotal ? 14 : 12.5,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
                color: isTotal ? context.textPrimary : context.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: isTotal ? 17 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
                color: valueColor ?? context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
