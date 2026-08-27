import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../widgets/share_comment_sheet.dart';
import '../utils/app_theme.dart';
import 'comment_detail_screen.dart';
import 'profile/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/verification_badge.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late ScrollController _scrollController;
  bool _isCollapsed = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final collapsed = _scrollController.offset > (175 - kToolbarHeight - statusBarHeight);
        if (collapsed != _isCollapsed) {
          setState(() {
            _isCollapsed = collapsed;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchSavedPosts();
      dbService.fetchSavedComments();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refresh(DatabaseService dbService) async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      dbService.fetchSavedPosts(),
      dbService.fetchSavedComments(),
    ]);
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final savedPosts = context.select<DatabaseService, List<ThreadPost>>((db) => db.savedPosts)
        .where((p) => !dbService.isPostDeleted(p.id))
        .toList();
    final savedComments = context.select<DatabaseService, List<Map<String, dynamic>>>((db) => db.savedComments);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 175,
              pinned: true,
              floating: true,
              backgroundColor: _isCollapsed ? context.scaffoldBg : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: context.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 1.0 : 0.0,
                child: Text(
                  "Saved Items",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: context.isDarkMode
                          ? [
                              const Color(0xFF0D2E1C),
                              const Color(0xFF020E06),
                            ]
                          : [
                              const Color(0xFFE8F5E9),
                              const Color(0xFFF5F6F8),
                            ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 56, // Clears the TabBar height to avoid overlaps
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.bookmark_fill,
                                color: Color(0xFF1E824C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Saved Items',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your bookmarked posts & comments',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isRefreshing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1E824C),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48.8),
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: const Color(0xFF1E824C),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: const Color(0xFF1E824C),
                      unselectedLabelColor: context.textSecondary,
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                      tabs: const [
                        Tab(text: "Saved Posts"),
                        Tab(text: "Saved Comments"),
                      ],
                    ),
                    Container(height: 0.8, color: context.border),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildSavedPostsTab(context, dbService, savedPosts),
              _buildSavedCommentsTab(context, dbService, savedComments),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPostsTab(
      BuildContext context, DatabaseService dbService, List<ThreadPost> savedPosts) {
    if (savedPosts.isEmpty) {
      return _buildEmptyState(context, isPosts: true);
    }
    return RefreshIndicator(
      color: const Color(0xFF1E824C),
      onRefresh: () => _refresh(dbService),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: savedPosts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF1E824C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only you can see these posts',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF1E824C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final post = savedPosts[index - 1];
          return RepaintBoundary(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomThreadCard(post: post),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedCommentsTab(
      BuildContext context, DatabaseService dbService, List<Map<String, dynamic>> savedComments) {
    if (savedComments.isEmpty) {
      return _buildEmptyState(context, isPosts: false);
    }
    return RefreshIndicator(
      color: const Color(0xFF1E824C),
      onRefresh: () => _refresh(dbService),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: savedComments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1E824C).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF1E824C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only you can see these comments',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF1E824C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final comment = savedComments[index - 1];
          return RepaintBoundary(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildSavedCommentCard(context, dbService, comment),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedCommentCard(
      BuildContext context, DatabaseService dbService, Map<String, dynamic> comment) {
    final Profile author = comment['author'] as Profile;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommentDetailScreen(
                  comment: comment,
                  threadId: comment['thread_id'] ?? '',
                ),
              ),
            ).then((_) {
              dbService.fetchSavedComments();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final isOwn = author.id == (dbService.myProfile?.id ?? dbService.currentUid);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(author.avatarUrl!)
                            : null,
                        child: (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 18, color: Colors.white54)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  author.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hindSiliguri(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              if (author.isVerified) ...[
                                const SizedBox(width: 4),
                                VerificationBadge(
                                  isVerified: true,
                                  badgeType: author.badgeType,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            "@${author.username}",
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      comment['created_at'] ?? '',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment['content'] as String,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14.5,
                    color: context.textPrimary,
                    height: 1.45,
                  ),
                ),
                if (comment['image_url'] != null && (comment['image_url'] as String).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: comment['image_url'] as String,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Divider(height: 1, color: context.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: () {
                        final bool currentVal = comment['is_liked_by_me'] as bool? ?? false;
                        final bool newVal = !currentVal;
                        final int currentLikes = comment['likes_count'] as int? ?? 0;
                        
                        setState(() {
                          comment['is_liked_by_me'] = newVal;
                          comment['likes_count'] = newVal 
                              ? currentLikes + 1 
                              : (currentLikes > 0 ? currentLikes - 1 : 0);
                        });
                        dbService.toggleCommentLike(comment['id'] as String, newVal);
                      },
                      child: Row(
                        children: [
                          Icon(
                            (comment['is_liked_by_me'] as bool? ?? false)
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            size: 15,
                            color: (comment['is_liked_by_me'] as bool? ?? false)
                                ? Colors.red
                                : context.textPrimary.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['likes_count'] ?? 0}",
                            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Replies Count
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentDetailScreen(
                              comment: comment,
                              threadId: comment['thread_id'] ?? '',
                            ),
                          ),
                        ).then((_) {
                          dbService.fetchSavedComments();
                        });
                      },
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.chat_bubble, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['replies_count'] ?? 0}",
                            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Saved Button
                    GestureDetector(
                      onTap: () async {
                        final bool currentSaved = comment['is_saved_by_me'] as bool? ?? false;
                        final bool newSaved = !currentSaved;
                        final int currentSaves = comment['saves_count'] as int? ?? 0;

                        setState(() {
                          comment['is_saved_by_me'] = newSaved;
                          comment['saves_count'] = newSaved 
                              ? currentSaves + 1 
                              : (currentSaves > 0 ? currentSaves - 1 : 0);
                        });
                        dbService.toggleSaveComment(comment['id'] as String);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newSaved ? "Comment saved to bookmarks" : "Comment removed from bookmarks"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            (comment['is_saved_by_me'] as bool? ?? false)
                                ? CupertinoIcons.bookmark_fill
                                : CupertinoIcons.bookmark,
                            size: 15,
                            color: (comment['is_saved_by_me'] as bool? ?? false)
                                ? const Color(0xFF1E824C)
                                : context.textPrimary.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['saves_count'] ?? 0}",
                            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Share Button
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetCtx) => ShareCommentSheet(comment: comment),
                        ).then((_) {
                          dbService.fetchSavedComments();
                        });
                      },
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.arrowshape_turn_up_right, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['shares_count'] ?? 0}",
                            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isPosts}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E824C).withValues(alpha: 0.08),
                  const Color(0xFF1E824C).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bookmark,
              size: 48,
              color: Color(0xFF1E824C),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPosts ? 'No saved posts' : 'No saved comments',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isPosts
                  ? 'Tap the bookmark icon on posts you want to read later.'
                  : 'Tap the bookmark icon on comments you want to read later.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E824C).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.bookmark,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back to Feed',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
