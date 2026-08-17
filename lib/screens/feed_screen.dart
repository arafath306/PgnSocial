import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../widgets/thread_shimmer.dart';
import '../utils/app_theme.dart';
import '../widgets/dak_logo.dart';
import '../widgets/custom_menu_button.dart';
import '../widgets/suggested_accounts_carousel.dart';
import 'communities/community_home_screen.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../state/music_playback_controller.dart';
import '../utils/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback onNavigateToChaStation;
  final VoidCallback onNavigateToCreate;

  const FeedScreen({
    super.key,
    required this.onNavigateToChaStation,
    required this.onNavigateToCreate,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin, RouteAware {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;
  static const double _kAppBarContentHeight = 56.0;
  List<Profile> _suggestedProfiles = [];
  bool _dismissedSuggested = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });

    _scrollController.addListener(() {
      if (_tabController.index == 0) {
        if (_scrollController.position.maxScrollExtent - _scrollController.offset < 400) {
          _triggerLoadMore();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (db.personalizedFeed.isEmpty && !db.isLoading) db.fetchAIFeed();
      if (db.feed.isEmpty && !db.isLoading) db.fetchFeed(silent: true);
      if (db.myProfile == null) db.fetchMyProfile();
      _loadSuggestedProfiles(db);
    });
  }

  Future<void> _loadSuggestedProfiles(DatabaseService db) async {
    final list = await db.fetchSuggestedProfiles(limit: 10);
    if (mounted) {
      setState(() {
        _suggestedProfiles = list;
      });
    }
  }

  void _triggerLoadMore() {
    final db = Provider.of<DatabaseService>(context, listen: false);
    if (db.aiFeedHasMore && !db.isLoading && !_isFetchingMore) {
      setState(() => _isFetchingMore = true);
      db.fetchAIFeed(loadMore: true, silent: true).then((_) {
        if (mounted) setState(() => _isFetchingMore = false);
      });
    }
  }

  Future<void> _onRefresh(int tabIndex) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    await Future.wait([
      db.fetchAIFeed(),
      db.fetchFeed(silent: true),
      _loadSuggestedProfiles(db),
    ]);
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    if (_tabController.index == index) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _tabController.animateTo(index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPushNext() {
    // Pause post music playback as soon as another screen/route is pushed on top
    if (mounted) {
      context.read<MusicPlaybackController>().pause();
    }
    super.didPushNext();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (mounted) {
      context.read<MusicPlaybackController>().pause();
    }
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final prof = context.select<DatabaseService, Profile?>((db) => db.myProfile);
    final showShimmer = context.select<DatabaseService, bool>((db) => db.isLoading && db.personalizedFeed.isEmpty && db.feed.isEmpty);
    final personalizedFeed = context.select<DatabaseService, List<ThreadPost>>((db) => db.personalizedFeed);
    final followingFeed = context.select<DatabaseService, List<ThreadPost>>((db) => db.feed.where((p) => db.isFollowingUser(p.userId)).toList());
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: showShimmer
          ? const SafeArea(child: ThreadShimmer())
          : NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: context.scaffoldBg,
                    floating: true,
                    snap: true,
                    elevation: 0,
                    toolbarHeight: _kAppBarContentHeight,
                    automaticallyImplyLeading: false,
                    titleSpacing: 0,
                    title: Row(
                      children: [
                        if (!isDesktop) const CustomMenuButton(),
                        Expanded(child: Center(child: DakLogo(size: 42))),
                        IconButton(
                          tooltip: 'Communities',
                          icon: Icon(Icons.groups_rounded, color: context.textPrimary, size: 24),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CommunityHomeScreen()),
                          ),
                        ),
                      ],
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(44.5),
                      child: Column(
                        children: [
                          Divider(height: 0.5, thickness: 0.5, color: context.border),
                          _buildTabBar(context),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: () => _onRefresh(0),
                    color: const Color(0xFF1E824C),
                    backgroundColor: context.cardBg,
                    child: _buildFeedList(tabIndex: 0, posts: personalizedFeed, dbService: dbService, prof: prof),
                  ),
                  RefreshIndicator(
                    onRefresh: () => _onRefresh(1),
                    color: const Color(0xFF1E824C),
                    backgroundColor: context.cardBg,
                    child: _buildFeedList(tabIndex: 1, posts: followingFeed, dbService: dbService, prof: prof),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            border: Border(bottom: BorderSide(color: context.border, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final isSelected = _tabController.index == index;
              final labels = ["For You", "Following"];
              return GestureDetector(
                onTap: () => _onTabTapped(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
                          letterSpacing: isSelected ? -0.2 : 0,
                        ),
                        child: Text(labels[index]),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        height: 3,
                        width: isSelected ? 32 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E824C),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildFeedList({
    required int tabIndex,
    required List<ThreadPost> posts,
    required DatabaseService dbService,
    required Profile? prof,
  }) {
    if (tabIndex == 1 && posts.isEmpty && !dbService.isLoading) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCreatePostRow(context, prof)),
          SliverFillRemaining(child: _buildEmptyFollowing(context)),
        ],
      );
    }

    if (posts.isEmpty && !dbService.isLoading) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCreatePostRow(context, prof)),
          SliverFillRemaining(child: _buildEmptyFeed(context, tabIndex)),
        ],
      );
    }

    final showSuggested = !_dismissedSuggested && _suggestedProfiles.isNotEmpty;
    final suggestedPosition = posts.length >= 7 ? 8 : (posts.isNotEmpty ? posts.length + 1 : -1);
    final totalCount = posts.length + 2 + (showSuggested && suggestedPosition > 0 ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0) return _buildCreatePostRow(context, prof);

        if (showSuggested && suggestedPosition > 0) {
          if (index == suggestedPosition) {
            return SuggestedAccountsCarousel(
              suggestedProfiles: _suggestedProfiles,
              onDismiss: () {
                setState(() {
                  _dismissedSuggested = true;
                });
              },
            );
          }
          final postIndex = index > suggestedPosition ? index - 2 : index - 1;
          if (postIndex < posts.length) {
            return RepaintBoundary(
              child: CustomThreadCard(
                key: ValueKey(posts[postIndex].id),
                post: posts[postIndex],
              ),
            );
          }
        } else {
          final postIndex = index - 1;
          if (postIndex < posts.length) {
            return RepaintBoundary(
              child: CustomThreadCard(
                key: ValueKey(posts[postIndex].id),
                post: posts[postIndex],
              ),
            );
          }
        }

        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreatePostRow(BuildContext context, dynamic prof) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onNavigateToCreate,
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: (prof?.avatarUrl != null && prof!.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(prof.avatarUrl!, maxHeight: 150)
                  : null,
              child: (prof?.avatarUrl == null || prof!.avatarUrl!.isEmpty)
                  ? Icon(Icons.person, size: 14, color: context.isDarkMode ? Colors.white54 : Colors.black38)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Send your thoughts...",
                        style: GoogleFonts.inter(color: context.textMuted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFollowing(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_2_alt, size: 48, color: context.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "You aren't following anyone yet.",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            "When you follow people, their posts\nwill show up here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: context.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onNavigateToChaStation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Find people to follow"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed(BuildContext context, int tabIndex) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.news, size: 48, color: context.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "No posts yet.",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
