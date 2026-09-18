import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/profile.dart';
import '../../../utils/app_theme.dart';

class ActiveFriendsTray extends StatelessWidget {
  final List<Profile> activeUsers;
  final ValueChanged<Profile> onUserTap;

  const ActiveFriendsTray({
    super.key,
    required this.activeUsers,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activeUsers.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;

    return Container(
      height: 98,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE NOW',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${activeUsers.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: activeUsers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final user = activeUsers[index];
                final firstName = user.fullName.trim().split(' ').first;

                return GestureDetector(
                  onTap: () => onUserTap(user),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Outer presence glow ring
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: ClipOval(
                              child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: user.avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => Container(
                                        color: isDark ? const Color(0xFF21262D) : const Color(0xFFE5E7EB),
                                      ),
                                      errorWidget: (_, _, _) => _buildInitials(user, isDark),
                                    )
                                  : _buildInitials(user, isDark),
                            ),
                          ),
                          // Online Dot
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF0D1117) : Colors.white,
                                  width: 2.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 58,
                        child: Text(
                          firstName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(Profile user, bool isDark) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName.trim()[0].toUpperCase()
        : '?';
    return Container(
      color: isDark ? const Color(0xFF21262D) : const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
