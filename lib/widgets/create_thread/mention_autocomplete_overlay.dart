import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile.dart';
import '../../utils/app_theme.dart';
import '../verification_badge.dart';

class MentionAutocompleteOverlay extends StatelessWidget {
  final List<Profile> users;
  final bool isLoading;
  final ValueChanged<Profile> onUserSelected;

  const MentionAutocompleteOverlay({
    super.key,
    required this.users,
    required this.isLoading,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && users.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;
    final accentColor = const Color(0xFF1D9BF0);

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: users.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final user = users[index];
                final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: accentColor.withAlpha(30),
                    backgroundImage: hasAvatar
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: !hasAvatar
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        VerificationBadge(
                          isVerified: user.isVerified,
                          badgeType: user.badgeType,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textMuted,
                    ),
                  ),
                  onTap: () => onUserSelected(user),
                );
              },
            ),
    );
  }
}
