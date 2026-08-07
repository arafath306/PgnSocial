import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/profile.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/verification_badge.dart';
import '../screens/profile/profile_screen.dart';

class SuggestedAccountsCarousel extends StatefulWidget {
  final List<Profile> suggestedProfiles;
  final VoidCallback onDismiss;

  const SuggestedAccountsCarousel({
    super.key,
    required this.suggestedProfiles,
    required this.onDismiss,
  });

  @override
  State<SuggestedAccountsCarousel> createState() => _SuggestedAccountsCarouselState();
}

class _SuggestedAccountsCarouselState extends State<SuggestedAccountsCarousel> {
  final Set<String> _locallyFollowed = {};

  @override
  Widget build(BuildContext context) {
    if (widget.suggestedProfiles.isEmpty) return const SizedBox.shrink();

    final dbService = Provider.of<DatabaseService>(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: context.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "Suggested for You",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onDismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Carousel
          SizedBox(
            height: 190,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: widget.suggestedProfiles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final profile = widget.suggestedProfiles[index];
                final isFollowing = dbService.isFollowingUser(profile.id) || _locallyFollowed.contains(profile.id);

                return _buildUserCard(context, dbService, profile, isFollowing);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    DatabaseService dbService,
    Profile profile,
    bool isFollowing,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: profile.id),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.border,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: profile.isVerified
                      ? const Color(0xFF0095F6).withValues(alpha: 0.4)
                      : context.border,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 52,
                        height: 52,
                        placeholder: (context, url) => Container(
                          color: context.cardBg,
                        ),
                        errorWidget: (context, url, err) => Icon(
                          Icons.person,
                          size: 28,
                          color: context.textMuted,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 28,
                        color: context.textMuted,
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Full Name & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                if (profile.isVerified) ...[
                  const SizedBox(width: 3),
                  VerificationBadge(
                    isVerified: profile.isVerified,
                    badgeType: profile.badgeType,
                    size: 13,
                  ),
                ],
              ],
            ),

            // Username (@handle)
            Text(
              '@${profile.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 10),

            // Follow Button
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    if (isFollowing) {
                      _locallyFollowed.remove(profile.id);
                    } else {
                      _locallyFollowed.add(profile.id);
                    }
                  });
                  await dbService.toggleFollowUser(profile.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? context.cardBg
                      : const Color(0xFF1E824C),
                  foregroundColor: isFollowing
                      ? context.textPrimary
                      : Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  side: isFollowing ? BorderSide(color: context.border, width: 0.8) : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
