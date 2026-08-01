import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/music_track.dart';
import '../services/music_service.dart';
import '../state/music_playback_controller.dart';
import 'music_player_bar.dart';

class MusicSearchSheet extends StatefulWidget {
  const MusicSearchSheet({super.key});

  @override
  State<MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<MusicSearchSheet> {
  final _searchController = TextEditingController();
  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  // Facebook-standard English category options
  final List<Map<String, String>> _categories = [
    {"label": "🔥 Bangla Hits", "query": "Bangla Hits"},
    {"label": "🎸 Bangla Band", "query": "Bangla Band"},
    {"label": "❤️ Romantic", "query": "Bangla Romantic"},
    {"label": "🎉 Party Hits", "query": "Bangla Party"},
    {"label": "🌍 Global Hits", "query": "Top Hits"},
  ];

  String _selectedCategoryQuery = "Bangla Hits";

  @override
  void initState() {
    super.initState();
    // Default search on load to show Bangla Hits first
    _search(_selectedCategoryQuery);
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _tracks = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    MusicService.searchMusic(query).then((results) {
      if (mounted) {
        setState(() {
          _tracks = results;
          _isLoading = false;
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  void _onCategorySelected(String label, String query) {
    setState(() {
      _selectedCategoryQuery = query;
      _searchController.clear();
    });
    _search(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackController = Provider.of<MusicPlaybackController>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title Header
          Text(
            "Select Music",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 14),

          // Search input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Search songs, artists...",
                hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _search(_selectedCategoryQuery);
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Facebook-Standard Horizontal Category Chips Bar
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryQuery == cat["query"] && _searchController.text.isEmpty;

                return GestureDetector(
                  onTap: () => _onCategorySelected(cat["label"]!, cat["query"]!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1D9BF0)
                          : (isDark ? const Color(0xFF1E2030) : const Color(0xFFF0F2F5)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1D9BF0)
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat["label"]!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Tracks List / Loading / Empty State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D9BF0)),
                    ),
                  )
                : _tracks.isEmpty
                    ? Center(
                        child: Text(
                          "No music found",
                          style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tracks.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          final isCurrent = playbackController.currentTrackId == track.trackId;
                          final isPlaying = isCurrent && playbackController.isPlaying;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? (isDark ? const Color(0xFF1E2540) : const Color(0xFFF0F4FF))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              onTap: () {
                                // Stop playback and return selected track
                                playbackController.stop();
                                Navigator.pop(context, track);
                              },
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  RotatingAlbumArt(
                                    imageUrl: track.artworkUrl,
                                    isPlaying: isPlaying,
                                    size: 44,
                                  ),
                                  // Play icon overlay
                                  GestureDetector(
                                    onTap: () {
                                      playbackController.play(track.trackId, track.previewUrl);
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                track.trackName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                track.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              trailing: Icon(
                                Icons.add_circle_outline_rounded,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Mini Player Bar if something is currently playing inside search sheet
          if (playbackController.currentTrackId != null && _tracks.any((t) => t.trackId == playbackController.currentTrackId))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: MusicPlayerBar(
                musicTrack: _tracks.firstWhere((t) => t.trackId == playbackController.currentTrackId),
                miniMode: true,
              ),
            ),
        ],
      ),
    );
  }
}
