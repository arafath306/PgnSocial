import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
  String _selectedCategory = 'general'; // 'general', 'business', 'media'

  // Step 2 State: Duration & Tier
  String _selectedDuration = 'weekly'; // 'weekly', 'monthly', 'yearly', 'lifetime'
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
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Step 3 -> Move to Personal Details
      final controller = context.read<VerificationController>();
      controller.selectPlan('${_selectedCategory}_${_selectedDuration}_$_selectedTier');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
      );
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

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
            onPressed: _previousStep,
          ),
          title: _currentStep == 0
              ? null
              : Row(
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
                    const Icon(Icons.verified_rounded, color: Color(0xFF0095F6), size: 19),
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
              _buildScreen3WhyGetVerified(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 1: Choose Your Verification Type
  // ==========================================
  Widget _buildScreen1CategorySelection(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final myProfile = dbService.myProfile;
    final avatarUrl = myProfile?.avatarUrl;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // User Profile Picture Container
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0095F6).withValues(alpha: 0.35),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(39),
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              width: 78,
                              height: 78,
                              placeholder: (context, url) => Container(
                                color: context.isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                                child: const Icon(Icons.person, size: 42, color: Color(0xFF0095F6)),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                              child: const Icon(Icons.person, size: 42, color: Color(0xFF0095F6)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title: Pigeon Verified 🔵
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pigeon Verified",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified_rounded, color: Color(0xFF0095F6), size: 24),
                  ],
                ),
                const SizedBox(height: 6),

                Text(
                  "Get verified. Build trust. Stand out.",
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),

                // Section Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose your verification type",
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select the category that best describes you.",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Card 1: General / Creator (Blue Badge)
                _buildCategoryCard(
                  context,
                  id: 'general',
                  badgeColor: const Color(0xFF0095F6),
                  badgeLabel: "Blue Badge",
                  badgeBgColor: const Color(0xFFEFF6FF),
                  title: "General / Creator",
                  subtitle: "For creators, influencers and public figures.",
                  titleColor: const Color(0xFF1D4ED8),
                ),
                const SizedBox(height: 14),

                // Card 2: Business / Corporate (Gold Badge)
                _buildCategoryCard(
                  context,
                  id: 'business',
                  badgeColor: const Color(0xFFD97706),
                  badgeLabel: "Gold Badge",
                  badgeBgColor: const Color(0xFFFFFBEB),
                  title: "Business / Corporate",
                  subtitle: "For brands, startups and organizations.",
                  titleColor: context.textPrimary,
                ),
                const SizedBox(height: 14),

                // Card 3: Government / Media (Gray Badge)
                _buildCategoryCard(
                  context,
                  id: 'media',
                  badgeColor: const Color(0xFF64748B),
                  badgeLabel: "Gray Badge",
                  badgeBgColor: const Color(0xFFF1F5F9),
                  title: "Government / Media",
                  subtitle: "For government agencies, news and public institutions.",
                  titleColor: context.textPrimary,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Footer note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Verified badge shows authenticity and helps you grow your presence.",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: context.textSecondary,
                    height: 1.35,
                  ),
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
    required String badgeLabel,
    required Color badgeBgColor,
    required String title,
    required String subtitle,
    required Color titleColor,
  }) {
    final isSelected = _selectedCategory == id;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
        _nextStep();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : (isSelected ? const Color(0xFFF8FAFC) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? badgeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Original Profile Verification Badge Icon
            Icon(
              Icons.verified_rounded,
              color: badgeColor,
              size: 44,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark ? badgeColor.withValues(alpha: 0.2) : badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 2: Choose Your Subscription
  // ==========================================
  Widget _buildScreen2SubscriptionPlans(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Choose your subscription",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Pick the plan that fits your needs.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Segmented Tab Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildDurationTab("weekly", "Weekly"),
                      _buildDurationTab("monthly", "Monthly"),
                      _buildDurationTab("yearly", "Yearly"),
                      _buildDurationTab("lifetime", "Lifetime"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sub-header
                Row(
                  children: [
                    Text(
                      "${_selectedDuration[0].toUpperCase()}${_selectedDuration.substring(1)} Plans",
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Best for short-term",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Basic Plan Card
                _buildBasicPlanCard(context),
                const SizedBox(height: 16),

                // Premium Plan Card
                _buildPremiumPlanCard(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Footer Note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Secure payment. Cancel anytime. Your subscription will auto-renew.",
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

  Widget _buildDurationTab(String durationId, String label) {
    final isSelected = _selectedDuration == durationId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = durationId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? context.textPrimary : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicPlanCard(BuildContext context) {
    final isSelected = _selectedTier == 'basic';
    final isDark = context.isDarkMode;

    String priceStr;
    switch (_selectedDuration) {
      case 'weekly':
        priceStr = "৳59 / week";
        break;
      case 'yearly':
        priceStr = "৳1,599 / year";
        break;
      case 'lifetime':
        priceStr = "৳4,999 / lifetime";
        break;
      case 'monthly':
      default:
        priceStr = "৳199 / month";
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = 'basic'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0095F6)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Basic",
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0095F6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  priceStr,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Perk checklist
                Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0095F6)),
                    const SizedBox(width: 8),
                    Text(
                      "Verified Badge",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedTier = 'basic');
                      _nextStep();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue",
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Original Badge Illustration on right
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPlanCard(BuildContext context) {
    final isSelected = _selectedTier == 'premium';
    final isDark = context.isDarkMode;

    String priceStr;
    switch (_selectedDuration) {
      case 'weekly':
        priceStr = "৳100 / week";
        break;
      case 'yearly':
        priceStr = "৳2,500 / year";
        break;
      case 'lifetime':
        priceStr = "৳8,999 / lifetime";
        break;
      case 'monthly':
      default:
        priceStr = "৳350 / month";
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = 'premium'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF59E0B),
            width: isSelected ? 2.2 : 1.4,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("👑 ", style: TextStyle(fontSize: 15)),
                    Text(
                      "Premium",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  priceStr,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Perk checklist
                _buildPerkRow("Verified Badge"),
                _buildPerkRow("Anonymous Posts"),
                _buildPerkRow("Voice Posts"),
                _buildPerkRow("Screenshot Protection"),
                _buildPerkRow("Algorithm Priority"),
                const SizedBox(height: 18),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedTier = 'premium');
                      _nextStep();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue",
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Top Right Popular Badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  "POPULAR",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB45309),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Original Badge Illustration on right
            const Positioned(
              top: 36,
              right: 4,
              child: Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkRow(String perkText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 16, color: Color(0xFFD97706)),
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

  // ==========================================
  // SCREEN 3: Why Get Verified?
  // ==========================================
  Widget _buildScreen3WhyGetVerified(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                RichText(
                  text: TextSpan(
                    text: "Why get ",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: "verified?",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0E8345),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Verified accounts get more trust, visibility and exclusive benefits.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 5 Feature Item List
                _buildBenefitTile(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: "Increase Trust",
                  subtitle: "A verified badge shows authenticity and builds credibility.",
                ),
                _buildBenefitTile(
                  context,
                  icon: Icons.trending_up_rounded,
                  title: "Higher Visibility",
                  subtitle: "Reach more people with algorithm priority and ranking.",
                ),
                _buildBenefitTile(
                  context,
                  icon: Icons.headset_mic_outlined,
                  title: "Priority Support",
                  subtitle: "Get faster help whenever you need it.",
                ),
                _buildBenefitTile(
                  context,
                  icon: Icons.diamond_outlined,
                  title: "Exclusive Features",
                  subtitle: "Unlock premium tools and exclusive capabilities.",
                ),
                _buildBenefitTile(
                  context,
                  icon: Icons.bolt_rounded,
                  title: "Fast Verification",
                  subtitle: "Quick review and verification process.",
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Bottom Action Button Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E8345),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "You can change or upgrade your plan anytime.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0E8345), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
