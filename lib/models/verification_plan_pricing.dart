class VerificationPlanPricing {
  final String id;
  final String category; // 'general', 'business', 'government'
  final String duration; // 'weekly', 'monthly', 'yearly', 'lifetime'
  final String tier; // 'basic', 'premium'
  final String name;
  final double basePrice;
  final double discountPrice;

  const VerificationPlanPricing({
    required this.id,
    required this.category,
    required this.duration,
    required this.tier,
    required this.name,
    required this.basePrice,
    required this.discountPrice,
  });

  static final Map<String, VerificationPlanPricing> allPlans = {
    // --- General Plans (Blue Badge 🔵) ---
    'general_weekly_basic': const VerificationPlanPricing(
      id: 'general_weekly_basic',
      category: 'general',
      duration: 'weekly',
      tier: 'basic',
      name: 'General Weekly Basic',
      basePrice: 60.0,
      discountPrice: 59.0,
    ),
    'general_weekly_premium': const VerificationPlanPricing(
      id: 'general_weekly_premium',
      category: 'general',
      duration: 'weekly',
      tier: 'premium',
      name: 'General Weekly Premium',
      basePrice: 110.0,
      discountPrice: 100.0,
    ),
    'general_monthly_basic': const VerificationPlanPricing(
      id: 'general_monthly_basic',
      category: 'general',
      duration: 'monthly',
      tier: 'basic',
      name: 'General Monthly Basic',
      basePrice: 210.0,
      discountPrice: 199.0,
    ),
    'general_monthly_premium': const VerificationPlanPricing(
      id: 'general_monthly_premium',
      category: 'general',
      duration: 'monthly',
      tier: 'premium',
      name: 'General Monthly Premium',
      basePrice: 380.0,
      discountPrice: 350.0,
    ),
    'general_yearly_basic': const VerificationPlanPricing(
      id: 'general_yearly_basic',
      category: 'general',
      duration: 'yearly',
      tier: 'basic',
      name: 'General Yearly Basic',
      basePrice: 1800.0,
      discountPrice: 1599.0,
    ),
    'general_yearly_premium': const VerificationPlanPricing(
      id: 'general_yearly_premium',
      category: 'general',
      duration: 'yearly',
      tier: 'premium',
      name: 'General Yearly Premium',
      basePrice: 2800.0,
      discountPrice: 2500.0,
    ),
    'general_lifetime_basic': const VerificationPlanPricing(
      id: 'general_lifetime_basic',
      category: 'general',
      duration: 'lifetime',
      tier: 'basic',
      name: 'General Lifetime Basic',
      basePrice: 5200.0,
      discountPrice: 4999.0,
    ),
    'general_lifetime_premium': const VerificationPlanPricing(
      id: 'general_lifetime_premium',
      category: 'general',
      duration: 'lifetime',
      tier: 'premium',
      name: 'General Lifetime Premium',
      basePrice: 9500.0,
      discountPrice: 8999.0,
    ),

    // --- Business Plans (Gold Badge 👑) ---
    'business_weekly_basic': const VerificationPlanPricing(
      id: 'business_weekly_basic',
      category: 'business',
      duration: 'weekly',
      tier: 'basic',
      name: 'Business Weekly Basic',
      basePrice: 150.0,
      discountPrice: 139.0,
    ),
    'business_weekly_premium': const VerificationPlanPricing(
      id: 'business_weekly_premium',
      category: 'business',
      duration: 'weekly',
      tier: 'premium',
      name: 'Business Weekly Premium',
      basePrice: 280.0,
      discountPrice: 250.0,
    ),
    'business_monthly_basic': const VerificationPlanPricing(
      id: 'business_monthly_basic',
      category: 'business',
      duration: 'monthly',
      tier: 'basic',
      name: 'Business Monthly Basic',
      basePrice: 500.0,
      discountPrice: 450.0,
    ),
    'business_monthly_premium': const VerificationPlanPricing(
      id: 'business_monthly_premium',
      category: 'business',
      duration: 'monthly',
      tier: 'premium',
      name: 'Business Monthly Premium',
      basePrice: 899.0,
      discountPrice: 799.0,
    ),
    'business_yearly_basic': const VerificationPlanPricing(
      id: 'business_yearly_basic',
      category: 'business',
      duration: 'yearly',
      tier: 'basic',
      name: 'Business Yearly Basic',
      basePrice: 3999.0,
      discountPrice: 3499.0,
    ),
    'business_yearly_premium': const VerificationPlanPricing(
      id: 'business_yearly_premium',
      category: 'business',
      duration: 'yearly',
      tier: 'premium',
      name: 'Business Yearly Premium',
      basePrice: 6999.0,
      discountPrice: 5999.0,
    ),
    'business_lifetime_basic': const VerificationPlanPricing(
      id: 'business_lifetime_basic',
      category: 'business',
      duration: 'lifetime',
      tier: 'basic',
      name: 'Business Lifetime Basic',
      basePrice: 9999.0,
      discountPrice: 8999.0,
    ),
    'business_lifetime_premium': const VerificationPlanPricing(
      id: 'business_lifetime_premium',
      category: 'business',
      duration: 'lifetime',
      tier: 'premium',
      name: 'Business Lifetime Premium',
      basePrice: 16999.0,
      discountPrice: 14999.0,
    ),

    // --- Government Plans (Gray Badge 🏛️) ---
    'government_weekly_basic': const VerificationPlanPricing(
      id: 'government_weekly_basic',
      category: 'government',
      duration: 'weekly',
      tier: 'basic',
      name: 'Government Weekly Basic',
      basePrice: 125.0,
      discountPrice: 110.0,
    ),
    'government_weekly_premium': const VerificationPlanPricing(
      id: 'government_weekly_premium',
      category: 'government',
      duration: 'weekly',
      tier: 'premium',
      name: 'Government Weekly Premium',
      basePrice: 250.0,
      discountPrice: 220.0,
    ),
    'government_monthly_basic': const VerificationPlanPricing(
      id: 'government_monthly_basic',
      category: 'government',
      duration: 'monthly',
      tier: 'basic',
      name: 'Government Monthly Basic',
      basePrice: 399.0,
      discountPrice: 350.0,
    ),
    'government_monthly_premium': const VerificationPlanPricing(
      id: 'government_monthly_premium',
      category: 'government',
      duration: 'monthly',
      tier: 'premium',
      name: 'Government Monthly Premium',
      basePrice: 799.0,
      discountPrice: 699.0,
    ),
    'government_yearly_basic': const VerificationPlanPricing(
      id: 'government_yearly_basic',
      category: 'government',
      duration: 'yearly',
      tier: 'basic',
      name: 'Government Yearly Basic',
      basePrice: 3200.0,
      discountPrice: 2800.0,
    ),
    'government_yearly_premium': const VerificationPlanPricing(
      id: 'government_yearly_premium',
      category: 'government',
      duration: 'yearly',
      tier: 'premium',
      name: 'Government Yearly Premium',
      basePrice: 5500.0,
      discountPrice: 4999.0,
    ),
    'government_lifetime_basic': const VerificationPlanPricing(
      id: 'government_lifetime_basic',
      category: 'government',
      duration: 'lifetime',
      tier: 'basic',
      name: 'Government Lifetime Basic',
      basePrice: 8999.0,
      discountPrice: 7999.0,
    ),
    'government_lifetime_premium': const VerificationPlanPricing(
      id: 'government_lifetime_premium',
      category: 'government',
      duration: 'lifetime',
      tier: 'premium',
      name: 'Government Lifetime Premium',
      basePrice: 14999.0,
      discountPrice: 12999.0,
    ),
  };

  static VerificationPlanPricing getPlan(String planId) {
    if (allPlans.containsKey(planId)) {
      return allPlans[planId]!;
    }
    // Check aliases (e.g. media -> government)
    String normalizedId = planId;
    if (normalizedId.contains('media')) {
      normalizedId = normalizedId.replaceAll('media', 'government');
    }
    if (allPlans.containsKey(normalizedId)) {
      return allPlans[normalizedId]!;
    }

    // Dynamic parse fallback if planId format is {category}_{duration}_{tier}
    final parts = planId.split('_');
    if (parts.length >= 3) {
      final category = parts[0] == 'media' ? 'government' : parts[0];
      final duration = parts[1];
      final tier = parts[2];
      final key = '${category}_${duration}_$tier';
      if (allPlans.containsKey(key)) {
        return allPlans[key]!;
      }
    }
    // Default fallback
    return allPlans['general_monthly_basic']!;
  }
}
