import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/verification_request.dart';
import '../../../state/verification_controller.dart';
import '../../../services/database_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import 'personal_details_screen.dart';
import 'pending_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VerificationIntroScreen extends StatefulWidget {
  const VerificationIntroScreen({super.key});

  @override
  State<VerificationIntroScreen> createState() => _VerificationIntroScreenState();
}

class _VerificationIntroScreenState extends State<VerificationIntroScreen> {
  // Category-First Selection State:
  // 'general' (Blue Badge), 'business' (Gold Badge - In Review), 'media' (Gray Badge - In Review)
  String _selectedCategory = 'general';
  String _selectedDuration = 'monthly'; // 'weekly', 'monthly', 'yearly'
  String _selectedTier = 'premium';     // 'basic', 'premium'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchVerificationPlans();
    });
  }

  // Tier prices breakdown for General Category
  Map<String, dynamic> _getPlanInfo(String duration, String tier) {
    if (duration == 'weekly') {
      if (tier == 'basic') {
        return {
          'id': 'general_weekly_basic',
          'name': 'Weekly Basic',
          'price': 59.0,
          'interval': 'week',
          'badge': '🔵 Blue Verification Badge',
          'perks': [
            'Official Blue Verification Badge (🔵)',
            '24/7 Standard Account Support',
          ]
        };
      } else {
        return {
          'id': 'general_weekly_premium',
          'name': 'Weekly Premium',
          'price': 99.0,
          'interval': 'week',
          'badge': '🔵 Blue Verification Badge',
          'bonus': '🎁 Extra 7 Days Free Badge Included!',
          'perks': [
            'Official Blue Verification Badge (🔵)',
            '🎙️ Voice Posting Access',
            '🕵️ Anonymous Posting (2 posts / month)',
            '🔥 Algorithm Feed Priority Boost',
            '🛡️ Screenshot Protection (E2EE Privacy)',
            '⚡ Direct VIP Support Line',
            '🎁 Extra 7 Days Free Badge Bonus',
          ]
        };
      }
    } else if (duration == 'yearly') {
      if (tier == 'basic') {
        return {
          'id': 'general_yearly_basic',
          'name': 'Yearly Basic',
          'price': 1599.0,
          'interval': 'year',
          'badge': '🔵 Blue Verification Badge',
          'perks': [
            'Official Blue Verification Badge (🔵)',
            '24/7 Standard Account Support',
          ]
        };
      } else {
        return {
          'id': 'general_yearly_premium',
          'name': 'Yearly Premium',
          'price': 2499.0,
          'interval': 'year',
          'badge': '🔵 Blue Verification Badge',
          'bonus': '🎁 2 Months Free + Early Access + Priority Member Badge!',
          'perks': [
            'Official Blue Verification Badge (🔵)',
            '🎙️ Voice Posting Access',
            '🕵️ Anonymous Posting (2 posts / month)',
            '🔥 Algorithm Feed Priority Boost',
            '🛡️ Screenshot Protection (E2EE Privacy)',
            '⚡ Direct VIP Support Line',
            '🎁 2 Months Free Badge Included',
            '✨ Early Access to New Features',
            '⭐ Priority Member Badge Status',
          ]
        };
      }
    } else {
      // Monthly (Default)
      if (tier == 'basic') {
        return {
          'id': 'general_monthly_basic',
          'name': 'Monthly Basic',
          'price': 199.0,
          'interval': 'month',
          'badge': '🔵 Blue Verification Badge',
          'perks': [
            'Official Blue Verification Badge (🔵)',
            '24/7 Standard Account Support',
          ]
        };
      } else {
        return {
          'id': 'general_monthly_premium',
          'name': 'Monthly Premium',
          'price': 349.0,
          'interval': 'month',
          'badge': '🔵 Blue Verification Badge',
          'bonus': '🚀 Complete VIP Creator Features Package',
          'perks': [
            'Official Blue Verification Badge (🔵)',
            '🎙️ Voice Posting Access',
            '🕵️ Anonymous Posting (2 posts / month)',
            '🔥 Algorithm Feed Priority Boost',
            '🛡️ Screenshot Protection (E2EE Privacy)',
            '⚡ Direct VIP Support Line',
          ]
        };
      }
    }
  }

  void _showComingSoonDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBg,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 10),
            Text(
              "Category in Review",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          "$categoryName verification requires direct documentation review. Applications for this category will open soon.\n\nPlease select 'General User / Creator' for individual verification.",
          style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Understood", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0095F6))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myAvatarUrl = context.select<DatabaseService, String?>((db) => db.myProfile?.avatarUrl);
    final controller = context.watch<VerificationController>();
    final status = controller.request.status;

    final currentPlan = _getPlanInfo(_selectedDuration, _selectedTier);
    final double activePrice = currentPlan['price'] as double;
    final String currentPlanId = currentPlan['id'] as String;

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
          AppLocalizations.of(context)!.pigeonVerified,
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Avatar Header
              _PulsingAvatarHeader(avatarUrl: myAvatarUrl),
              const SizedBox(height: 28),

              // 2. Step 1: Select Account Category
              _buildSectionHeader(context, "1. Select Account Category"),
              const SizedBox(height: 12),

              _buildCategoryCard(
                context,
                id: 'general',
                icon: Icons.verified_rounded,
                badgeColor: const Color(0xFF0095F6),
                title: "General User / Creator",
                subtitle: "Blue Badge (🔵) — Personal identity, creators, influencers & public figures",
                isSelected: _selectedCategory == 'general',
                onTap: () => setState(() => _selectedCategory = 'general'),
              ),
              const SizedBox(height: 10),

              _buildCategoryCard(
                context,
                id: 'business',
                icon: Icons.business_center_rounded,
                badgeColor: Colors.amber,
                title: "Business or Brand",
                subtitle: "Gold Badge (🟡) — Registered companies, organizations & corporate brands",
                isSelected: _selectedCategory == 'business',
                isComingSoon: true,
                onTap: () => _showComingSoonDialog("Business or Brand"),
              ),
              const SizedBox(height: 10),

              _buildCategoryCard(
                context,
                id: 'media',
                icon: Icons.account_balance_rounded,
                badgeColor: Colors.blueGrey,
                title: "Media or Government",
                subtitle: "Gray Badge (🩶) — Official news outlets & government departments",
                isSelected: _selectedCategory == 'media',
                isComingSoon: true,
                onTap: () => _showComingSoonDialog("Media or Government"),
              ),
              const SizedBox(height: 28),

              // If General category is active, show Duration & Tier plans
              if (_selectedCategory == 'general') ...[
                // 3. Step 2: Select Duration
                _buildSectionHeader(context, "2. Select Duration"),
                const SizedBox(height: 12),

                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildDurationTab("weekly", "🗓️ Weekly"),
                      _buildDurationTab("monthly", "📅 Monthly"),
                      _buildDurationTab("yearly", "🌟 Yearly (Save 20%)"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Step 3: Select Plan Tier (Basic vs Premium)
                _buildSectionHeader(context, "3. Select Plan Tier"),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildTierCard(
                        context,
                        tierId: 'basic',
                        title: "Basic Tier",
                        badgeText: "🔵 Blue Badge",
                        priceText: _selectedDuration == 'weekly'
                            ? "৳59/wk"
                            : (_selectedDuration == 'yearly' ? "৳1,599/yr" : "৳199/mo"),
                        isSelected: _selectedTier == 'basic',
                        onTap: () => setState(() => _selectedTier = 'basic'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTierCard(
                        context,
                        tierId: 'premium',
                        title: "Premium Tier",
                        badgeText: "👑 VIP Creator",
                        tagText: "RECOMMENDED",
                        priceText: _selectedDuration == 'weekly'
                            ? "৳99/wk"
                            : (_selectedDuration == 'yearly' ? "৳2,499/yr" : "৳349/mo"),
                        isSelected: _selectedTier == 'premium',
                        onTap: () => setState(() => _selectedTier = 'premium'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Featured Selected Plan Benefits Card
                _buildSelectedPlanSummaryCard(context, currentPlan),
                const SizedBox(height: 28),
              ],

              // 6. Requirements
              _buildSectionHeader(context, "Eligibility Requirements"),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRequirementItem(context, "Must be at least 18 years of age"),
                    _buildRequirementItem(context, "Must provide a government-issued photo ID card"),
                    _buildRequirementItem(context, "Full profile picture showing your face clearly"),
                    _buildRequirementItem(context, "Enabled 2FA or secure recovery email on account"),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 7. Security Privacy Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0095F6).withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF0095F6), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.yourIdentityIsSecure,
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.weDoNotSellOrShareYourIdentityDetailsNid,
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 8. Sticky Action Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    PigeonPrimaryButton(
                      label: "Continue with ${currentPlan['name']} (৳${activePrice.toStringAsFixed(0)})",
                      onPressed: () {
                        controller.selectPlan(currentPlanId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
                        );
                      },
                    ),
                    if (status != VerificationStatus.incomplete) ...[
                      const SizedBox(height: 12),
                      PigeonPrimaryButton(
                        label: AppLocalizations.of(context)!.checkCurrentStatus,
                        outlined: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PendingScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode ? const Color(0xFF2E3045) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? context.textPrimary : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String id,
    required IconData icon,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    bool isComingSoon = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? badgeColor.withValues(alpha: 0.08)
              : (context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? badgeColor
                : (context.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "IN REVIEW",
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? badgeColor : context.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String tierId,
    required String title,
    required String badgeText,
    String? tagText,
    required String priceText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (tierId == 'premium'
                  ? const Color(0xFF0095F6).withValues(alpha: 0.1)
                  : context.cardBg)
              : (context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0095F6)
                : (context.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tagText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tagText,
                  style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              badgeText,
              style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              priceText,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0095F6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlanSummaryCard(BuildContext context, Map<String, dynamic> planInfo) {
    final String name = planInfo['name'] as String;
    final double price = planInfo['price'] as double;
    final String? bonus = planInfo['bonus'] as String?;
    final List<String> perks = List<String>.from(planInfo['perks']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0095F6).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0095F6).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$name Package",
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              Text(
                "৳${price.toStringAsFixed(0)}",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0095F6),
                ),
              ),
            ],
          ),
          if (bonus != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                bonus,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            "Included Perks:",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...perks.map((perk) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        perk,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildRequirementItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom pulsing avatar widget representing high quality multinational style
class _PulsingAvatarHeader extends StatefulWidget {
  final String? avatarUrl;
  const _PulsingAvatarHeader({this.avatarUrl});

  @override
  State<_PulsingAvatarHeader> createState() => _PulsingAvatarHeaderState();
}

class _PulsingAvatarHeaderState extends State<_PulsingAvatarHeader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final wave = _pulseController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                  // Pulse Wave 1
                  Container(
                    width: 96 + (wave * 24),
                    height: 96 + (wave * 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0095F6).withValues(alpha: (1 - wave) * 0.25),
                    ),
                  ),
                  // Pulse Wave 2
                  Container(
                    width: 86 + (wave * 12),
                    height: 86 + (wave * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0095F6).withValues(alpha: (1 - wave) * 0.35),
                    ),
                  ),
                  // Glowing Border Ring
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.customCardBg,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  // Actual Avatar
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.avatarUrl!)
                        : null,
                    child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, size: 36, color: isDark ? Colors.white30 : Colors.black26)
                        : null,
                  ),
                  // Glowing Badge Checkmark icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF0095F6),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.pigeonVerified,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppLocalizations.of(context)!.aSubscriptionBundleToBuildYourPresenceAn,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
