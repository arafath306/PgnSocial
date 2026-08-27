import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
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
import '../widgets/verification_badge.dart';
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
  bool _isTopicsLoading = true;
  final Map<String, String> _topicImages = {};

  // Filter States
  List<String> _selectedCategories = [];
  String _selectedTimeframe = 'Today';
  String _selectedSortBy = 'Recent';
  bool _filtersApplied = false;
  List<ThreadPost> _filteredPosts = [];
  bool _isFiltering = false;

  // Banner Cycle States
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // Search Debouncer
  Timer? _searchDebounceTimer;

  // Mockup elements state
  String _selectedCategoryChip = 'For you';
  final List<String> _categoryChips = ['For you', 'Trending', 'News', 'Sports'];
  List<ThreadPost> _categoryPosts = [];
  bool _isCategoryLoading = false;

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
    _bannerTimer?.cancel();
    _searchDebounceTimer?.cancel();
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
    if (mounted) {
      setState(() {
        _trendingTopics = trending;
        _isTopicsLoading = false;
        _currentBannerIndex = 0;
      });

      _startBannerAutoCycle();

      // Asynchronously fetch first post images for these topics in background
      // Limit to first 5 topics since only they are visible (Hot Banner + 4 Grid Items) to save network load
      final fetchLimit = trending.take(5);
      for (final topic in fetchLimit) {
        final topicName = topic['topic_name'] as String?;
        if (topicName != null && topicName.isNotEmpty) {
          _fetchTopicImage(topicName, dbService);
        }
      }
    }
  }

  void _startBannerAutoCycle() {
    _bannerTimer?.cancel();
    if (_trendingTopics.isNotEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() {
            _currentBannerIndex = (_currentBannerIndex + 1) % _trendingTopics.length;
          });
        }
      });
    }
  }

  void _fetchTopicImage(String topicName, DatabaseService dbService) async {
    try {
      final threads = await dbService.fetchTopicThreads(topicName);
      
      // Filter posts that actually contain image attachments
      final imagePosts = threads.where((post) => post.imageUrls != null && post.imageUrls!.isNotEmpty).toList();
      
      if (imagePosts.isNotEmpty) {
        // Sort by likesCount descending to find the most popular post with a photo
        imagePosts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        
        final bestImage = imagePosts.first.imageUrls!.first;
        if (mounted) {
          setState(() {
            _topicImages[topicName] = bestImage;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching image for topic $topicName: $e");
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
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
      final threadFuture = dbService.searchThreads(
        trimmed,
        categories: _selectedCategories,
        timeframe: _selectedTimeframe,
        sortBy: _selectedSortBy,
      );

      final results = await Future.wait([profileFuture, threadFuture]);

      if (mounted) {
        setState(() {
          _searchResults = results[0] as List<Profile>;
          _searchPostResults = results[1] as List<ThreadPost>;
          _isLoading = false;
        });
      }
    });
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

  String _getTopicImageUrl(String topic) {
    final t = topic.toLowerCase().replaceAll('#', '').trim();
    if (_topicImages.containsKey(topic)) {
      return _topicImages[topic]!;
    }
    
    // Curated Daily Life Fallback Categories (35+ categories)
    if (t.contains('phone') || t.contains('mobile') || t.contains('tech') || t.contains('smartphone') || t.contains('gadget') || t.contains('watch')) {
      return 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500&auto=format&fit=crop';
    } else if (t.contains('cricket') || t.contains('sport') || t.contains('football') || t.contains('cup') || t.contains('game') || t.contains('play') || t.contains('soccer') || t.contains('racing')) {
      return 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500&auto=format&fit=crop';
    } else if (t.contains('ev') || t.contains('car') || t.contains('tesla') || t.contains('auto') || t.contains('vehicle') || t.contains('bike') || t.contains('motorcycle') || t.contains('ride')) {
      return 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&auto=format&fit=crop';
    } else if (t.contains('food') || t.contains('cafe') || t.contains('restaurant') || t.contains('eat') || t.contains('recipe') || t.contains('coffee') || t.contains('tea') || t.contains('cook') || t.contains('kitchen')) {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&auto=format&fit=crop';
    } else if (t.contains('ai') || t.contains('robot') || t.contains('technology') || t.contains('future') || t.contains('vr') || t.contains('metaverse') || t.contains('virtual') || t.contains('science') || t.contains('lab')) {
      return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop';
    } else if (t.contains('travel') || t.contains('tour') || t.contains('nature') || t.contains('mountain') || t.contains('beach') || t.contains('trip') || t.contains('city') || t.contains('street') || t.contains('night')) {
      return 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=500&auto=format&fit=crop';
    } else if (t.contains('fashion') || t.contains('style') || t.contains('clothes') || t.contains('dress') || t.contains('outfit') || t.contains('shopping') || t.contains('mall') || t.contains('store')) {
      return 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=500&auto=format&fit=crop';
    } else if (t.contains('fitness') || t.contains('gym') || t.contains('workout') || t.contains('exercise') || t.contains('run')) {
      return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=500&auto=format&fit=crop';
    } else if (t.contains('music') || t.contains('song') || t.contains('concert') || t.contains('band') || t.contains('singer')) {
      return 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop';
    } else if (t.contains('book') || t.contains('read') || t.contains('study') || t.contains('education') || t.contains('school') || t.contains('college') || t.contains('history') || t.contains('museum')) {
      return 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=500&auto=format&fit=crop';
    } else if (t.contains('business') || t.contains('money') || t.contains('finance') || t.contains('stock') || t.contains('crypto') || t.contains('bitcoin') || t.contains('invest')) {
      return 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=500&auto=format&fit=crop';
    } else if (t.contains('health') || t.contains('medical') || t.contains('doctor') || t.contains('hospital') || t.contains('medicine')) {
      return 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=500&auto=format&fit=crop';
    } else if (t.contains('weather') || t.contains('rain') || t.contains('sun') || t.contains('cloud') || t.contains('winter') || t.contains('summer')) {
      return 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?w=500&auto=format&fit=crop';
    } else if (t.contains('photo') || t.contains('photography') || t.contains('camera') || t.contains('lens') || t.contains('art') || t.contains('drawing') || t.contains('painting') || t.contains('design')) {
      return 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=500&auto=format&fit=crop';
    } else if (t.contains('animal') || t.contains('pet') || t.contains('dog') || t.contains('cat') || t.contains('kitten') || t.contains('meow')) {
      return 'https://images.unsplash.com/photo-1477884213974-b957b95885f9?w=500&auto=format&fit=crop';
    } else if (t.contains('code') || t.contains('coding') || t.contains('programming') || t.contains('software') || t.contains('developer')) {
      return 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=500&auto=format&fit=crop';
    } else if (t.contains('movie') || t.contains('cinema') || t.contains('netflix') || t.contains('show') || t.contains('series')) {
      return 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&auto=format&fit=crop';
    } else if (t.contains('news') || t.contains('politics') || t.contains('election') || t.contains('government') || t.contains('vote')) {
      return 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=500&auto=format&fit=crop';
    } else if (t.contains('love') || t.contains('heart') || t.contains('couple') || t.contains('relationship') || t.contains('romance') || t.contains('family') || t.contains('kids') || t.contains('parents')) {
      return 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=500&auto=format&fit=crop';
    } else if (t.contains('birthday') || t.contains('gift') || t.contains('party') || t.contains('celebration') || t.contains('holiday') || t.contains('festival')) {
      return 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=500&auto=format&fit=crop';
    } else if (t.contains('dhaka') || t.contains('bangladesh') || t.contains('bengali') || t.contains('local') || t.contains('deshi')) {
      return 'https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=500&auto=format&fit=crop';
    }
    
    // Default abstract/gradient image
    return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop';
  }

  IconData _getChipIcon(String chip) {
    switch (chip) {
      case 'For you':
        return Icons.local_fire_department_rounded;
      case 'Trending':
        return Icons.trending_up_rounded;
      case 'News':
        return Icons.article_outlined;
      case 'Sports':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.tag;
    }
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryChips.length,
        itemBuilder: (context, index) {
          final chip = _categoryChips[index];
          final isSelected = _selectedCategoryChip == chip;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                _getChipIcon(chip),
                size: 15,
                color: isSelected ? Colors.white : context.textPrimary,
              ),
              label: Text(
                chip,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : context.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF1E824C), // Indigo blue matching mockup
              backgroundColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
              disabledColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  _onCategoryChipSelected(chip);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _onCategoryChipSelected(String chip) async {
    setState(() {
      _selectedCategoryChip = chip;
      _categoryPosts = [];
    });

    if (chip == 'For you') {
      return;
    }

    setState(() {
      _isCategoryLoading = true;
    });

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      List<ThreadPost> results = [];
      if (chip == 'Trending') {
        results = await dbService.searchThreads(
          '',
          sortBy: 'Popular',
        );
      } else if (chip == 'News') {
        results = await dbService.searchThreads(
          'news',
          sortBy: 'Recent',
        );
      } else if (chip == 'Sports') {
        results = await dbService.searchThreads(
          'sports',
          sortBy: 'Recent',
        );
      }
      if (mounted) {
        setState(() {
          _categoryPosts = results;
          _isCategoryLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Category fetch error: $e");
      if (mounted) {
        setState(() {
          _isCategoryLoading = false;
        });
      }
    }
  }

  Widget _buildHotBanner() {
    final hasTrending = _trendingTopics.isNotEmpty;
    final topic = hasTrending ? _trendingTopics[_currentBannerIndex % _trendingTopics.length] : null;

    final title = topic != null && topic['headline'] != null && (topic['headline'] as String).isNotEmpty
        ? topic['headline'] as String
        : (topic != null ? "#${topic['topic_name']}" : "");

    final subtitle = topic != null && topic['summary'] != null && (topic['summary'] as String).isNotEmpty
        ? topic['summary'] as String
        : "";

    final imageUrl = topic != null ? _getTopicImageUrl(topic['topic_name'] as String) : '';

    if (title.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black, // Dark background to prevent white flash during transition
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: GestureDetector(
          key: ValueKey<int>(_currentBannerIndex),
          onTap: () {
            if (topic != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TopicThreadsScreen(topicName: topic['topic_name'] as String),
                ),
              );
            }
          },
          child: Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl, maxHeight: 400),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: context.cardBg,
              border: imageUrl.isEmpty ? Border.all(color: context.border, width: 0.8) : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: imageUrl.isNotEmpty
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "HOT",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: imageUrl.isNotEmpty ? Colors.white : context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: imageUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.8) : context.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingGrid() {
    final List<Map<String, dynamic>> gridItems = [];

    // Skip first element as it is already in Hot Banner
    for (int i = 1; i < _trendingTopics.length; i++) {
      gridItems.add({
        'topic_name': _trendingTopics[i]['topic_name'] as String,
        'headline': (_trendingTopics[i]['headline'] as String?) ?? '#${_trendingTopics[i]['topic_name']}',
        'isReal': true,
      });
    }

    final displayItems = gridItems.take(4).toList();

    if (displayItems.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final topicName = item['topic_name'] as String;
        final headline = item['headline'] as String;
        final imageUrl = _getTopicImageUrl(topicName);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TopicThreadsScreen(
                  topicName: topicName,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 95,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheHeight: 200, // Optimize image memory footprint
                    memCacheWidth: 350,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName.startsWith('#') ? topicName : '#$topicName',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E824C), // Indigo color
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        headline,
                        style: GoogleFonts.inter(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhoToFollow(DatabaseService dbService) {
    final List<Profile> displayUsers = List.from(_recommended);

    if (displayUsers.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayUsers.length,
      separatorBuilder: (context, index) => Divider(height: 16, color: context.border, thickness: 0.5),
      itemBuilder: (context, index) {
        final user = displayUsers[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
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
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: context.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.fullName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          VerificationBadge(
                            isVerified: true,
                            badgeType: user.badgeType,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "@${user.username} • ${user.bio ?? 'Explore enthusiast'}",
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Selector<DatabaseService, bool>(
                selector: (_, db) => db.isFollowingUser(user.id),
                builder: (context, isFollowing, _) {
                  return isFollowing
                      ? OutlinedButton(
                          onPressed: () {
                            dbService.toggleFollowUser(user.id);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.border, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(
                            "Following",
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            dbService.toggleFollowUser(user.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E824C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(
                            "Follow",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        );
                },
              ),
            ],
          ),
        );
      },
    );
  }



  void _showFilterBottomSheet() {
    List<String> tempCategories = List.from(_selectedCategories);
    String tempTimeframe = _selectedTimeframe;
    String tempSortBy = _selectedSortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 18, color: context.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 16, color: context.primaryAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Categories",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Technology', 'Entertainment', 'Sports', 'Lifestyle', 'Travel'].map((cat) {
                      final isSelected = tempCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: isSelected ? Colors.white : context.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: const Color(0xFF1E824C),
                        backgroundColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF1E824C) : context.border,
                            width: 0.8,
                          ),
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempCategories.add(cat);
                            } else {
                              tempCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: context.primaryAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Timeframe",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Today', 'This Week', 'This Month'].map((tf) {
                      final isSelected = tempTimeframe == tf;
                      return ChoiceChip(
                        label: Text(tf),
                        selected: isSelected,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: isSelected ? const Color(0xFF1E824C) : context.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: const Color(0x1F1E824C),
                        backgroundColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF1E824C) : BorderSide.none.color,
                            width: isSelected ? 1.5 : 0,
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              tempTimeframe = tf;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 16, color: context.primaryAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Sort By",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildModalSortRow(
                          title: "Recent",
                          icon: Icons.access_time_rounded,
                          value: "Recent",
                          selectedValue: tempSortBy,
                          onChanged: (val) {
                            setModalState(() => tempSortBy = val!);
                          },
                        ),
                        Divider(height: 1, color: context.border),
                        _buildModalSortRow(
                          title: "Popular",
                          icon: Icons.trending_up_rounded,
                          value: "Popular",
                          selectedValue: tempSortBy,
                          onChanged: (val) {
                            setModalState(() => tempSortBy = val!);
                          },
                        ),
                        Divider(height: 1, color: context.border),
                        _buildModalSortRow(
                          title: "Relevance",
                          icon: Icons.tune_rounded,
                          value: "Relevance",
                          selectedValue: tempSortBy,
                          onChanged: (val) {
                            setModalState(() => tempSortBy = val!);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCategories.clear();
                            tempTimeframe = 'Today';
                            tempSortBy = 'Recent';
                          });
                        },
                        child: Text(
                          "Clear",
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters(tempCategories, tempTimeframe, tempSortBy);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E824C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Apply Filters",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSortRow({
    required String title,
    required IconData icon,
    required String value,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x1F1E824C) : (context.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: isSelected ? const Color(0xFF1E824C) : context.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: context.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E824C) : context.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E824C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters(List<String> categories, String timeframe, String sortBy) async {
    final hasActiveFilters = categories.isNotEmpty || (timeframe != 'Today' && timeframe.isNotEmpty) || (sortBy != 'Recent' && sortBy.isNotEmpty);
    
    setState(() {
      _selectedCategories = categories;
      _selectedTimeframe = timeframe;
      _selectedSortBy = sortBy;
      _filtersApplied = hasActiveFilters;
      _isFiltering = hasActiveFilters;
    });

    if (!hasActiveFilters) {
      if (mounted) {
        setState(() {
          _filteredPosts = [];
          _isFiltering = false;
        });
      }
      return;
    }

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final query = _searchController.text;

    try {
      final results = await dbService.searchThreads(
        query,
        categories: _selectedCategories,
        timeframe: _selectedTimeframe,
        sortBy: _selectedSortBy,
      );

      if (mounted) {
        setState(() {
          _filteredPosts = results;
          _isFiltering = false;
        });
      }
    } catch (e) {
      debugPrint("Apply filters error: $e");
      if (mounted) {
        setState(() {
          _isFiltering = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData iconData, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
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
              builder: (_) => ProfileScreen(userId: user.id == currentUid ? null : user.id),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                        VerificationBadge(
                          isVerified: true,
                          badgeType: user.badgeType,
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    user.fullName,
                    style: GoogleFonts.hindSiliguri(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                          ? (context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade300)
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
                    color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "($count)",
                  style: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF1E824C).withValues(alpha: 0.8) : context.textMuted,
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
              // Mockup Header Appbar
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0, bottom: 2.0),
                      child: Icon(
                        Icons.menu_rounded,
                        color: context.textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Explore",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.search,
                    color: context.textPrimary,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mockup Search Input Box
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
                      : IconButton(
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: Color(0xFF1E824C),
                            size: 24,
                          ),
                          onPressed: _showFilterBottomSheet,
                        ),
                  hintText: "Search",
                  hintStyle: GoogleFonts.inter(
                    color: context.textMuted,
                    fontSize: 14,
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mockup Filter row (Only shown when not searching)
              if (!isSearching) ...[
                _buildCategoryChips(),
                const SizedBox(height: 16),
              ],

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

              // Search History / Mockup Dashboard OR Search Results
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

                                if (_filtersApplied) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Filtered Results",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategories.clear();
                                            _selectedTimeframe = 'Today';
                                            _selectedSortBy = 'Recent';
                                            _filtersApplied = false;
                                            _filteredPosts.clear();
                                          });
                                        },
                                        child: Text(
                                          "Clear All",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF1E824C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_isFiltering)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 40.0),
                                        child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                                      ),
                                    )
                                  else if (_filteredPosts.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                                        child: Column(
                                          children: [
                                            Icon(Icons.search_off_rounded, size: 48, color: context.textMuted),
                                            const SizedBox(height: 12),
                                            Text(
                                              "No posts match the selected filters",
                                              style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _filteredPosts.length,
                                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final post = _filteredPosts[index];
                                        return CustomThreadCard(
                                          key: ValueKey(post.id),
                                          post: post,
                                        );
                                      },
                                    ),
                                ] else if (_trendingTopics.isEmpty && _recommended.isEmpty) ...[
                                  SizedBox(
                                    height: 300,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.explore_outlined, size: 48, color: context.textMuted),
                                          const SizedBox(height: 12),
                                          Text(
                                            "No trends or recommended profiles found",
                                            style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Swipe down to refresh",
                                            style: GoogleFonts.inter(color: context.textMuted.withValues(alpha: 0.7), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else if (_selectedCategoryChip != 'For you') ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$_selectedCategoryChip Feed",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_isCategoryLoading)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 40.0),
                                        child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                                      ),
                                    )
                                  else if (_categoryPosts.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                                        child: Column(
                                          children: [
                                            Icon(Icons.feed_outlined, size: 48, color: context.textMuted),
                                            const SizedBox(height: 12),
                                            Text(
                                              "No posts found in $_selectedCategoryChip",
                                              style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _categoryPosts.length,
                                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final post = _categoryPosts[index];
                                        return CustomThreadCard(
                                          key: ValueKey(post.id),
                                          post: post,
                                        );
                                      },
                                    ),
                                ] else ...[
                                  // 1- What's Happening Section
                                  if (_trendingTopics.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      "What's happening",
                                      Icons.local_fire_department_rounded,
                                      iconColor: Colors.redAccent,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildHotBanner(),
                                    const SizedBox(height: 20),
                                  ],

                                  // 2- Trending Grid Section
                                  if (_trendingTopics.length > 1) ...[
                                    _buildSectionHeader(
                                      "Trending",
                                      Icons.trending_up_rounded,
                                      iconColor: const Color(0xFF1E824C),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTrendingGrid(),
                                    const SizedBox(height: 20),
                                  ],

                                  // 3- Who to Follow Section
                                  if (_recommended.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      "Who to follow",
                                      Icons.person_add_alt_1_rounded,
                                      iconColor: const Color(0xFF1E824C),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildWhoToFollow(dbService),
                                  ],
                                ],
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
