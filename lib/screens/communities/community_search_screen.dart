import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/community_service.dart';
import '../../utils/app_theme.dart';
import '../../models/community.dart';
import 'community_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  Timer? _debounce;
  String _query = '';
  List<Community> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchBar = false; // Toggles between search textfield and standard Discover Title



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<CommunityService>(context, listen: false);
      service.loadRecentSearches();
      if (service.recommendedCommunities.isEmpty) {
        service.fetchRecommendedCommunities();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query.trim());
    if (_query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final service = Provider.of<CommunityService>(context, listen: false);
    final results = await service.searchCommunities(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }
  
  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    final service = Provider.of<CommunityService>(context, listen: false);
    service.addRecentSearch(query.trim());
    _focusNode.unfocus();
    _searchController.text = query;
    _onSearchChanged(query);
  }



  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}m members';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k members';
    }
    return '$count members';
  }

  Widget _buildCommunityAvatar(Community community, double size) {
    if (community.avatarUrl != null && community.avatarUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(size * 0.3),
          image: DecorationImage(
            image: CachedNetworkImageProvider(community.avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
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
  }

  Widget _buildCommunityCard(Community community) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: community)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildCommunityAvatar(community, 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          community.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary),
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
                  const SizedBox(height: 2),
                  Text(
                    _formatMemberCount(community.memberCount),
                    style: GoogleFonts.inter(color: context.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Search / Title Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: context.textPrimary),
                    onPressed: () {
                      if (_showSearchBar) {
                        setState(() {
                          _showSearchBar = false;
                          _searchController.clear();
                          _query = '';
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Expanded(
                    child: _showSearchBar
                        ? Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: context.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Icon(CupertinoIcons.search, color: context.textMuted, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    style: GoogleFonts.inter(color: context.textPrimary, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: "Search communities...",
                                      hintStyle: GoogleFonts.inter(color: context.textMuted),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: _onSearchChanged,
                                    onSubmitted: _submitSearch,
                                  ),
                                ),
                                if (_query.isNotEmpty)
                                  IconButton(
                                    icon: Icon(CupertinoIcons.clear_thick_circled, color: context.textMuted, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      _focusNode.requestFocus();
                                    },
                                  ),
                              ],
                            ),
                          )
                        : Text(
                            "Discover communities",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                  ),
                  if (!_showSearchBar)
                    IconButton(
                      icon: Icon(CupertinoIcons.search, color: context.textPrimary),
                      onPressed: () {
                        setState(() {
                          _showSearchBar = true;
                        });
                      },
                    ),
                ],
              ),
            ),
            
            Divider(height: 1, thickness: 1, color: context.border),

            // Body
            Expanded(
              child: Consumer<CommunityService>(
                builder: (context, service, _) {
                  if (_query.isNotEmpty) {
                    // Show search results
                    if (_isSearching) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (_searchResults.isEmpty) {
                      return Center(
                        child: Text(
                          "No communities found for '$_query'",
                          style: GoogleFonts.inter(color: context.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 40),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: context.border),
                      itemBuilder: (context, index) {
                        return _buildCommunityCard(_searchResults[index]);
                      },
                    );
                  }

                  if (_showSearchBar && _query.isEmpty) {
                    // Show recent searches state when in search mode but query is empty
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      physics: const ClampingScrollPhysics(),
                      children: [
                        if (service.recentSearches.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recent Searches",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                              ),
                              TextButton(
                                onPressed: service.clearRecentSearches,
                                child: Text(
                                  "Clear All",
                                  style: GoogleFonts.inter(fontSize: 14, color: context.greenAccent, fontWeight: FontWeight.w600),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: service.recentSearches.map((term) {
                              return GestureDetector(
                                onTap: () => _submitSearch(term),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.time, size: 14, color: context.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        term,
                                        style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ] else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                "Type to search communities",
                                style: GoogleFonts.inter(color: context.textSecondary),
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  // Discover Main Page (Matches the screenshot layout - dynamically grouped by topic)
                  final Map<String, List<Community>> grouped = {};
                  for (final community in service.recommendedCommunities) {
                    final topic = community.topic ?? "General";
                    grouped.putIfAbsent(topic, () => []).add(community);
                  }

                  if (grouped.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          "No communities found",
                          style: GoogleFonts.inter(color: context.textSecondary),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    physics: const ClampingScrollPhysics(),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, sectionIndex) {
                      final topic = grouped.keys.elementAt(sectionIndex);
                      final communities = grouped[topic]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Topic Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        context.primaryAccent,
                                        context.primaryAccent.withValues(alpha: 0.5),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  topic,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                Icon(CupertinoIcons.chevron_right, size: 14, color: context.textMuted),
                              ],
                            ),
                          ),

                          // List of communities under this topic
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: communities.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: context.border,
                            ),
                            itemBuilder: (context, index) {
                              final community = communities[index];
                              final bool isJoined = community.myRole != null;

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: community)),
                                  ).then((_) {
                                    service.fetchJoinedCommunities();
                                    service.fetchRecommendedCommunities();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      _buildCommunityAvatar(community, 44),
                                      const SizedBox(width: 12),

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
                                                      fontSize: 14.5,
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
                                            const SizedBox(height: 2),
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
                                                if (community.description != null && community.description!.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  const Text("·", style: TextStyle(color: Colors.grey)),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      community.description!,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        color: context.textMuted,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
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
                          const SizedBox(height: 10),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.border,
                          ),
                        ],
                      );
                    },
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
