import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../utils/app_theme.dart';
import 'profile/profile_screen.dart';
import 'topic/topic_threads_screen.dart';
import '../widgets/custom_thread_card.dart';
import '../widgets/search_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchExploreScreen extends StatefulWidget {
  final String? initialQuery;
  final int initialTabIndex;

  const SearchExploreScreen({
    super.key,
    this.initialQuery,
    this.initialTabIndex = 0,
  });

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<String> _recentSearches = [];
  List<Profile> _searchResults = [];
  List<ThreadPost> _searchPostResults = [];
  List<Profile> _recommended = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();
  int _searchTabIndex = 0; // 0 for Accounts, 1 for Posts

  List<Map<String, dynamic>> _trendingTopics = [];
  List<Map<String, dynamic>> _risingTopics = [];
  List<Map<String, dynamic>> _discussedTopics = [];
  bool _isTopicsLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchTabIndex = widget.initialTabIndex;
      _onSearchChanged(widget.initialQuery!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
      _loadTopics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecommendations() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final recs = await dbService.getRecommendedProfiles();
    if (mounted) {
      setState(() {
        _recommended = recs;
      });
    }
  }

  void _loadTopics() async {
    if (!mounted) return;
    setState(() => _isTopicsLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final trending = await dbService.fetchTrendingTopics();
    final rising = await dbService.fetchRisingTopics();
    final discussed = await dbService.fetchMostDiscussedTopics();
    if (mounted) {
      setState(() {
        _trendingTopics = trending;
        _risingTopics = rising;
        _discussedTopics = discussed;
        _isTopicsLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchPostResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final profileFuture = dbService.searchProfiles(trimmed);
    final threadFuture = dbService.searchThreads(trimmed);

    final results = await Future.wait([profileFuture, threadFuture]);

    if (mounted) {
      setState(() {
        _searchResults = results[0] as List<Profile>;
        _searchPostResults = results[1] as List<ThreadPost>;
        _isLoading = false;
      });
    }
  }

  void _addToHistory(String item) {
    if (item.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(item);
      _recentSearches.insert(0, item);
      if (_recentSearches.length > 6) {
        _recentSearches.removeLast();
      }
    });
  }

  Widget _buildUserRow(Profile user, DatabaseService dbService) {
    final currentUid = dbService.myProfile?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: () {
          _addToHistory(user.fullName);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfileScreen(userId: user.id == currentUid ? null : user.id),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Circular Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: context.isDarkMode
                  ? const Color(0xFF1B3B2B)
                  : const Color(0xFFE8F5E9),
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: context.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Center: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Username
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                  // Name
                  Text(
                    user.fullName,
                    style: GoogleFonts.hindSiliguri(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Followers
                  Text(
                    "${user.followersCount} ${user.followersCount == 1 ? 'follower' : 'followers'}",
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Follow Button
            Selector<DatabaseService, bool>(
              selector: (_, db) => db.isFollowingUser(user.id),
              builder: (context, isFollowing, _) {
                return OutlinedButton(
                  onPressed: () {
                    dbService.toggleFollowUser(user.id);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isFollowing
                          ? (context.isDarkMode
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade300)
                          : context.border,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    isFollowing ? "Following" : "Follow",
                    style: GoogleFonts.hindSiliguri(
                      color: isFollowing ? context.textMuted : context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData iconData, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, size: 18, color: iconColor ?? const Color(0xFF1E824C)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(String rank, String tag, String postsCount, {String? headline, String? summary}) {
    final hasAiContext = headline != null && headline.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TopicThreadsScreen(topicName: tag)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Trending · #$rank",
                        style: GoogleFonts.inter(
                          color: context.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasAiContext) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E824C).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF1E824C).withValues(alpha: 0.2), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 10,
                                color: Color(0xFF1E824C),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "AI Context",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1E824C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasAiContext ? headline : (tag.startsWith('#') ? tag : '#$tag'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: hasAiContext ? 16 : 15,
                      color: context.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAiContext 
                      ? "${tag.startsWith('#') ? tag : '#$tag'} · $postsCount"
                      : postsCount,
                    style: GoogleFonts.inter(
                      color: hasAiContext ? const Color(0xFF1E824C) : context.textMuted,
                      fontSize: 12.5,
                      fontWeight: hasAiContext ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (hasAiContext && summary != null && summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF151824)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.isDarkMode
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade200,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        summary,
                        style: GoogleFonts.hindSiliguri(
                          color: context.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_horiz, color: context.textMuted, size: 18),
              onPressed: () {
                // Actions popup option
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRisingTopicItem(String topic, String growth, {String? headline, String? summary}) {
    final hasAiContext = headline != null && headline.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicThreadsScreen(topicName: topic),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAiContext ? headline : (topic.startsWith('#') ? topic : '#$topic'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasAiContext 
                      ? "${topic.startsWith('#') ? topic : '#$topic'} · Rising rapidly"
                      : "Rising rapidly",
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (hasAiContext && summary != null && summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      style: GoogleFonts.hindSiliguri(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                growth,
                style: GoogleFonts.inter(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussedItem(String topic, String replies, {String? headline, String? summary}) {
    final hasAiContext = headline != null && headline.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicThreadsScreen(topicName: topic),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.orange,
                size: 16,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAiContext ? headline : (topic.startsWith('#') ? topic : '#$topic'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.textPrimary,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasAiContext
                      ? "${topic.startsWith('#') ? topic : '#$topic'} · Highly active"
                      : "Highly active discussion",
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (hasAiContext && summary != null && summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      style: GoogleFonts.hindSiliguri(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              replies,
              style: GoogleFonts.inter(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTabButton(int index, String label, int count) {
    final isSelected = _searchTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF1E824C)
                        : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "($count)",
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF1E824C).withValues(alpha: 0.8)
                        : context.textMuted,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Text(
              "No results found",
              style: GoogleFonts.hindSiliguri(color: context.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0, bottom: 2.0),
                      child: Icon(
                        CupertinoIcons.search,
                        color: context.textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                  Text(
                    "Explorer",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // 3-dot menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: context.textPrimary, size: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    color: context.cardBg,
                    elevation: 8,
                    onSelected: (value) {
                      switch (value) {
                        case 'refresh':
                          _loadRecommendations();
                          _loadTopics();
                          break;
                        case 'saved':
                          Navigator.pushNamed(context, '/saved');
                          break;
                        case 'settings':
                          Navigator.pushNamed(context, '/settings');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 18, color: context.textSecondary),
                            const SizedBox(width: 10),
                            Text('Refresh', style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'saved',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_outline_rounded, size: 18, color: context.textSecondary),
                            const SizedBox(width: 10),
                            Text('Saved Posts', style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 18, color: context.textSecondary),
                            const SizedBox(width: 10),
                            Text('Settings', style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Input Box
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  _addToHistory(val);
                },
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.textMuted,
                    size: 20,
                  ),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: context.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  hintText: "Search for posts,users or topics...",
                  hintStyle: GoogleFonts.hindSiliguri(
                    color: context.textMuted,
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  fillColor: context.isDarkMode
                      ? const Color(0xFF151824)
                      : const Color(0xFFF1F1F1),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Search Tab Selector (Only shown when searching)
              if (isSearching) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSearchTabButton(0, "Accounts", _searchResults.length),
                    const SizedBox(width: 12),
                    _buildSearchTabButton(
                      1,
                      "Posts",
                      _searchPostResults.length,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),

              // Search History / Recommendations OR Search Results
              Expanded(
                child: RefreshIndicator(
                  color: context.primaryAccent,
                  onRefresh: () async {
                    _loadRecommendations();
                    _loadTopics();
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: (_isLoading || (_isTopicsLoading && _trendingTopics.isEmpty && !isSearching))
                      ? const SearchShimmer()
                      : isSearching
                      ? (() {
                          if (_searchTabIndex == 0) {
                            if (_searchResults.isEmpty) {
                              return _buildNoResultsView();
                            }
                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 72),
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: context.border),
                              itemBuilder: (context, index) {
                                return RepaintBoundary(
                                  child: _buildUserRow(
                                    _searchResults[index],
                                    dbService,
                                  ),
                                );
                              },
                            );
                          } else {
                            if (_searchPostResults.isEmpty) {
                              return _buildNoResultsView();
                            }
                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 72),
                              itemCount: _searchPostResults.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: context.border),
                              itemBuilder: (context, index) {
                                return CustomThreadCard(
                                  key: ValueKey(_searchPostResults[index].id),
                                  post: _searchPostResults[index],
                                );
                              },
                            );
                          }
                        })()
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 72),
                          children: [
                            // Recent Searches Section
                            if (_recentSearches.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Recent Searches",
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _recentSearches.clear();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      "Clear All",
                                      style: GoogleFonts.hindSiliguri(
                                        color: context.primaryAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _recentSearches.map((search) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.cardBg,
                                      border: Border.all(color: context.border),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 14,
                                          color: context.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            _searchController.text = search;
                                            _onSearchChanged(search);
                                          },
                                          child: Text(
                                            search,
                                            style: GoogleFonts.hindSiliguri(
                                              fontSize: 13,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _recentSearches.remove(search);
                                            });
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: context.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 1- Trending Now
                            _buildSectionHeader(
                              "Trending Now",
                              Icons.trending_up_rounded,
                              iconColor: const Color(0xFF1E824C),
                            ),
                            if (_isTopicsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1E824C),
                                  ),
                                ),
                              )
                            else if (_trendingTopics.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  "No trending topics right now",
                                  style: GoogleFonts.inter(
                                    color: context.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ..._trendingTopics.mapIndexed((index, item) {
                                final posts = item['post_count'] as int? ?? 0;
                                return _buildTrendingItem(
                                  (index + 1).toString(),
                                  item['topic_name'] as String? ?? '',
                                  "$posts ${posts == 1 ? 'post' : 'posts'}",
                                  headline: item['headline'] as String?,
                                  summary: item['summary'] as String?,
                                );
                              }),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: context.border),

                            // 2- Rising Topics
                            _buildSectionHeader(
                              "Rising Topics",
                              Icons.show_chart_rounded,
                              iconColor: Colors.blue,
                            ),
                            if (_isTopicsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1E824C),
                                  ),
                                ),
                              )
                            else if (_risingTopics.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  "No rising topics right now",
                                  style: GoogleFonts.inter(
                                    color: context.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ..._risingTopics.map((item) {
                                final growth = item['growth_percentage'] ?? 0;
                                final sign = growth >= 0 ? '+' : '';
                                return _buildRisingTopicItem(
                                  item['topic_name'] as String? ?? '',
                                  "$sign$growth% growth",
                                  headline: item['headline'] as String?,
                                  summary: item['summary'] as String?,
                                );
                              }),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: context.border),

                            // 3- Most Discussed
                            _buildSectionHeader(
                              "Most Discussed",
                              Icons.forum_rounded,
                              iconColor: Colors.orange,
                            ),
                            if (_isTopicsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1E824C),
                                  ),
                                ),
                              )
                            else if (_discussedTopics.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  "No discussed topics right now",
                                  style: GoogleFonts.inter(
                                    color: context.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ..._discussedTopics.map((item) {
                                final replies =
                                    item['discussion_count'] as int? ?? 0;
                                return _buildDiscussedItem(
                                  item['topic_name'] as String? ?? '',
                                  "$replies ${replies == 1 ? 'reply' : 'replies'} today",
                                  headline: item['headline'] as String?,
                                  summary: item['summary'] as String?,
                                );
                              }),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: context.border),

                            // 4- Recommended for you
                            _buildSectionHeader(
                              "Recommended for you",
                              Icons.person_add_alt_1_rounded,
                              iconColor: const Color(0xFF1E824C),
                            ),
                            if (_recommended.isEmpty)
                              SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text(
                                    "No recommendations found",
                                    style: GoogleFonts.hindSiliguri(
                                      color: context.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._recommended.map((user) {
                                return Column(
                                  children: [
                                    _buildUserRow(user, dbService),
                                    Divider(height: 1, color: context.border),
                                  ],
                                );
                              }),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
