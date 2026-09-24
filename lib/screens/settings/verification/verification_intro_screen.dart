import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/profile.dart';
import '../../../models/verification_plan_pricing.dart';
import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import 'personal_details_screen.dart';

class VerificationIntroScreen extends StatefulWidget {
  const VerificationIntroScreen({super.key});

  @override
  State<VerificationIntroScreen> createState() => _VerificationIntroScreenState();
}

class _VerificationIntroScreenState extends State<VerificationIntroScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 State: Category
  String _selectedCategory = 'general'; // 'general', 'business', 'government'

  // Step 2 State: Duration & Tier
  String _selectedDuration = 'monthly'; // 'weekly', 'monthly', 'yearly', 'lifetime'
  String _selectedTier = 'premium'; // 'basic', 'premium'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<DatabaseService>();
      if (db.myProfile == null) {
        db.fetchMyProfile();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _proceedToDetails();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _proceedToDetails([String? tierId]) {
    final tier = tierId ?? _selectedTier;
    final controller = context.read<VerificationController>();
    controller.selectCategory(_selectedCategory);
    controller.selectPlan('${_selectedCategory}_${_selectedDuration}_$tier');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
    );
  }

  Color get _categoryColor {
    if (_selectedCategory == 'business') return const Color(0xFFD97706);
    if (_selectedCategory == 'government' || _selectedCategory == 'media') {
      return const Color(0xFF64748B);
    }
    return const Color(0xFF0095F6);
  }


  VerificationPlanPricing _getPlan(String tier) {
    return VerificationPlanPricing.getPlan(
      '${_selectedCategory}_${_selectedDuration}_$tier',
    );
  }

  String _getDurationSuffix() {
    switch (_selectedDuration) {
      case 'weekly':
        return '/ week';
      case 'yearly':
        return '/ year';
      case 'lifetime':
        return '/ one-time';
      case 'monthly':
      default:
        return '/ month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final myProfile = dbService.myProfile;
    if (myProfile != null && myProfile.isVerified) {
      return _buildVerifiedDashboard(context, myProfile);
    }

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary,
              size: 18,
            ),
            onPressed: _previousStep,
          ),
          title: _currentStep == 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Pigeon Verified",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0095F6),
                      size: 18,
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Select Plan",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified_rounded,
                      color: _categoryColor,
                      size: 19,
                    ),
                  ],
                ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            children: [
              _buildScreen1CategorySelection(context),
              _buildScreen2SubscriptionPlans(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 1: Choose Category & Benefits
  // ==========================================
  Widget _buildScreen1CategorySelection(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final myProfile = dbService.myProfile;
    final avatarUrl = myProfile?.avatarUrl;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                const SizedBox(height: 6),

                // User Profile Picture Preview with Dynamic Badge Overlay
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _categoryColor.withValues(alpha: 0.45),
                            width: 2.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _categoryColor.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(41),
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 82,
                                  height: 82,
                                  placeholder: (context, url) => Container(
                                    color: context.isDarkMode
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: _categoryColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      size: 44,
                                      color: _categoryColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: _categoryColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 44,
                                    color: _categoryColor,
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: context.scaffoldBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: _categoryColor,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  "Get Pigeon Verified",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  "Select your category to build trust and unlock monetization.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),

                // Section Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose Category",
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Card 1: General / Creator (Blue Badge)
                _buildCategoryCard(
                  context,
                  id: 'general',
                  badgeColor: const Color(0xFF0095F6),
                  title: "General / Creator",
                  subtitle: "For creators, influencers, writers, and public figures.",
                  perks: ["Creator Studio", "Blue Badge", "Priority Feed"],
                ),
                const SizedBox(height: 12),

                // Card 2: Business / Corporate (Gold Badge)
                _buildCategoryCard(
                  context,
                  id: 'business',
                  badgeColor: const Color(0xFFD97706),
                  title: "Business / Corporate",
                  subtitle: "For registered businesses, brands, and startups.",
                  perks: ["Brand Trust", "Gold Badge", "Priority Payouts"],
                ),
                const SizedBox(height: 12),

                // Card 3: Government / Official (Gray Badge)
                _buildCategoryCard(
                  context,
                  id: 'government',
                  badgeColor: const Color(0xFF64748B),
                  title: "Government / Official",
                  subtitle: "For public institutions, state officials, and media.",
                  perks: ["Official Mark", "Gray Badge", "Authority Boost"],
                ),
                const SizedBox(height: 22),

                // Key Verification Benefits Overview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: _categoryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Included With All Badges",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMiniPerk(
                        icon: Icons.shield_outlined,
                        title: "Official Verification Badge",
                        desc: "Shows followers you are authentic and impersonation-protected.",
                      ),
                      const SizedBox(height: 10),
                      _buildMiniPerk(
                        icon: Icons.monetization_on_outlined,
                        title: "Creator Studio & Monetization",
                        desc: "Exclusive access to audience subscriptions and paid posts.",
                      ),
                      const SizedBox(height: 10),
                      _buildMiniPerk(
                        icon: Icons.trending_up_rounded,
                        title: "Algorithmic Priority Boost",
                        desc: "Higher visibility across timelines, explore, and comments.",
                      ),
                      const SizedBox(height: 10),
                      _buildMiniPerk(
                        icon: Icons.support_agent_rounded,
                        title: "Fast 24/7 Priority Support",
                        desc: "Dedicated support team for account assistance and quick reviews.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Bottom Continue Button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            border: Border(top: BorderSide(color: context.border, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _categoryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Next: Choose Subscription Plan",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Cancel or switch plans anytime. Secure payment processing.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String id,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required List<String> perks,
  }) {
    final isSelected = _selectedCategory == id;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? badgeColor.withValues(alpha: isDark ? 0.15 : 0.05)
              : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? badgeColor : context.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_rounded,
              color: badgeColor,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? badgeColor : context.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: context.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: perks.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPerk({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _categoryColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: "$title: ",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              children: [
                TextSpan(
                  text: desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 2: Choose Your Subscription Plan
  // ==========================================
  Widget _buildScreen2SubscriptionPlans(BuildContext context) {
    final basicPlan = _getPlan('basic');
    final premiumPlan = _getPlan('premium');
    final isDark = context.isDarkMode;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: _categoryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} Verification",
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Pick your plan duration and tier.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Segmented Duration Tab Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildDurationTab("weekly", "Weekly"),
                      _buildDurationTab("monthly", "Monthly", isHighlight: true),
                      _buildDurationTab("yearly", "Yearly", badgeText: "SAVE 20%"),
                      _buildDurationTab("lifetime", "Lifetime", badgeText: "VIP"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Basic Plan Card
                _buildPlanCard(
                  context: context,
                  tierId: 'basic',
                  title: 'Basic Plan',
                  plan: basicPlan,
                  perks: [
                    "${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} Verified Badge",
                    "Creator Studio & Monetization Access",
                    "Official Authenticity Check",
                    "Anti-Impersonation Protection",
                  ],
                  isPopular: false,
                ),
                const SizedBox(height: 16),

                // 2. Premium Plan Card (With Glowing Border)
                _buildPlanCard(
                  context: context,
                  tierId: 'premium',
                  title: 'Premium VIP Plan',
                  plan: premiumPlan,
                  perks: [
                    "${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} Verified Badge",
                    "Creator Studio & Monetization Access",
                    "Anonymous Posts (Incognito Mode)",
                    "Voice Note Audio Posts",
                    "Maximum Feed Algorithm Boost",
                    "Screenshot Protection on Content",
                    "Priority 24/7 Dedicated Support",
                  ],
                  isPopular: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Secure verification process. Automatic receipt generated on submission.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationTab(
    String durationId,
    String label, {
    bool isHighlight = false,
    String? badgeText,
  }) {
    final isSelected = _selectedDuration == durationId;
    final isDark = context.isDarkMode;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = durationId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? context.textPrimary
                      : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String tierId,
    required String title,
    required VerificationPlanPricing plan,
    required List<String> perks,
    required bool isPopular,
  }) {
    final isSelected = _selectedTier == tierId;
    final isDark = context.isDarkMode;
    final hasDiscount = plan.discountPrice < plan.basePrice;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tierId),
      child: AnimatedGlowingBorder(
        isSelected: isSelected,
        glowColor: _categoryColor,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? _categoryColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _categoryColor,
                        ),
                      ),
                      const Spacer(),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const LiveFireEmoji(),
                              Text(
                                "RECOMMENDED",
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFB45309),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price Row with Discount Support
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "৳${plan.discountPrice.toStringAsFixed(0)}",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDurationSuffix(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          "৳${plan.basePrice.toStringAsFixed(0)}",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: context.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Perk Checklist
                  for (final perk in perks) _buildPerkRow(perk),
                  const SizedBox(height: 16),

                  // Continue Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedTier = tierId);
                        _proceedToDetails(tierId);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: isSelected
                            ? _categoryColor
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9)),
                        foregroundColor: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF64748B)),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isSelected
                                  ? (tierId == 'premium' ? "Continue with Premium VIP" : "Continue with $title")
                                  : "Select & Continue",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(String perkText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: _categoryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              perkText,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVerifiedDashboard(BuildContext context, Profile myProfile) {
    Color badgeColor;
    String badgeName;
    String powerLevelLabel;
    double powerPercent;
    List<String> benefits;

    final badge = myProfile.badgeType?.toLowerCase() ?? 'blue';
    if (badge == 'gold') {
      badgeColor = const Color(0xFFD97706);
      badgeName = 'Gold Verification';
      powerLevelLabel = '99% Impersonation Protection & Maximum Algorithm Boost';
      powerPercent = 0.99;
      benefits = [
        '📈 Unlimited monetization access & subscription tiers.',
        '🏢 Official business banner & community promotion.',
        '🛡️ Advanced anti-impersonation protection & profile lock.',
        '⚡ Priority 24/7 dedicated support & faster payout processing.'
      ];
    } else if (badge == 'green') {
      badgeColor = const Color(0xFF1E824C);
      badgeName = 'Green Verification';
      powerLevelLabel = '95% Authority Score & Targeted Feed Reach Boost';
      powerPercent = 0.95;
      benefits = [
        '📰 High authority tag in trends feed & official journalism mark.',
        '🎙️ Premium access to live audio/video broadcast features.',
        '🔒 Enhanced verification security & multi-factor protection.',
        '💬 Direct verified-only messaging channels and groups.'
      ];
    } else {
      badgeColor = const Color(0xFF0095F6);
      badgeName = 'Blue Verification';
      powerLevelLabel = '85% Authenticated Creator Score & Boosted Reach';
      powerPercent = 0.85;
      benefits = [
        '🎨 Full Creator Studio features & exclusive subscriber options.',
        '🚀 Pigeon Feed algorithm visibility boost in all posts.',
        '💬 Comment priority in popular threads & auto-moderation.',
        '🌟 Exclusive verified-only custom profile badges & tabs.'
      ];
    }

    final expires = myProfile.verifiedExpiresAt;
    String expiryText = 'Lifetime Active';
    if (expires != null) {
      final daysRemaining = expires.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) {
        expiryText = 'Expired on ${expires.day}/${expires.month}/${expires.year}';
      } else {
        expiryText = 'Expires in $daysRemaining days (on ${expires.day}/${expires.month}/${expires.year})';
      }
    }

    final isDark = context.isDarkMode;
    final primaryGreen = context.primaryAccent;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification Status',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: badgeColor, width: 3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: (myProfile.avatarUrl != null && myProfile.avatarUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: myProfile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 45),
                                )
                              : const Icon(Icons.person, size: 45),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: badgeColor,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are Verified!',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${myProfile.username}',
                    style: GoogleFonts.inter(
                      color: badgeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeName.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Details',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF1E824C), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Active',
                            style: GoogleFonts.inter(color: const Color(0xFF1E824C), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Renewal Period',
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                      ),
                      Text(
                        expiryText,
                        style: GoogleFonts.inter(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Badge Power Score',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    powerLevelLabel,
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: powerPercent,
                      minHeight: 8,
                      backgroundColor: context.border,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Active Benefits Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Badge Benefits',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: benefits.map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: primaryGreen, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b,
                                style: GoogleFonts.inter(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
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

            const SizedBox(height: 24),

            // Express Support Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pigeon Verified ensures maximum trust and reach. Any plan updates or renewals are processed within 24 hours.',
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class AnimatedGlowingBorder extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color glowColor;

  const AnimatedGlowingBorder({
    super.key,
    required this.child,
    required this.isSelected,
    required this.glowColor,
  });

  @override
  State<AnimatedGlowingBorder> createState() => _AnimatedGlowingBorderState();
}

class _AnimatedGlowingBorderState extends State<AnimatedGlowingBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSelected) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(2.0), // Border width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0.0,
              endAngle: 3.14159 * 2,
              colors: [
                widget.glowColor.withValues(alpha: 0.1),
                widget.glowColor,
                widget.glowColor.withValues(alpha: 0.1),
                widget.glowColor,
                widget.glowColor.withValues(alpha: 0.1),
              ],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class LiveFireEmoji extends StatefulWidget {
  const LiveFireEmoji({super.key});

  @override
  State<LiveFireEmoji> createState() => _LiveFireEmojiState();
}

class _LiveFireEmojiState extends State<LiveFireEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: const Text("🔥 ", style: TextStyle(fontSize: 10)),
    );
  }
}
