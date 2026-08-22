import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/verification_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/media_download_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../services/general_settings_provider.dart';
import '../services/view_tracking_service.dart';
import '../services/screenshot_protection_service.dart';
import '../screens/thread_detail_screen.dart';
import '../screens/create_thread_screen.dart';
import '../screens/communities/community_detail_screen.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import 'poll_widget.dart';
import 'comments_sheet.dart';
import '../screens/profile/profile_screen.dart';
import 'share_post_sheet.dart';
import 'thread_image_carousel.dart';
import '../state/music_playback_controller.dart';
import '../models/music_track.dart';
import '../state/monetization_controller.dart';
import 'expandable_post_text.dart';

import 'voice_post_player.dart';
import 'thread_card_components/thread_actions.dart';
part 'thread_card_components/quick_actions_sheet.dart';
part 'thread_card_components/post_media_and_actions.dart';


void showThreadQuickActionsSheet({
  required BuildContext context,
  required DatabaseService dbService,
  required ThreadPost post,
  bool isCommunityModerator = false,
  VoidCallback? onDeletePost,
}) {
  final isAuthor = post.userId == dbService.currentUid;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      if (isAuthor) {
        return _AuthorActionsSheet(
          post: post,
          dbService: dbService,
          parentContext: context,
          onDeletePost: onDeletePost,
        );
      } else {
        return _QuickActionsSheet(
          post: post,
          dbService: dbService,
          parentContext: context,
          isCommunityModerator: isCommunityModerator,
          onDeletePost: onDeletePost,
        );
      }
    },
  );
}

class CustomThreadCard extends StatefulWidget {
  final ThreadPost post;
  final bool isCommunityModerator;

  const CustomThreadCard({super.key, required this.post, this.isCommunityModerator = false});

  @override
  State<CustomThreadCard> createState() => _CustomThreadCardState();
}

class _CustomThreadCardState extends State<CustomThreadCard> {

  @override
  void initState() {
    super.initState();
    // Commenter profile loading removed from initState to avoid
    // N API calls when the feed renders. Avatars are shown lazily
    // only after the comment sheet is opened.
  }

  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SharePostSheet(post: widget.post),
    );
  }

  void _showQuickActions(BuildContext context, DatabaseService dbService, ThreadPost post) {
    showThreadQuickActionsSheet(
      context: context,
      dbService: dbService,
      post: post,
      isCommunityModerator: widget.isCommunityModerator,
    );
  }

  void _showCommentsBottomSheet(BuildContext context, ThreadPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => CommentsSheet(post: post),
    );
  }

  void _showRepostOptions(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final targetPostId = post.isRepost && post.repostedPost != null ? post.repostedPost!.id : post.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(CupertinoIcons.arrow_2_circlepath, color: context.textPrimary),
                title: Text('Repost', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
                subtitle: Text('Instantly share this post to your feed', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  dbService.repostThread(targetPostId).then((success) {
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post status updated")),
                      );
                    }
                  });
                },
              ),
              Divider(height: 1, color: context.border),
              ListTile(
                leading: Icon(Icons.edit_note, color: context.textPrimary),
                title: Text('Quote Post', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
                subtitle: Text('Share this post and add your own comment', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final targetPost = post.isRepost && post.repostedPost != null ? post.repostedPost! : post;
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(
                      child: CreateThreadScreen(quotePost: targetPost),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildNestedOriginalPost(BuildContext context, DatabaseService dbService, ThreadPost origPost) {
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
                    ? CachedNetworkImageProvider(origPost.author.avatarUrl!, maxHeight: 150)
                    : null,
                child: origPost.author.avatarUrl == null || origPost.author.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 10)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                origPost.author.fullName,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
              ),
              const SizedBox(width: 4),
              Text(
                "@${origPost.author.username}",
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            origPost.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hindSiliguri(fontSize: 14.5, color: context.textPrimary, height: 1.35),
          ),
          if (origPost.imageUrls != null && origPost.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMusicImageStack(
              context: context,
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

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    return Selector<DatabaseService, ThreadPost>(
      selector: (_, db) => db.getLatestPost(widget.post),
      builder: (context, post, child) {
        // If this post was deleted, render nothing.
        if (dbService.isPostDeleted(post.id)) return const SizedBox.shrink();

        final isVerified = post.author.isVerified;
        final isPremiumAuthor = post.author.hasScreenshotProtection || post.author.isPremium;

        return VisibilityDetector(
          key: Key('visibility_post_${post.id}'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0.5) {
              Provider.of<ViewTrackingService>(context, listen: false).trackView(post.id);
            }
            if (isPremiumAuthor) {
              if (info.visibleFraction >= 0.4) {
                ScreenshotProtectionService.enableProtection();
              } else {
                ScreenshotProtectionService.disableProtection();
              }
            }
          },
          child: RepaintBoundary(
            child: InkWell(
            hoverColor: Colors.transparent,
            onTap: () {
              final targetPost = (post.isRepost && (post.quoteText == null || post.quoteText!.isEmpty)) 
                  ? post.repostedPost! 
                  : post;
              Navigator.push(
                context,
                NoTransitionPageRoute(
                  child: ThreadDetailScreen(post: targetPost),
                ),
              );
            },
            onLongPress: () => _showQuickActions(context, dbService, post),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0, top: 8.0, bottom: 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.pin_fill,
                          size: 12,
                          color: context.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Pinned post',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 6.0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftColumn(context, dbService, post),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRightColumn(context, dbService, post, isVerified),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 0.5, color: context.border),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildLeftColumn(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final avatarWidget = CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[900],
      backgroundImage: post.isAnonymous
          ? const AssetImage('assets/anonymous_avatar.png') as ImageProvider
          : ((post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(post.author.avatarUrl!, maxHeight: 150)
              : null),
      child: (!post.isAnonymous && (post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty))
          ? const Icon(Icons.person, size: 20, color: Colors.white54)
          : null,
    );

    return Column(
      children: [
        if (post.isAnonymous)
          avatarWidget
        else
          GestureDetector(
            onTap: () {
              final isOwn = post.userId == dbService.currentUid;
              Navigator.push(
                context,
                NoTransitionPageRoute(
                  child: ProfileScreen(userId: isOwn ? null : post.userId),
                ),
              );
            },
            child: avatarWidget,
          ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: 1.5,
            color: context.border,
          ),
        ),
        if (post.commenterAvatars != null && post.commenterAvatars!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildCommenterAvatars(context, post.commenterAvatars!),
        ],
      ],
    );
  }

  Widget _buildCommenterAvatars(BuildContext context, List<String> avatars) {
    final displayAvatars = avatars.take(3).toList();
    if (displayAvatars.isEmpty) return const SizedBox.shrink();

    final count = displayAvatars.length;
    final double containerWidth = 28.0;
    final double containerHeight = 28.0;

    Widget buildAvatar(String url, double size, double top, double left) {
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.cardBg, width: 2.0),
            image: url.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(url, maxHeight: 50),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: url.isEmpty
              ? Icon(Icons.person, size: size - 6, color: Colors.white54)
              : null,
        ),
      );
    }

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (count == 1)
            buildAvatar(displayAvatars[0], 20.0, 4.0, 4.0),
          if (count == 2) ...[
            buildAvatar(displayAvatars[1], 14.0, 2.0, 2.0),
            buildAvatar(displayAvatars[0], 18.0, 8.0, 8.0),
          ],
          if (count == 3) ...[
            buildAvatar(displayAvatars[2], 12.0, 14.0, 2.0),
            buildAvatar(displayAvatars[1], 14.0, 2.0, 4.0),
            buildAvatar(displayAvatars[0], 18.0, 8.0, 10.0),
          ],
        ],
      ),
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    DatabaseService dbService,
    ThreadPost post,
    bool isVerified,
  ) {
    final monetization = Provider.of<MonetizationController>(context);
    final bool isLocked = post.isSubscriberOnly && post.userId != dbService.currentUid && !monetization.isSubscribedTo(post.userId);
    final bool isOwn = post.userId == dbService.currentUid;
    final bool showVerified = !post.isAnonymous && isVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: post.isAnonymous
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          NoTransitionPageRoute(
                            child: ProfileScreen(userId: isOwn ? null : post.userId),
                          ),
                        );
                      },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.author.fullName} ',
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: context.textPrimary,
                        ),
                      ),
                      if (showVerified)
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2, right: 4),
                            child: VerificationBadge(
                              isVerified: post.author.isVerified,
                              badgeType: post.author.badgeType,
                              size: 14,
                            ),
                          ),
                        ),
                      if (post.isAnonymous && isOwn)
                        WidgetSpan(
                          child: Container(
                            margin: const EdgeInsets.only(left: 2, right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Pigeon Alias 🕵️",
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ),
                        ),
                      TextSpan(
                        text: post.isAnonymous ? '@pigeon_alias' : '@${post.author.username}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              post.createdAt,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: context.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showQuickActions(context, dbService, post),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.more_horiz,
                  color: context.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        if (post.community != null) ...[
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                NoTransitionPageRoute(
                  child: CommunityDetailScreen(community: post.community!),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.group,
                  size: 13,
                  color: Color(0xFF1E824C),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    post.community!.name,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E824C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 3),
        if (isLocked)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBg.withValues(alpha: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "This content is for subscribers only.",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16.5,
                        color: context.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Go to profile and trigger subscribe
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(userId: post.userId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text("Unlock"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ExpandablePostText(
            text: post.content,
          ),
        if (post.isRepost && post.repostedPost != null)
          _buildNestedOriginalPost(context, dbService, post.repostedPost!),
        if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMusicImageStack(
            context: context,
            imageUrls: post.imageUrls!,
            height: 220,
            musicTrack: post.musicTrack,
            postId: post.id,
          ),
        ],
        if (post.videoUrl != null && post.videoUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _sharePost(context),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.0),
                image: Provider.of<GeneralSettingsProvider>(context).lowDataMode 
                    ? null
                    : const DecorationImage(
                        image: CachedNetworkImageProvider("https://images.unsplash.com/photo-1492691527719-9d1e07e534b4", maxHeight: 400),
                        fit: BoxFit.cover,
                        opacity: 0.6,
                      ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white70,
                    child: Icon(Icons.play_arrow, color: Colors.black, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.black54,
                    child: Text(
                      post.videoUrl!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
        if (post.audioUrl != null && post.audioUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          VoicePostPlayer(audioUrl: post.audioUrl!),
        ],
        PollWidget(post: post, dbService: dbService),
        const SizedBox(height: 8),
        ThreadActions(
          post: post,
          dbService: dbService,
          onShowComments: () => _showCommentsBottomSheet(context, post),
          onShowRepostOptions: () => _showRepostOptions(context, dbService, post),
          onShare: () => _sharePost(context),
        ),
        const SizedBox(height: 8),
      ], // end of else ...[
      ], // end of Column children
    );
  }




}

// ─── Quick Actions Bottom Sheet (Twitter/X Style) ─────────────────────────────
