class SavedAccount {
  final String userId;
  final String email;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String refreshToken;
  final bool isVerified;
  final String? badgeType;
  final DateTime lastActive;

  SavedAccount({
    required this.userId,
    required this.email,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.refreshToken,
    this.isVerified = false,
    this.badgeType,
    required this.lastActive,
  });

  SavedAccount copyWith({
    String? userId,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? refreshToken,
    bool? isVerified,
    String? badgeType,
    DateTime? lastActive,
  }) {
    return SavedAccount(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      refreshToken: refreshToken ?? this.refreshToken,
      isVerified: isVerified ?? this.isVerified,
      badgeType: badgeType ?? this.badgeType,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'refreshToken': refreshToken,
      'isVerified': isVerified,
      'badgeType': badgeType,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      refreshToken: json['refreshToken'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      badgeType: json['badgeType'] as String?,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
