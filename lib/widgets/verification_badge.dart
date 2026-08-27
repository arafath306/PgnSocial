import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String? badgeType;
  final double size;
  
  const VerificationBadge({
    super.key, 
    required this.isVerified,
    this.badgeType,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();
    
    Color badgeColor;
    final String type = (badgeType ?? 'blue').toLowerCase();
    if (type == 'gold' || type == 'business') {
      badgeColor = const Color(0xFFD97706); // Gold Badge 👑
    } else if (type == 'green' || type == 'government' || type == 'media') {
      badgeColor = const Color(0xFF1E824C); // Green Badge 🏛️
    } else {
      badgeColor = const Color(0xFF0095F6); // Blue Badge 🔵
    }
    
    return Icon(Icons.verified_rounded, color: badgeColor, size: size);
  }
}
