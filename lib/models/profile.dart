class Profile {
  final String id;
  final String username;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final int followersCount;
  final int followingCount;
  final String? phone;
  final String? email;
  final String? country;
  final String? division;
  final String? city;
  final String? village;
  final String? zip;
  final bool isVerified;
  final String? badgeType;
  final String? verifiedTier;
  final DateTime? verifiedExpiresAt;
  final String? birthdate;
  final String? gender;
  final bool isPrivate;
  final String allowMentions;
  final bool filterAdult;
  final bool autoplayVideos;
  final bool isShadowbanned;
  final bool verificationRequested;
  final bool canMonetize;
  final bool isActiveStatusEnabled;
  final DateTime? lastSeen;
  final String? publicKey;
  final DateTime? createdAt;
  final String? role;

  Profile({
    required this.id,
    required this.username,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.phone,
    this.email,
    this.country,
    this.division,
    this.city,
    this.village,
    this.zip,
    this.isVerified = false,
    this.badgeType,
    this.verifiedTier,
    this.verifiedExpiresAt,
    this.birthdate,
    this.gender,
    this.isPrivate = false,
    this.allowMentions = 'everyone',
    this.filterAdult = true,
    this.autoplayVideos = true,
    this.isShadowbanned = false,
    this.verificationRequested = false,
    this.canMonetize = false,
    this.isActiveStatusEnabled = true,
    this.lastSeen,
    this.publicKey,
    this.createdAt,
    this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final isVer = json['is_verified'] as bool? ?? false;
    return Profile(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? 'anonymous',
      fullName: (json['full_name'] as String?) ?? 'Anonymous User',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      followersCount: (json['followers_count'] as int?) ?? 0,
      followingCount: (json['following_count'] as int?) ?? 0,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      country: json['country'] as String?,
      division: json['division'] as String?,
      city: json['city'] as String?,
      village: json['village'] as String?,
      zip: json['zip'] as String?,
      isVerified: isVer,
      badgeType: (json['badge_type'] as String?) ?? (json['verified_badge'] as String?),
      verifiedTier: json['verified_tier'] as String? ??
          ((json['verified_plan_id']?.toString().contains('premium') == true ||
                  json['plan_id']?.toString().contains('premium') == true)
              ? 'premium'
              : null),
      verifiedExpiresAt: json['verified_expires_at'] != null 
          ? DateTime.tryParse(json['verified_expires_at'] as String) 
          : null,
      birthdate: json['birthdate'] as String?,
      gender: json['gender'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      allowMentions: json['allow_mentions'] as String? ?? 'everyone',
      filterAdult: json['filter_adult'] as bool? ?? true,
      autoplayVideos: json['autoplay_videos'] as bool? ?? true,
      isShadowbanned: json['is_shadowbanned'] as bool? ?? false,
      verificationRequested: json['verification_requested'] as bool? ?? false,
      canMonetize: json['can_monetize'] as bool? ?? isVer,
      isActiveStatusEnabled: json['is_active_status_enabled'] as bool? ?? true,
      lastSeen: _parseUtcTime(json['last_seen'] as String?),
      publicKey: json['public_key'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'followers_count': followersCount,
      'following_count': followingCount,
      'phone': phone,
      'email': email,
      'country': country,
      'division': division,
      'city': city,
      'village': village,
      'zip': zip,
      'is_verified': isVerified,
      'badge_type': badgeType,
      'verified_tier': verifiedTier,
      'verified_expires_at': verifiedExpiresAt?.toIso8601String(),
      'birthdate': birthdate,
      'gender': gender,
      'is_private': isPrivate,
      'allow_mentions': allowMentions,
      'filter_adult': filterAdult,
      'autoplay_videos': autoplayVideos,
      'is_shadowbanned': isShadowbanned,
      'verification_requested': verificationRequested,
      'can_monetize': canMonetize,
      'is_active_status_enabled': isActiveStatusEnabled,
      'last_seen': lastSeen?.toIso8601String(),
      if (publicKey != null) 'public_key': publicKey,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (role != null) 'role': role,
    };
  }

  /// True if user is verified on any Premium plan (General Premium, Business Premium, Government Premium)
  bool get isPremium => isVerified && (verifiedTier?.toLowerCase() == 'premium' || verifiedTier == 'Premium');

  /// Anonymous Post access (Premium feature)
  bool get hasAnonymousAccess => isPremium;

  /// Voice Post access (Premium feature)
  bool get hasVoiceAccess => isPremium;

  /// Algorithm Priority access (Premium feature)
  bool get hasAlgorithmPriority => isPremium;

  /// Screenshot Protection (Premium feature)
  bool get hasScreenshotProtection => isPremium;

  static DateTime? _parseUtcTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    if (!dateStr.contains('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
      dateStr += 'Z';
    }
    return DateTime.tryParse(dateStr)?.toLocal();
  }
}
