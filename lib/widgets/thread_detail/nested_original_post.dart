import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/thread_post.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/routes.dart';
import '../../screens/thread_detail_screen.dart';
import 'thread_detail_music_player.dart';
import '../verification_badge.dart';

class NestedOriginalPost extends StatelessWidget {
  final ThreadPost origPost;
  final DatabaseService dbService;

  const NestedOriginalPost({
    super.key,
    required this.origPost,
    required this.dbService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          NoTransitionPageRoute(
            child: ThreadDetailScreen(post: origPost),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 16, thickness: 0.5, color: context.border),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: origPost.author.avatarUrl != null && origPost.author.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(origPost.author.avatarUrl!)
                    : null,
                backgroundColor: Colors.grey[800],
                child: (origPost.author.avatarUrl == null || origPost.author.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                origPost.author.fullName,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              if (origPost.author.isVerified) ...[
                const SizedBox(width: 4),
                VerificationBadge(
                  isVerified: true,
                  badgeType: origPost.author.badgeType,
                  size: 12,
                ),
              ],
              const SizedBox(width: 4),
              Text(
                '@${origPost.author.username}',
                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            origPost.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
          ),
          if (origPost.imageUrls != null && origPost.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 6),
            MusicImageStack(
              imageUrls: origPost.imageUrls!,
              height: 120,
              musicTrack: origPost.musicTrack,
              postId: origPost.id,
            ),
          ],
        ],
      ),
    );
  }
}
