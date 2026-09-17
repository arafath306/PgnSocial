import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../state/monetization_controller.dart';
import '../../utils/app_theme.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final String creatorId;
  final String creatorName;
  final double planPrice;

  const SubscriptionPaymentScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.planPrice,
  });

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _trxController = TextEditingController();
  bool _isSubmitting = false;

  static const _bkashNumber = '01313961899'; // Same admin bKash number

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
        content: Text(
          'bKash number copied to clipboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;

    setState(() => _isSubmitting = true);

    try {
      final mc = Provider.of<MonetizationController>(context, listen: false);
      await mc.submitSubscription(
        myProfile.id,
        widget.creatorId,
        _senderController.text.trim(),
        _trxController.text.trim().toUpperCase(),
        widget.planPrice,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription request sent! Pending admin approval.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: context.greenAccent,
        )
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscribe',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Supporter tier header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Support @${widget.creatorName}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Monthly Pass',
                              style: GoogleFonts.inter(
                                color: context.primaryAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '৳${widget.planPrice.toStringAsFixed(0)} / month',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _benefitItem(context, 'Full access to all exclusive subscriber-only threads'),
                      const SizedBox(height: 6),
                      _benefitItem(context, 'Supporter recognition badge on all creator threads'),
                      const SizedBox(height: 6),
                      _benefitItem(context, 'Directly supports independent creative work'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Steps
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, color: context.primaryAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'How to Pay with bKash',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '1. Open your bKash app and choose "Send Money"',
                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '2. Send exactly ৳${widget.planPrice.toStringAsFixed(0)} to this official recipient number:',
                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.scaffoldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _bkashNumber,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.1,
                                color: context.textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: _copyNumber,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: context.primaryAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tap to Copy',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: context.primaryAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '3. Fill in your sender number and Transaction ID (TrxID) below to activate your pass.',
                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form fields
                Text(
                  'bKash Sender Mobile Number',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _senderController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: '01XXXXXXXXX (11 digits)',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                    filled: true,
                    fillColor: context.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryAccent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your bKash mobile number';
                    final cleaned = val.trim().replaceAll(RegExp(r'\s+'), '');
                    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(cleaned)) {
                      return 'Please enter a valid 11-digit Bangladeshi mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Text(
                  'bKash Transaction ID (TrxID)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _trxController,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. BL9A4K8Z2D',
                    hintStyle: GoogleFonts.inter(color: context.textMuted, letterSpacing: 0),
                    filled: true,
                    fillColor: context.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryAccent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter the bKash TrxID';
                    if (val.trim().length < 8) return 'Please enter a valid TrxID (at least 8 characters)';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Trust reassurance note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: context.primaryAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Transactions are verified promptly. You will gain instant access to all subscriber-only content upon confirmation.',
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm & Submit Support',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitItem(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: context.primaryAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: context.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
