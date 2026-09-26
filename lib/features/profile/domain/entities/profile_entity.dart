// NOTE: [UNUSED / REFERENCE ONLY]
// This entity file is currently not active in the app.
// User profiles are managed across all screens via [Profile] in 'models/profile.dart'.
// Kept for future clean-architecture reference.

class ProfileEntity {
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
  final DateTime? verifiedExpiresAt;
  final String? birthdate;
  final String? gender;
  final bool isPrivate;
  final String allowMentions;
  final bool filterAdult;
  final bool autoplayVideos;
  final bool verificationRequested;
  final bool isActiveStatusEnabled;
  final DateTime? lastSeen;

  const ProfileEntity({
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
    this.verifiedExpiresAt,
    this.birthdate,
    this.gender,
    this.isPrivate = false,
    this.allowMentions = 'everyone',
    this.filterAdult = true,
    this.autoplayVideos = true,
    this.verificationRequested = false,
    this.isActiveStatusEnabled = true,
    this.lastSeen,
  });
}
