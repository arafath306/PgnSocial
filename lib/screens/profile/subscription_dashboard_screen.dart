import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../state/monetization_controller.dart';
import '../../utils/app_theme.dart';

class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _priceController = TextEditingController();
  bool _isSaving = false;

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
        _priceController.text = (mc.creatorSettings!['monthly_price'] ?? 0).toString();
      } else {
        _priceController.text = "0";
      }
    }
  }

  void _showRequestPayoutDialog(BuildContext context, MonetizationController mc) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;

    final amountController = TextEditingController(text: mc.estimatedMonthlyNet > 0 ? mc.estimatedMonthlyNet.toStringAsFixed(2) : "500");
    final accountController = TextEditingController();
    String selectedMethod = 'bKash';
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
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Request Payout',
                        style: GoogleFonts.inter(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: context.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E824C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E824C).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: Color(0xFF1E824C), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payouts will be processed and completed to your account within 24 hours.',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Select Payout Method',
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['bKash', 'Nagad', 'Bank Transfer'].map((method) {
                      final isSelected = selectedMethod == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedMethod = method),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E824C) : context.scaffoldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1E824C) : context.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                method,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.white : context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    selectedMethod == 'Bank Transfer' ? 'Bank Account Details (Name, Acc No, Branch)' : '$selectedMethod Mobile Number',
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accountController,
                    style: GoogleFonts.inter(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: selectedMethod == 'Bank Transfer' ? 'e.g. DBBL - 12345678 - Dhaka' : '017XXXXXXXX',
                      filled: true,
                      fillColor: context.scaffoldBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'Payout Amount (৳ BDT)',
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      filled: true,
                      fillColor: context.scaffoldBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        final amt = double.tryParse(amountController.text) ?? 0.0;
                        final acc = accountController.text.trim();
                        if (amt <= 0 || acc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid amount and account details')),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);
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
                              const SnackBar(
                                content: Text('Payout request submitted! Processing within 24 hours.'),
                                backgroundColor: Color(0xFF1E824C),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        } finally {
                          setModalState(() => isSubmitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E824C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Submit Payout Request', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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

  Future<void> _savePrice() async {
    final newPrice = double.tryParse(_priceController.text) ?? 0.0;
    if (newPrice < 0) return;
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;
    
    setState(() => _isSaving = true);
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
                  "Subscription price updated to ৳${newPrice.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E824C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update price: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmtCurrency(double amount) {
    return '৳ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final mc = Provider.of<MonetizationController>(context);
    final isLoading = mc.isLoadingDashboard || mc.isLoadingHistory;
    final primaryGreen = context.primaryAccent;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.insights_rounded, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Earnings & Monetization',
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: primaryGreen,
          labelColor: primaryGreen,
          unselectedLabelColor: context.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subscribers'),
            Tab(text: 'Payouts'),
            Tab(text: 'Locked Posts'),
          ],
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryGreen))
        : RefreshIndicator(
            color: primaryGreen,
            onRefresh: _loadDashboard,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, mc, primaryGreen),
                _buildSubscribersTab(context, mc, primaryGreen),
                _buildPayoutsTab(context, mc, primaryGreen),
                _buildLockedPostsTab(context, mc, primaryGreen),
              ],
            ),
          ),
    );
  }

  // ─── TAB 1: OVERVIEW ─────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, MonetizationController mc, Color primaryGreen) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Hero Banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen, primaryGreen.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ESTIMATED MONTHLY NET',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '90% Payout',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _fmtCurrency(mc.estimatedMonthlyNet),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestPayoutDialog(context, mc),
                  icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                  label: Text('Request Payout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.9), size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Payouts complete within 24 hours via bKash/Nagad/Bank.',
                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Financial Overview', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(context: context, title: 'Monthly Gross', value: _fmtCurrency(mc.estimatedMonthlyGross), icon: Icons.account_balance_wallet_outlined, accentColor: primaryGreen),
            _buildStatCard(context: context, title: 'Active Subscribers', value: '${mc.activeSubscribers}', icon: Icons.people_outline_rounded, accentColor: const Color(0xFF2563EB)),
            _buildStatCard(context: context, title: 'Lifetime Net', value: _fmtCurrency(mc.totalLifetimeNet), icon: Icons.trending_up_rounded, accentColor: const Color(0xFF7C3AED)),
            _buildStatCard(context: context, title: 'Platform Fee (10%)', value: _fmtCurrency(mc.estimatedMonthlyFee), icon: Icons.pie_chart_outline_rounded, accentColor: const Color(0xFFD97706)),
          ],
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Revenue Breakdown', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBreakdownRow(context: context, label: 'Gross Estimated Revenue', value: _fmtCurrency(mc.estimatedMonthlyGross), valueColor: context.textPrimary),
              const SizedBox(height: 12),
              _buildBreakdownRow(context: context, label: 'Platform Service Fee (10%)', value: '- ${_fmtCurrency(mc.estimatedMonthlyFee)}', valueColor: Colors.redAccent),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _buildBreakdownRow(context: context, label: 'Net Payable Income (90%)', value: _fmtCurrency(mc.estimatedMonthlyNet), valueColor: primaryGreen, isBold: true),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Subscription Pricing', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Subscription Fee (৳ BDT)', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: context.scaffoldBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: primaryGreen.withValues(alpha: 0.3))),
                child: Row(
                  children: [
                    Text('৳', style: GoogleFonts.inter(color: primaryGreen, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(border: InputBorder.none, hintText: '0.00', hintStyle: GoogleFonts.inter(color: context.textSecondary.withValues(alpha: 0.5))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePrice,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Save Pricing Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── TAB 2: SUBSCRIBERS ──────────────────────────────────────
  Widget _buildSubscribersTab(BuildContext context, MonetizationController mc, Color primaryGreen) {
    if (mc.subscriberDetailsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: context.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Subscribers Yet', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Subscribers will appear here when users join.', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: mc.subscriberDetailsList.length,
      itemBuilder: (context, index) {
        final item = mc.subscriberDetailsList[index];
        final sub = item['subscriber'] as Map<String, dynamic>?;
        final username = sub?['username'] ?? 'subscriber';
        final fullName = sub?['full_name'] ?? 'Subscriber User';
        final avatarUrl = sub?['avatar_url'] as String?;
        final price = (item['plan_price'] as num?)?.toDouble() ?? mc.monthlyPrice;
        final status = item['status'] as String? ?? 'active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryGreen.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty ? Text(username.substring(0, 1).toUpperCase(), style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@$username', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(fullName, style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtCurrency(price), style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'active' || status == 'approved' ? primaryGreen.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: status == 'active' || status == 'approved' ? primaryGreen : Colors.amber.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 3: PAYOUTS ──────────────────────────────────────────
  Widget _buildPayoutsTab(BuildContext context, MonetizationController mc, Color primaryGreen) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 24h Guarantee Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.flash_on_rounded, color: primaryGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('24-Hour Express Payout', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Payouts will be completed and processed to your designated bKash, Nagad, or Bank account within 24 hours.', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showRequestPayoutDialog(context, mc),
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
            label: Text('Request New Payout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text('Payout Request History', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (mc.payoutRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
            child: Center(child: Text('No payout requests submitted yet.', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13))),
          )
        else
          Column(
            children: mc.payoutRequests.map((req) {
              final status = req['status'] as String? ?? 'pending';
              final amount = (req['amount'] as num?)?.toDouble() ?? 0.0;
              final method = req['payout_method'] as String? ?? 'bKash';
              final details = req['account_details'] as String? ?? '';

              Color statusBg;
              Color statusFg;
              String statusText;
              IconData statusIcon;

              if (status == 'paid') {
                statusBg = const Color(0xFF1E824C).withValues(alpha: 0.12);
                statusFg = const Color(0xFF1E824C);
                statusText = 'Paid';
                statusIcon = Icons.check_circle_rounded;
              } else if (status == 'rejected') {
                statusBg = Colors.redAccent.withValues(alpha: 0.12);
                statusFg = Colors.redAccent;
                statusText = 'Rejected';
                statusIcon = Icons.cancel_rounded;
              } else {
                statusBg = const Color(0xFFD97706).withValues(alpha: 0.12);
                statusFg = const Color(0xFFD97706);
                statusText = 'Pending (within 24h)';
                statusIcon = Icons.hourglass_top_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                      child: Icon(statusIcon, color: statusFg, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$method - $details', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(statusText, style: GoogleFonts.inter(color: statusFg, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(_fmtCurrency(amount), style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ─── TAB 4: LOCKED POSTS ─────────────────────────────────────
  Widget _buildLockedPostsTab(BuildContext context, MonetizationController mc, Color primaryGreen) {
    if (mc.lockedPostsIncomeList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: context.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Locked Posts Found', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Create subscriber-only posts to see per-post earnings.', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: mc.lockedPostsIncomeList.length,
      itemBuilder: (context, index) {
        final item = mc.lockedPostsIncomeList[index];
        final snippet = item['content'] as String;
        final count = item['unlock_count'] as int;
        final totalIncome = (item['total_income'] as num).toDouble();
        final unlockers = item['unlockers'] as List<dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.border),
          ),
          child: ExpansionTile(
            shape: const Border(),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.lock_open_rounded, color: primaryGreen, size: 20),
            ),
            title: Text(
              snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '$count unlocks • ${_fmtCurrency(totalIncome)} Total Income',
              style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unlocked By:', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (unlockers.isEmpty)
                      Text('No specific buyers logged yet.', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12))
                    else
                      Column(
                        children: unlockers.map((u) {
                          final sub = u['subscriber'] as Map<String, dynamic>?;
                          final username = sub?['username'] ?? 'user';
                          final price = (u['plan_price'] as num?)?.toDouble() ?? mc.monthlyPrice;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('@$username unlocked this post', style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13)),
                                Text(_fmtCurrency(price), style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


