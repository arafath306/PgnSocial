import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/community_service.dart';
import '../../utils/app_theme.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart';
import 'community_search_screen.dart';
import '../../models/community.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  List<String> _pinnedIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPinnedIds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commService = Provider.of<CommunityService>(context, listen: false);
      commService.refreshAllCommunities();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPinnedIds() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pinnedIds = prefs.getStringList('pinned_communities_ids') ?? [];
      });
    }
  }

  Widget _buildCommunityAvatar(Community community, double size) {
    Widget avatar;
    if (community.avatarUrl != null && community.avatarUrl!.isNotEmpty) {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(size * 0.3),
          image: DecorationImage(
            image: CachedNetworkImageProvider(community.avatarUrl!),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      );
    } else {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.primaryAccent,
              context.primaryAccent.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: context.primaryAccent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            community.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (_pinnedIds.contains(community.id)) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber[600],
                shape: BoxShape.circle,
                border: Border.all(color: context.scaffoldBg, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.push_pin_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    return avatar;
  }

  Widget _buildYourCommunitiesTab(CommunityService service) {
    if (service.isLoadingJoined) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (service.joinedCommunities.isEmpty) {
      return _buildEmptyState(
        "No Communities Yet",
        "Join communities to connect with others and see them here.",
        Icons.explore_off_rounded,
        action: () => _tabController.animateTo(1),
      );
    }

    final sortedCommunities = List<Community>.from(service.joinedCommunities);
    sortedCommunities.sort((a, b) {
      final aPinned = _pinnedIds.contains(a.id);
      final bPinned = _pinnedIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    return RefreshIndicator(
      color: context.primaryAccent,
      onRefresh: () => service.refreshAllCommunities(),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: sortedCommunities.length,
        separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: context.border),
        itemBuilder: (context, index) {
          final community = sortedCommunities[index];
          final isOwner = community.myRole == 'owner';
          final isModerator = community.myRole == 'moderator';
          final isPinned = _pinnedIds.contains(community.id);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: community)),
              ).then((_) {
                _loadPinnedIds();
                service.refreshAllCommunities();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildCommunityAvatar(community, 48),
                      if (isPinned)
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.amber[600],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.push_pin, size: 8, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                community.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (community.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                            ],
                            const SizedBox(width: 8),
                            if (isOwner || isModerator)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOwner
                                      ? Colors.purple.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isOwner ? "Owner" : "Mod",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isOwner ? Colors.purple : Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          community.description ?? "A Pigeon Community",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(CupertinoIcons.person_2_fill, size: 11, color: context.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              "${community.memberCount} members",
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: context.textMuted,
                                  fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "·",
                              style: TextStyle(color: context.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              community.privacy == 'public' ? "Public" : "Private",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_right, size: 14, color: context.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab(CommunityService service) {
    if (service.isLoadingRecommended) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (service.recommendedCommunities.isEmpty) {
      return _buildEmptyState(
        "No New Communities",
        "You've joined all available public communities!",
        Icons.check_circle_outline_rounded,
      );
    }

    return RefreshIndicator(
      color: context.primaryAccent,
      onRefresh: () => service.refreshAllCommunities(),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: service.recommendedCommunities.length,
        separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: context.border),
        itemBuilder: (context, index) {
          final community = service.recommendedCommunities[index];
          final bool isJoined = community.myRole != null;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: community)),
              ).then((_) {
                _loadPinnedIds();
                service.refreshAllCommunities();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  _buildCommunityAvatar(community, 48),
                  const SizedBox(width: 14),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                community.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: context.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (community.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          community.description ?? "A Pigeon Community",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(CupertinoIcons.person_2_fill, size: 10, color: context.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              "${community.memberCount} members",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "·",
                              style: TextStyle(color: context.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              community.privacy == 'public' ? "Public" : "Private",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Join Button
                  GestureDetector(
                    onTap: () async {
                      if (isJoined) {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: context.cardBg,
                            title: Text("Leave Community", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
                            content: Text("Are you sure you want to leave ${community.name}?", style: GoogleFonts.inter(color: context.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text("Cancel", style: TextStyle(color: context.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Leave", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await service.leaveCommunity(community.id);
                          service.fetchJoinedCommunities();
                          service.fetchRecommendedCommunities();
                        }
                      } else {
                        await service.joinCommunity(community.id);
                        service.fetchJoinedCommunities();
                        service.fetchRecommendedCommunities();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isJoined
                            ? context.border.withValues(alpha: 0.3)
                            : context.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isJoined ? "Joined" : "Join",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isJoined ? context.textSecondary : context.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: context.primaryAccent),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  "Explore Now",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Communities",
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.search, color: context.textPrimary),
            tooltip: "Search Communities",
            onPressed: () {
              final service = Provider.of<CommunityService>(context, listen: false);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const CommunitySearchScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              ).then((_) {
                service.fetchJoinedCommunities();
                service.fetchRecommendedCommunities();
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: GestureDetector(
              onTap: () {
                final service = Provider.of<CommunityService>(context, listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCommunityScreen(),
                  ),
                ).then((_) {
                  service.fetchJoinedCommunities();
                  service.fetchRecommendedCommunities();
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryAccent,
                      context.primaryAccent.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: context.primaryAccent,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelColor: context.textPrimary,
                unselectedLabelColor: context.textSecondary,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
                tabs: const [
                  Tab(text: "Your Communities"),
                  Tab(text: "Discover"),
                ],
              ),
              Divider(height: 1, thickness: 0.5, color: context.border),
            ],
          ),
        ),
      ),
      body: Consumer<CommunityService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildYourCommunitiesTab(service),
              _buildDiscoverTab(service),
            ],
          );
        },
      ),
    );
  }
}
