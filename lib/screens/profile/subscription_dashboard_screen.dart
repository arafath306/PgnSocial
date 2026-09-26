import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/database_service.dart';
import '../../state/monetization_controller.dart';
import '../../utils/app_theme.dart';
import '../create_thread_screen.dart';
import '../settings/verification/verification_intro_screen.dart';

/// Creator Studio screen for managing subscriptions, audience earnings,
/// payouts, and subscriber-only content.
class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _priceController = TextEditingController();
  bool _isSavingPrice = false;

  final DateFormat _fullDateFmt = DateFormat('d MMM yyyy, h:mm a');
  final DateFormat _shortDateFmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile != null) {
      final mc = Provider.of<MonetizationController>(context, listen: false);
      await mc.fetchFullMonetizationHistory(myProfile.id);
      if (mc.creatorSettings != null) {
        final price = (mc.creatorSettings!['monthly_price'] as num?)?.toDouble() ?? 0.0;
        _priceController.text = price > 0 ? price.toStringAsFixed(0) : "0";
      } else {
        _priceController.text = "0";
      }
    }
  }

  String _fmt(num amount) {
    if (amount % 1 == 0) {
      return '৳ ${amount.toStringAsFixed(0)}';
    }
    return '৳ ${amount.toStringAsFixed(2)}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recent';
    try {
      final dt = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      return _fullDateFmt.format(dt.toLocal());
    } catch (_) {
      return timestamp.toString();
    }
  }

  String _formatShortDate(dynamic timestamp) {
    if (timestamp == null) return 'Recent';
    try {
      final dt = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      return _shortDateFmt.format(dt.toLocal());
    } catch (_) {
      return timestamp.toString();
    }
  }

  String _maskAccount(String details) {
    final trimmed = details.trim();
    if (trimmed.length >= 10 && RegExp(r'^\d+$').hasMatch(trimmed)) {
      return '${trimmed.substring(0, 3)}••••${trimmed.substring(trimmed.length - 4)}';
    }
    if (trimmed.length > 8) {
      return '${trimmed.substring(0, 4)}...${trimmed.substring(trimmed.length - 3)}';
    }
    return trimmed;
  }

  Future<void> _savePrice() async {
    final newPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (newPrice < 0 || newPrice > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set a valid price between ৳0 and ৳10,000'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;

    setState(() => _isSavingPrice = true);
    try {
      final mc = Provider.of<MonetizationController>(context, listen: false);
      await mc.saveCreatorPrice(myProfile.id, newPrice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  newPrice > 0
                      ? 'Monthly tier updated to ${_fmt(newPrice)}/month'
                      : 'Subscriptions disabled (set to free)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: context.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update price: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPrice = false);
    }
  }

  void _showRequestPayoutDialog(BuildContext context, MonetizationController mc) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;

    final avail = mc.availableBalance;
    final initialAmount = avail >= 100 ? "100" : (avail > 0 ? avail.toStringAsFixed(0) : "50");
    final amountController = TextEditingController(text: initialAmount);
    final accountController = TextEditingController();
    String selectedMethod = 'bKash';
    String? validationError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdraw Earnings',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Available to cash out: ${_fmt(avail)}',
                            style: GoogleFonts.inter(
                              color: context.primaryAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: context.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Method Selector
                  Text(
                    'Withdraw To',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['bKash', 'Nagad', 'Bank Transfer'].map((method) {
                      final isSelected = selectedMethod == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedMethod = method;
                              validationError = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.primaryAccent.withValues(alpha: 0.12)
                                  : context.scaffoldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? context.primaryAccent : context.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                method,
                                style: GoogleFonts.inter(
                                  color: isSelected ? context.primaryAccent : context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Account Number / Details
                  Text(
                    selectedMethod == 'Bank Transfer'
                        ? 'Bank Account (Bank name, Acc No, Branch)'
                        : '$selectedMethod Mobile Number (11 digits)',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accountController,
                    keyboardType: selectedMethod == 'Bank Transfer'
                        ? TextInputType.text
                        : TextInputType.phone,
                    style: GoogleFonts.inter(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: selectedMethod == 'Bank Transfer'
                          ? 'e.g. City Bank, 1102938475, Gulshan Branch'
                          : '01XXXXXXXXX',
                      hintStyle: GoogleFonts.inter(color: context.textMuted),
                      filled: true,
                      fillColor: context.scaffoldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount (BDT)',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Min. ৳50.00',
                        style: GoogleFonts.inter(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      prefixStyle: GoogleFonts.inter(
                        color: context.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: context.scaffoldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  ),
                  const SizedBox(height: 10),

                  // Quick selection chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (avail >= 100)
                        _quickAmountChip('৳100', () {
                          setModalState(() => amountController.text = '100');
                        }, context),
                      if (avail >= 500)
                        _quickAmountChip('৳500', () {
                          setModalState(() => amountController.text = '500');
                        }, context),
                      if (avail >= 1000)
                        _quickAmountChip('৳1,000', () {
                          setModalState(() => amountController.text = '1000');
                        }, context),
                      if (avail > 0)
                        _quickAmountChip('All (${_fmt(avail)})', () {
                          setModalState(() => amountController.text = avail.toStringAsFixed(0));
                        }, context, isHighlight: true),
                    ],
                  ),

                  if (validationError != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            validationError!,
                            style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Payout notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, color: context.primaryAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Withdrawal requests are reviewed and sent within 24–48 hours directly to your account.',
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              final acc = accountController.text.trim();

                              if (amt < 50) {
                                setModalState(() => validationError = 'Minimum cashout amount is ৳50.00');
                                return;
                              }

                              if (amt > avail && avail > 0) {
                                setModalState(() => validationError = 'Amount cannot exceed available balance (${_fmt(avail)})');
                                return;
                              }

                              if (acc.isEmpty) {
                                setModalState(() => validationError = 'Please enter your account details');
                                return;
                              }

                              if (selectedMethod != 'Bank Transfer') {
                                final phoneRegex = RegExp(r'^01[3-9]\d{8}$');
                                if (!phoneRegex.hasMatch(acc.replaceAll(RegExp(r'\s+'), ''))) {
                                  setModalState(() => validationError = 'Please enter a valid 11-digit Bangladeshi mobile number');
                                  return;
                                }
                              }

                              setModalState(() {
                                isSubmitting = true;
                                validationError = null;
                              });

                              try {
                                await mc.requestPayout(
                                  userId: myProfile.id,
                                  amount: amt,
                                  method: selectedMethod,
                                  accountDetails: acc,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Withdrawal request for ${_fmt(amt)} submitted successfully!',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: context.primaryAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  validationError = e.toString().replaceAll('Exception: ', '');
                                  isSubmitting = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Confirm Withdrawal',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickAmountChip(String text, VoidCallback onTap, BuildContext context, {bool isHighlight = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isHighlight
              ? context.primaryAccent.withValues(alpha: 0.12)
              : context.scaffoldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? context.primaryAccent : context.border,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isHighlight ? context.primaryAccent : context.textSecondary,
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showPlatformFeeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: context.primaryAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              'How Pigeon Fees Work',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You keep 90% of all subscription revenue. Pigeon retains a modest 10% platform fee to cover:\n\n'
              '• Secure payment processing & mobile wallet gateways\n'
              '• Media storage, image compression, and streaming servers\n'
              '• Fraud prevention and account protection\n\n'
              'There are no hidden deductions or withdrawal fees.',
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.primaryAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final myProfile = db.myProfile;
    final primaryAccent = context.primaryAccent;

    // Strict gate: Only verified badge holders can access Creator Studio
    if (myProfile != null && !myProfile.canMonetize) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Creator Studio',
            style: GoogleFonts.inter(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF0095F6),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verified Badge Required',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Creator Studio and monetization features are exclusively available to verified badge holders. Get verified to unlock subscriptions, earn revenue from your audience, and post subscriber-only threads.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VerificationIntroScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Get Verified Badge',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mc = Provider.of<MonetizationController>(context);
    final isLoading = mc.isLoadingDashboard || mc.isLoadingHistory;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.stars_rounded, color: primaryAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator Studio',
                  style: GoogleFonts.inter(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  mc.monthlyPrice > 0
                      ? 'Tier: ${_fmt(mc.monthlyPrice)}/mo • ${mc.activeSubscribers} members'
                      : 'Subscription tier not set',
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: primaryAccent,
          indicatorWeight: 2.5,
          labelColor: primaryAccent,
          unselectedLabelColor: context.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 18)),
            Tab(text: 'Supporters', icon: Icon(Icons.favorite_outline_rounded, size: 18)),
            Tab(text: 'Payouts', icon: Icon(Icons.payments_outlined, size: 18)),
            Tab(text: 'Exclusive Posts', icon: Icon(Icons.lock_outline_rounded, size: 18)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryAccent, strokeWidth: 2.5))
          : RefreshIndicator(
              color: primaryAccent,
              onRefresh: _loadDashboard,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(context, mc),
                  _buildSubscribersTab(context, mc),
                  _buildPayoutsTab(context, mc),
                  _buildLockedPostsTab(context, mc),
                ],
              ),
            ),
    );
  }

  // ─── TAB 1: OVERVIEW ─────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, MonetizationController mc) {
    final avail = mc.availableBalance;
    final primaryAccent = context.primaryAccent;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        // Available Balance Card
        // Available Balance Card (Crisp modern card, no bubbly curves)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Available to Withdraw',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showPlatformFeeInfo(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '90% Payout',
                            style: GoogleFonts.inter(
                              color: primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.info_outline_rounded, color: primaryAccent, size: 13),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _fmt(avail),
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestPayoutDialog(context, mc),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: Text(
                    'Withdraw Earnings',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Summary footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Review: ${_fmt(mc.pendingPayoutAmount)}',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Lifetime Net: ${_fmt(mc.totalLifetimeNet)}',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Performance Summary (Clean open layout, no rounded box)
        Text(
          'Performance Summary',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context: context,
                title: 'Active Members',
                value: '${mc.activeSubscribers}',
                icon: Icons.favorite_rounded,
                accentColor: primaryAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricItem(
                context: context,
                title: 'Monthly Run-Rate',
                value: _fmt(mc.estimatedMonthlyGross),
                icon: Icons.trending_up_rounded,
                accentColor: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context: context,
                title: 'Total Withdrawn',
                value: _fmt(mc.paidPayoutAmount),
                icon: Icons.verified_rounded,
                accentColor: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricItem(
                context: context,
                title: 'In Review',
                value: _fmt(mc.pendingPayoutAmount),
                icon: Icons.hourglass_top_rounded,
                accentColor: const Color(0xFFD97706),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Revenue Breakdown (Clean open layout, no rounded box)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estimated Monthly Earnings',
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.help_outline_rounded, size: 18, color: context.textMuted),
              onPressed: () => _showPlatformFeeInfo(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildBreakdownRow(
          context: context,
          label: 'Gross Member Revenue',
          value: _fmt(mc.estimatedMonthlyGross),
          valueColor: context.textPrimary,
        ),
        const SizedBox(height: 8),
        _buildBreakdownRow(
          context: context,
          label: 'Platform Service Fee (10%)',
          value: '- ${_fmt(mc.estimatedMonthlyFee)}',
          valueColor: Colors.redAccent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
        ),
        _buildBreakdownRow(
          context: context,
          label: 'Your Share (90%)',
          value: _fmt(mc.estimatedMonthlyNet),
          valueColor: primaryAccent,
          isBold: true,
        ),

        const SizedBox(height: 24),

        // Interactive Pricing Section (Clean open layout, no outer rounded box)
        _buildPricingCard(context, mc),

        const SizedBox(height: 20),

        // Creator Tip (clean inline hint, no artificial bordered box)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: primaryAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Creator Pro-tip: ',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Creators who publish 2–3 public posts alongside 1 exclusive subscriber-only thread per week see 3x higher subscriber retention over 6 months.',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // Pricing Section (clean open layout, no outer card box, no bubbly corners)
  Widget _buildPricingCard(BuildContext context, MonetizationController mc) {
    final primaryAccent = context.primaryAccent;
    final currentInputPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final takeHomePerSub = (currentInputPrice * 0.90).clamp(0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Subscription Tier',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Supporters pay this monthly fee to unlock all your exclusive posts.',
          style: GoogleFonts.inter(
            color: context.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),

        // Price field (crisp border, radius 8, not bubbly)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Text(
                '৳',
                style: GoogleFonts.inter(
                  color: primaryAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
              ),
              Text(
                '/ month',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Presets (crisp radius 6, not bubbly)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [99, 199, 299, 499].map((preset) {
            final isCurrent = currentInputPrice == preset;
            return InkWell(
              onTap: () {
                setState(() {
                  _priceController.text = preset.toString();
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? primaryAccent.withValues(alpha: 0.12)
                      : context.cardBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrent ? primaryAccent : context.border,
                  ),
                ),
                child: Text(
                  '৳$preset',
                  style: GoogleFonts.inter(
                    color: isCurrent ? primaryAccent : context.textSecondary,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Live projection text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: primaryAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentInputPrice > 0
                      ? 'You take home ${_fmt(takeHomePerSub)} per subscriber each month after the 10% fee.'
                      : 'Set an amount above ৳0 to enable monthly subscriptions.',
                  style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Save button (crisp radius 8)
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isSavingPrice ? null : _savePrice,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSavingPrice
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Save Subscription Tier',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: SUBSCRIBERS ──────────────────────────────────────
  Widget _buildSubscribersTab(BuildContext context, MonetizationController mc) {
    if (mc.subscriberDetailsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.primaryAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_outline_rounded, size: 48, color: context.primaryAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Build Your Supporter Community',
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share exclusive posts, early updates, and private discussions. Supporters who subscribe to your tier will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  'Write an Exclusive Post',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${mc.subscriberDetailsList.length} Active Supporters',
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Monthly: ${_fmt(mc.estimatedMonthlyGross)}',
              style: GoogleFonts.inter(
                color: context.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mc.subscriberDetailsList.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 52,
            color: context.border.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final item = mc.subscriberDetailsList[index];
            final sub = item['subscriber'] as Map<String, dynamic>?;
            final username = sub?['username'] ?? 'subscriber';
            final fullName = sub?['full_name'] ?? 'Pigeon Supporter';
            final avatarUrl = sub?['avatar_url'] as String?;
            final price = (item['plan_price'] as num?)?.toDouble() ?? mc.monthlyPrice;
            final status = (item['status'] as String? ?? 'active').toLowerCase();
            final createdAt = item['created_at'];

            final isActive = status == 'active' || status == 'approved';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.primaryAccent.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            username.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(
                              color: context.primaryAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username • Joined ${_formatShortDate(createdAt)}',
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(price),
                        style: GoogleFonts.inter(
                          color: context.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? context.primaryAccent : Colors.amber.shade700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Member' : 'Pending',
                            style: GoogleFonts.inter(
                              color: isActive ? context.primaryAccent : Colors.amber.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── TAB 3: PAYOUTS ──────────────────────────────────────────
  Widget _buildPayoutsTab(BuildContext context, MonetizationController mc) {
    final avail = mc.availableBalance;
    final primaryAccent = context.primaryAccent;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        // Available withdrawal card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available for Cashout',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _fmt(avail),
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestPayoutDialog(context, mc),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: Text(
                    'Request Withdrawal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // How Withdrawals Work (clean open section, no boxed card)
        Text(
          'How Withdrawals Work',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPayoutStep(
          context,
          stepNumber: '1',
          title: 'Submit Request',
          description: 'Choose bKash, Nagad, or Bank Transfer and enter your details.',
        ),
        const SizedBox(height: 10),
        _buildPayoutStep(
          context,
          stepNumber: '2',
          title: 'Review & Verification',
          description: 'Our team verifies your account within 24–48 hours to protect funds.',
        ),
        const SizedBox(height: 10),
        _buildPayoutStep(
          context,
          stepNumber: '3',
          title: 'Direct Deposit',
          description: 'Money is deposited with an SMS confirmation to your wallet.',
        ),

        const SizedBox(height: 22),

        // History
        Text(
          'Withdrawal History',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        if (mc.payoutRequests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Center(
              child: Text(
                'No withdrawals requested yet. Once your available balance reaches ৳50, you can request a cashout anytime.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mc.payoutRequests.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 44,
              color: context.border.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final req = mc.payoutRequests[index];
              final status = (req['status'] as String? ?? 'pending').toLowerCase();
              final amount = (req['amount'] as num?)?.toDouble() ?? 0.0;
              final method = req['payout_method'] as String? ?? 'bKash';
              final details = req['account_details'] as String? ?? '';
              final createdAt = req['created_at'];

              Color statusBg;
              Color statusFg;
              String statusLabel;
              IconData statusIcon;

              if (status == 'paid' || status == 'approved' || status == 'completed') {
                statusBg = primaryAccent.withValues(alpha: 0.12);
                statusFg = primaryAccent;
                statusLabel = 'Completed';
                statusIcon = Icons.check_circle_rounded;
              } else if (status == 'rejected' || status == 'declined') {
                statusBg = Colors.redAccent.withValues(alpha: 0.12);
                statusFg = Colors.redAccent;
                statusLabel = 'Declined';
                statusIcon = Icons.cancel_rounded;
              } else {
                statusBg = const Color(0xFFD97706).withValues(alpha: 0.12);
                statusFg = const Color(0xFFD97706);
                statusLabel = 'In Review';
                statusIcon = Icons.hourglass_top_rounded;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusFg, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$method • ${_maskAccount(details)}',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(createdAt),
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(amount),
                          style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            color: statusFg,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPayoutStep(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: context.primaryAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.inter(
                color: context.primaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TAB 4: LOCKED POSTS ─────────────────────────────────────
  Widget _buildLockedPostsTab(BuildContext context, MonetizationController mc) {
    if (mc.lockedPostsIncomeList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.primaryAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_open_rounded, size: 48, color: context.primaryAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Publish Exclusive Content',
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When creating any thread, turn on "Subscribers only" to make it exclusive to your members. Your locked posts and unlock history will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Create Exclusive Post',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${mc.lockedPostsIncomeList.length} Exclusive Threads',
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: context.primaryAccent, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
                );
              },
              tooltip: 'Write new exclusive thread',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mc.lockedPostsIncomeList.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 48,
            color: context.border.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final item = mc.lockedPostsIncomeList[index];
            final snippet = item['content'] as String;
            final count = item['unlock_count'] as int;
            final totalIncome = (item['total_income'] as num).toDouble();
            final unlockers = item['unlockers'] as List<dynamic>;
            final createdAt = item['created_at'];

            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              shape: const Border(),
              leading: Icon(Icons.lock_outline_rounded, color: context.primaryAccent, size: 20),
              title: Text(
                snippet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '$count unlocks • ${_fmt(totalIncome)} revenue • ${_formatShortDate(createdAt)}',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 11,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 48, right: 12, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supporters Who Unlocked This:',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (unlockers.isEmpty)
                        Text(
                          'No purchases yet. Subscribers unlock exclusive threads automatically.',
                          style: GoogleFonts.inter(color: context.textMuted, fontSize: 12),
                        )
                      else
                        Column(
                          children: unlockers.map((u) {
                            final sub = u['subscriber'] as Map<String, dynamic>?;
                            final username = sub?['username'] ?? 'supporter';
                            final price = (u['plan_price'] as num?)?.toDouble() ?? mc.monthlyPrice;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '@$username',
                                    style: GoogleFonts.inter(
                                      color: context.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _fmt(price),
                                    style: GoogleFonts.inter(
                                      color: context.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow({
    required BuildContext context,
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isBold ? context.textPrimary : context.textSecondary,
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
