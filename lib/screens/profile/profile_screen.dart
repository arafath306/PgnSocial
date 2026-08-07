import 'package:flutter/material.dart';
import '../../widgets/profile_shimmer.dart';
import '../full_screen_media_viewer.dart';
import 'package:dak/l10n/generated/app_localizations.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/verification_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../models/profile.dart';
import '../../models/thread_post.dart';
import '../../utils/routes.dart';
import '../../utils/app_theme.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';
import 'subscription_payment_screen.dart';
import 'followers_following_screen.dart';
import '../../widgets/custom_thread_card.dart';
import '../create_thread_screen.dart';
import '../messenger/chat_screen.dart';
import '../../state/monetization_controller.dart';
import '../../services/screenshot_protection_service.dart';


class ProfileScreen extends StatefulWidget {
  /// Pass userId to view another user's profile. Leave null for own profile.
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Profile? _viewedProfile;
  List<ThreadPost> _viewedThreads = [];
  List<ThreadPost> _replies = [];
  List<ThreadPost> _reposts = [];
  bool _isLoading = false;
  
  double? _creatorPrice;

  List<String> get _tabs => [
    AppLocalizations.of(context)!.posts,
    AppLocalizations.of(context)!.replies,
    AppLocalizations.of(context)!.reposts,
    AppLocalizations.of(context)!.media,
  ];

  /// Own profile if userId is null OR matches the current user's Supabase UID
  bool get _isOwnProfile {
    if (widget.userId == null) return true;
    final db = Provider.of<DatabaseService>(context, listen: false);
    final currentUid = db.currentUid;
    final myProfileId = db.myProfile?.id;
    // Check against both currentUid and myProfile.id for robustness
    if (currentUid.isNotEmpty && widget.userId == currentUid) return true;
    if (myProfileId != null && widget.userId == myProfileId) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    ScreenshotProtectionService.disableProtection();
    super.dispose();
  }

  bool _doesFollowMe = false;

  Future<void> _loadProfileData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final targetId = _isOwnProfile ? dbService.currentUid : widget.userId!;

    if (_isOwnProfile) {
      await dbService.fetchMyProfile();
      await dbService.fetchMyThreads();
    } else {
      _viewedProfile = await dbService.fetchProfile(targetId);
      _viewedThreads = await dbService.fetchUserThreads(targetId);
      _doesFollowMe = await dbService.doesUserFollowMe(targetId);
    }

    final currentProfile = _isOwnProfile ? dbService.myProfile : _viewedProfile;
    if (currentProfile?.hasScreenshotProtection == true || currentProfile?.isPremium == true) {
      ScreenshotProtectionService.enableProtection();
    } else {
      ScreenshotProtectionService.disableProtection();
    }

    _replies = await dbService.fetchUserRepliedThreads(targetId);
    _reposts = await dbService.fetchUserReposts(targetId);

    // Fetch monetization info if this is someone else and they can monetize
    if (!_isOwnProfile && _viewedProfile?.canMonetize == true) {
      try {
        final res = await Supabase.instance.client.from('creator_settings').select('monthly_price').eq('creator_id', targetId).maybeSingle();
        if (res != null) {
          _creatorPrice = (res['monthly_price'] as num?)?.toDouble();
        }
      } catch (e) {
        debugPrint("Error fetching creator price: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ── Format helper ──────────────────────────────────────────
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        // Choose correct profile & posts
        final Profile? profile = _isOwnProfile ? db.myProfile : _viewedProfile;
        final List<ThreadPost> threads =
            _isOwnProfile ? db.myThreads : _viewedThreads;

        // While loading own profile for first time
        if (_isOwnProfile && db.myProfile == null) {
          return const ProfileShimmer();
        }

        if (!_isOwnProfile && _isLoading) {
          return const ProfileShimmer();
        }

        final bool isBlocked = !_isOwnProfile && widget.userId != null && db.isBlocked(widget.userId!);
        if (isBlocked) {
          final bool blockedByMe = db.isBlockedByMe(widget.userId!);
          return _buildBlockedProfileView(context, db, widget.userId!, blockedByMe);
        }


        Widget tabSection = Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildTabViews(profile, threads)),
          ],
        );

        Widget bodyContent = tabSection;

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          body: RefreshIndicator(
            color: const Color(0xFF0085FF),
            onRefresh: _loadProfileData,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: _buildHeader(profile, db),
                ),
              ],
              body: bodyContent,
            ),
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(Profile? profile, DatabaseService db) {
    final double coverHeight = 130;
    final double avatarRadius = 55; // 110px diameter
    final double avatarHeightOffset = coverHeight - avatarRadius;
    final List<ThreadPost> threads = _isOwnProfile ? db.myThreads : _viewedThreads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover + Avatar stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Image Area
            GestureDetector(
              onTap: ((profile?.coverUrl ?? '').isNotEmpty) ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenMediaViewer(
                        imageUrls: [profile?.coverUrl ?? ''],
                        initialIndex: 0,
                      ),
                    ),
                  );
                } : null,
              child: Container(
                height: coverHeight,
                width: double.infinity,
                color: Colors.grey[200],
                child: (profile?.coverUrl ?? '').isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profile?.coverUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: _isOwnProfile
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, color: Color(0xFF0085FF), size: 28),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add cover photo',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF0085FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
              ),
            ),
            
            // Header buttons overlay on cover
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  if (ModalRoute.of(context)?.isFirst == false)
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  const Spacer(),
                  if (_isOwnProfile) ...[
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      radius: 18,
                      child: IconButton(
                        tooltip: 'More options',
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
                        onPressed: _showMoreOptions,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      radius: 18,
                      child: IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                           Navigator.push(
                             context,
                             NoTransitionPageRoute(
                               child: SettingsScreen(
                                 onSwitchToProfile: () {
                                   // Already on profile screen
                                 },
                               ),
                             ),
                           );
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ] else ...[
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      radius: 18,
                      child: IconButton(
                        tooltip: 'More options',
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
                        onPressed: _showMoreOptions,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Avatar stacked over cover bottom-left
            Positioned(
              top: avatarHeightOffset,
              left: 16,
              child: GestureDetector(
                onTap: ((profile?.avatarUrl ?? '').isNotEmpty) ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenMediaViewer(
                        imageUrls: [profile?.avatarUrl ?? ''],
                        initialIndex: 0,
                      ),
                    ),
                  );
                } : null,
                child: Stack(
                  children: [
                    Container(
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.scaffoldBg, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (profile?.avatarUrl ?? '').isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profile?.avatarUrl ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _defaultAvatar(size: avatarRadius * 2),
                                errorWidget: (context, url, error) => _defaultAvatar(size: avatarRadius * 2),
                              )
                            : _defaultAvatar(size: avatarRadius * 2),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),

        // Spacing for buttons next to avatar
        const SizedBox(height: 12),

        // Buttons next to avatar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isOwnProfile) ...[
                _outlinedBtn(AppLocalizations.of(context)!.editProfile, onTap: () async {
                  if (profile != null) {
                    await Navigator.push(
                      context,
                      NoTransitionPageRoute(
                        child: EditProfileScreen(
                          profile: profile.toJson(),
                        ),
                      ),
                    );
                    db.fetchMyProfile();
                  }
                }),
              ] else ...[
                Consumer<DatabaseService>(
                  builder: (ctx, dbS, _) {
                    final isFollowing = dbS.isFollowingUser(widget.userId!);
                    return _filledBtn(
                      isFollowing ? 'Following' : 'Follow',
                      onTap: () => dbS.toggleFollowUser(widget.userId!),
                      outlined: isFollowing,
                    );
                  },
                ),
                if (profile != null && (!profile.isPrivate || _doesFollowMe)) ...[
                  const SizedBox(width: 8),
                  _outlinedBtn(
                    'Message',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(otherUser: profile),
                        ),
                      );
                    },
                  ),
                ],
                if (_creatorPrice != null && _creatorPrice! > 0) ...(() {
                  final mc = Provider.of<MonetizationController>(context, listen: true);
                  final isSubbed = mc.isSubscribedTo(widget.userId!);
                  return [
                    const SizedBox(width: 8),
                    _filledBtn(
                      isSubbed ? 'Subscribed' : 'Subscribe',
                      onTap: isSubbed 
                        ? () {} // Maybe add unsubscribe later
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionPaymentScreen(
                                  creatorId: widget.userId!,
                                  creatorName: profile!.fullName,
                                  planPrice: _creatorPrice!,
                                ),
                              ),
                            );
                          },
                      outlined: isSubbed,
                    ),
                  ];
                }()),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Name and username details below avatar, taking full width
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      profile?.fullName ?? 'User',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile?.isVerified == true ||
                      (_isOwnProfile && db.myProfile?.isVerified == true) ||
                      (profile != null && profile.id == db.currentUid && db.myProfile?.isVerified == true)) ...[
                    const SizedBox(width: 6),
                    VerificationBadge(isVerified: profile?.isVerified ?? false, badgeType: profile?.badgeType, size: 20),
                  ],
                ],
              ),
              Text(
                '@${profile?.username ?? ''}',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Stats row — tappable followers and following
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (profile == null) return;
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(
                      child: FollowersFollowingScreen(
                        userId: profile.id,
                        username: profile.username,
                        listType: FollowListType.followers,
                        isOwnProfile: _isOwnProfile,
                      ),
                    ),
                  );
                },
                child: _statItem(_fmt(profile?.followersCount ?? 0), AppLocalizations.of(context)!.followers),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  if (profile == null) return;
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(
                      child: FollowersFollowingScreen(
                        userId: profile.id,
                        username: profile.username,
                        listType: FollowListType.following,
                        isOwnProfile: _isOwnProfile,
                      ),
                    ),
                  );
                },
                child: _statItem(_fmt(profile?.followingCount ?? 0), AppLocalizations.of(context)!.following),
              ),
              const SizedBox(width: 20),
              _statItem(_fmt(threads.length), AppLocalizations.of(context)!.posts),
            ],
          ),
        ),

        // Bio
        if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              profile.bio!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],

        // Location (country) + Join date
        if ((profile?.country != null && profile!.country!.isNotEmpty) ||
            profile?.createdAt != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (profile?.country != null &&
                    profile!.country!.isNotEmpty) ...[
                  Icon(Icons.public_rounded,
                      size: 14, color: context.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    profile.country!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
                if (profile?.country != null &&
                    profile!.country!.isNotEmpty &&
                    profile.createdAt != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '·',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (profile?.createdAt != null) ...[
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: context.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    () {
                      final dt = profile!.createdAt!;
                      const months = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      return 'Joined ${months[dt.month - 1]} ${dt.year}';
                    }(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 4),
      ],
    );
  }


  Widget _defaultAvatar({double size = 40}) => Container(
        color: const Color(0xFF0085FF),
        child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.55),
      );

  Widget _statItem(String count, String label) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: '$count ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        TextSpan(
          text: label,
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: context.textSecondary),
        ),
      ]),
    );
  }

  Widget _outlinedBtn(String label, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.border),
          ),
          child: Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary)),
        ),
      );

  Widget _filledBtn(String label,
      {required VoidCallback onTap, bool outlined = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          decoration: BoxDecoration(
            color: outlined ? context.cardBg : (context.isDarkMode ? Colors.white : Colors.black),
            borderRadius: BorderRadius.circular(20),
            border:
                outlined ? Border.all(color: context.border) : null,
          ),
          child: Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: outlined ? context.textPrimary : (context.isDarkMode ? Colors.black : Colors.white))),
        ),
      );



  // ── Tab Bar ────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.border, width: 1)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: context.textPrimary,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: context.textPrimary,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.hindSiliguri(
              fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              GoogleFonts.hindSiliguri(fontSize: 14),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      );

  Widget _buildTabViews(Profile? profile, List<ThreadPost> threads) =>
      TabBarView(
        controller: _tabController,
        children: [
          KeepAliveWrapper(child: _postsTab(profile, threads)),
          KeepAliveWrapper(child: _repliesTab(profile)),
          KeepAliveWrapper(child: _repostsTab(profile)),
          KeepAliveWrapper(child: _mediaTab(profile, threads)),
        ],
      );

  Widget _postsTab(Profile? profile, List<ThreadPost> threads) {
    // Filter out posts that have been deleted during this session
    final db = Provider.of<DatabaseService>(context, listen: false);
    final visibleThreads = threads.where((p) => !db.isPostDeleted(p.id)).toList();

    if (visibleThreads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: context.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_outlined,
                  size: 34, color: context.textMuted),
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.noPostsYet,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500)),
            if (_isOwnProfile) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E824C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  elevation: 0,
                ),
                child: Text('Write a post',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 72),
      physics: const BouncingScrollPhysics(),
      itemCount: visibleThreads.length,
      itemBuilder: (context, i) => CustomThreadCard(
        key: ValueKey(visibleThreads[i].id),
        post: visibleThreads[i],
      ),
    );
  }

  Widget _repliesTab(Profile? profile) {
    // Filter out posts that have been deleted during this session
    final db = Provider.of<DatabaseService>(context, listen: false);
    final visibleReplies = _replies.where((p) => !db.isPostDeleted(p.id)).toList();

    if (visibleReplies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: context.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.forum_outlined,
                  size: 34, color: context.textMuted),
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.noRepliesYet,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 72),
      physics: const BouncingScrollPhysics(),
      itemCount: visibleReplies.length,
      itemBuilder: (context, i) => CustomThreadCard(
        key: ValueKey(visibleReplies[i].id),
        post: visibleReplies[i],
      ),
    );
  }



  Widget _repostsTab(Profile? profile) {
    // Filter out posts that have been deleted during this session
    final db = Provider.of<DatabaseService>(context, listen: false);
    final visibleReposts = _reposts.where((p) => !db.isPostDeleted(p.id)).toList();

    if (visibleReposts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: context.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(CupertinoIcons.arrow_2_circlepath,
                  size: 34, color: context.textMuted),
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.noRepostsYet,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 72),
      physics: const BouncingScrollPhysics(),
      itemCount: visibleReposts.length,
      itemBuilder: (context, i) => CustomThreadCard(
        key: ValueKey(visibleReposts[i].id),
        post: visibleReposts[i],
      ),
    );
  }

  Widget _mediaTab(Profile? profile, List<ThreadPost> threads) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final mediaThreads = threads.where((p) {
      if (db.isPostDeleted(p.id)) return false;
      final hasImages = p.imageUrls != null && p.imageUrls!.isNotEmpty;
      final hasVideo = p.videoUrl != null && p.videoUrl!.isNotEmpty;
      return hasImages || hasVideo;
    }).toList();

    if (mediaThreads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: context.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.image_outlined,
                  size: 34, color: context.textMuted),
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.noMediaYet,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 72),
      physics: const BouncingScrollPhysics(),
      itemCount: mediaThreads.length,
      itemBuilder: (context, i) => CustomThreadCard(
        key: ValueKey(mediaThreads[i].id),
        post: mediaThreads[i],
      ),
    );
  }


  // ── More Options ───────────────────────────────────────────
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      backgroundColor: context.cardBg,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            if (_isOwnProfile) ...[
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text('Share Profile',
                    style: GoogleFonts.hindSiliguri(fontSize: 15)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text('Log Out',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // close bottom sheet
                  Provider.of<AuthService>(context, listen: false).handleSignout();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.red),
                title: Text('Block',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context); // close bottom sheet
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        'Block this account?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'Are you sure you want to block this account?',
                        style: GoogleFonts.inter(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: Text('Block', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);
                    final db = Provider.of<DatabaseService>(context, listen: false);
                    await settings.blockUserById(widget.userId!);
                    if (!mounted) return;
                    db.fetchBlockedMutedLists();
                    db.fetchFollowingList();
                    db.fetchFeed();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account has been blocked.', style: GoogleFonts.inter())),
                    );
                    Navigator.pop(context); // Go back
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: Text('Report',
                    style: GoogleFonts.inter(
                        fontSize: 15, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context); // close bottom sheet
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          'Reason for reporting',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Describe why you are reporting...',
                            hintStyle: GoogleFonts.inter(),
                          ),
                          style: GoogleFonts.inter(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: Text('Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                  if (reason != null && reason.isNotEmpty && mounted) {
                    final db = Provider.of<DatabaseService>(context, listen: false);
                    await db.reportProfile(widget.userId!, reason);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Report submitted. Thank you!', style: GoogleFonts.inter())),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  
  Widget _buildBlockedProfileView(BuildContext context, DatabaseService db, String targetId, bool blockedByMe) {
    final username = _viewedProfile?.username ?? 'user';
    final fullName = _viewedProfile?.fullName ?? 'User';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "@$username",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.isDarkMode ? Colors.grey[850] : Colors.grey[200],
                  border: Border.all(color: context.border, width: 2),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                blockedByMe ? fullName : "Account unavailable",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "@$username",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: context.border, height: 1),
              const SizedBox(height: 24),
              Icon(
                Icons.block_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                blockedByMe
                    ? "You blocked this account"
                    : "You cannot view this account",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                blockedByMe
                    ? "Unblock @$username to see their posts and profile info."
                    : "You are blocked from following @$username or viewing their posts.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (blockedByMe) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final settingsProvider = Provider.of<GeneralSettingsProvider>(context, listen: false);
                    await settingsProvider.unblockAccount(targetId);
                    await db.fetchBlockedMutedLists();
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("@$username has been unblocked."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    "Unblock",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
