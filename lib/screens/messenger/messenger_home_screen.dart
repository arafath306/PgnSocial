import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';
import 'chat_settings_screen.dart';
import 'member_search_sheet.dart';
import '../../widgets/chat_shimmer.dart';
import '../../utils/chat_themes.dart';
import 'widgets/user_actions_sheet.dart';
import 'widgets/active_friends_tray.dart';
import 'widgets/chat_filter_chips.dart';
import '../../services/general_settings_provider.dart';
import '../../widgets/verification_badge.dart';

class MessengerHomeScreen extends StatefulWidget {
  const MessengerHomeScreen({super.key});

  @override
  State<MessengerHomeScreen> createState() => _MessengerHomeScreenState();
}

class _MessengerHomeScreenState extends State<MessengerHomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static final Map<String, List<Map<String, dynamic>>> _globalChatsCache = {};
  
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ChatFilter _selectedFilter = ChatFilter.all;
  Set<String> _pinnedChatIds = {};
  final Map<String, bool> _typingUsers = {};
  final Map<String, Timer> _typingTimers = {};

  @override
  void initState() {
    super.initState();
    _loadPinnedChats();

    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId != null && _globalChatsCache.containsKey(myId)) {
      _chats = _globalChatsCache[myId]!;
      _isLoading = false;
      _loadChats(silent: true);
    } else {
      _loadChats();
    }
    
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    _notifSub = dbService.incomingNotificationStream.listen((event) {
      final eventType = event['type'] as String?;
      if (eventType == 'typing') {
        final senderId = event['sender_id'] as String?;
        final isTyping = event['is_typing'] == true;
        if (senderId != null) {
          setState(() {
            _typingUsers[senderId] = isTyping;
          });
          _typingTimers[senderId]?.cancel();
          if (isTyping) {
            _typingTimers[senderId] = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _typingUsers[senderId] = false);
            });
          }
        }
      } else if (eventType == 'message') {
        if (event['profile'] != null) {
          final senderId = event['sender_id'];
          final profile = event['profile'] as Profile;
          final body = event['body'] as String;
          final createdAtRaw = event['created_at'];
          final createdAt = createdAtRaw != null 
              ? (DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()) 
              : DateTime.now();

          setState(() {
            final existingIndex = _chats.indexWhere((chat) => (chat['profile'] as Profile).id == senderId);
            final activeId = dbService.currentActiveChatUserId?.trim().toLowerCase();
            final bool isCurrentlyInChat = activeId != null &&
                activeId.isNotEmpty &&
                senderId != null &&
                senderId.toString().trim().toLowerCase() == activeId;
            
            if (existingIndex >= 0) {
              final chat = _chats.removeAt(existingIndex);
              chat['last_message'] = body;
              chat['last_message_time'] = 'Just now';
              chat['timestamp'] = createdAt;
              chat['is_me'] = false;
              if (!isCurrentlyInChat) {
                chat['unread_count'] = (chat['unread_count'] as int? ?? 0) + 1;
              } else {
                chat['unread_count'] = 0;
              }
              _chats.insert(0, chat);
            } else {
              _chats.insert(0, {
                'profile': profile,
                'last_message': body,
                'last_message_time': 'Just now',
                'unread_count': isCurrentlyInChat ? 0 : 1,
                'timestamp': createdAt,
                'is_me': false,
                'is_read': false,
                'latest_message_id': '',
              });
            }
          });
        }
        _loadChats(silent: true);
      }
    });
  }

  Future<void> _loadPinnedChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('messenger_pinned_chat_ids') ?? [];
      if (mounted) {
        setState(() {
          _pinnedChatIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _togglePinChat(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (_pinnedChatIds.contains(userId)) {
          _pinnedChatIds.remove(userId);
        } else {
          _pinnedChatIds.add(userId);
        }
      });
      await prefs.setStringList('messenger_pinned_chat_ids', _pinnedChatIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pinnedChatIds.contains(userId)
                  ? 'Conversation pinned to top'
                  : 'Conversation unpinned',
              style: GoogleFonts.inter(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _searchController.dispose();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  String _formatLastMessagePreview(String rawMsg) {
    if (rawMsg.isEmpty) return '';
    final trimmed = rawMsg.trim();

    if (trimmed.startsWith('custom:')) {
      return '🎨 Changed custom theme';
    }

    if (allChatThemes.any((t) => t.id == trimmed)) {
      final theme = getChatThemeById(trimmed);
      return '🎨 Changed theme to ${theme.name}';
    }

    if (trimmed == 'none') {
      return '🖼️ Removed chat wallpaper';
    }

    return rawMsg;
  }

  Future<void> _loadChats({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final chats = await dbService.fetchActiveChats();
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId != null) {
      _globalChatsCache[myId] = chats;
    }
    if (mounted) {
      setState(() {
        _chats = chats;
        if (!silent) _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadChats();
  }

  Future<void> _openChat(Profile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(otherUser: profile)),
    );
    _loadChats(silent: _chats.isNotEmpty);
  }

  void _showUserActions(BuildContext ctx, Profile profile, int chatIndex) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return UserActionsSheet(
          profile: profile,
          isPinned: _pinnedChatIds.contains(profile.id),
          onTogglePin: () => _togglePinChat(profile.id),
          onChatRemoved: () {
            setState(() {
              _chats.removeWhere((c) => (c['profile'] as Profile).id == profile.id);
              final myId = Supabase.instance.client.auth.currentUser?.id;
              if (myId != null) _globalChatsCache[myId] = _chats;
            });
          },
        );
      },
    );
  }

  List<Profile> get _activeFriends {
    return _chats
        .map((c) => c['profile'] as Profile)
        .where((p) =>
            p.isActiveStatusEnabled &&
            p.lastSeen != null &&
            DateTime.now().difference(p.lastSeen!).inMinutes <= 5)
        .toList();
  }

  List<Map<String, dynamic>> get _displayChats {
    List<Map<String, dynamic>> list = List.from(_chats);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((chat) {
        final profile = chat['profile'] as Profile;
        final lastMsg = (chat['last_message'] as String? ?? '').toLowerCase();
        final name = profile.fullName.toLowerCase();
        final username = profile.username.toLowerCase();
        return name.contains(_searchQuery) ||
            username.contains(_searchQuery) ||
            lastMsg.contains(_searchQuery);
      }).toList();
    }

    // Filter by chip
    if (_selectedFilter == ChatFilter.unread) {
      list = list.where((chat) => (chat['unread_count'] as int? ?? 0) > 0).toList();
    } else if (_selectedFilter == ChatFilter.pinned) {
      list = list.where((chat) => _pinnedChatIds.contains((chat['profile'] as Profile).id)).toList();
    }

    // Sort: pinned first, then by timestamp descending
    list.sort((a, b) {
      final aId = (a['profile'] as Profile).id;
      final bId = (b['profile'] as Profile).id;
      final aPinned = _pinnedChatIds.contains(aId);
      final bPinned = _pinnedChatIds.contains(bId);

      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      final aTime = a['timestamp'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b['timestamp'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDarkMode;
    final mySettings = Provider.of<GeneralSettingsProvider>(context, listen: false);
    final bool myActiveStatusEnabled = mySettings.isActiveStatusEnabled;
    final displayList = _displayChats;
    final unreadTotal = _chats.where((c) => (c['unread_count'] as int? ?? 0) > 0).length;
    final pinnedTotal = _chats.where((c) => _pinnedChatIds.contains((c['profile'] as Profile).id)).length;
    final activeFriendsList = _activeFriends;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: context.textPrimary, size: 24),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        titleSpacing: 0,
        title: Text(
          'Chats',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textPrimary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatSettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: RefreshIndicator(
        color: context.primaryAccent,
        onRefresh: _handleRefresh,
        child: _isLoading
            ? const ChatShimmer()
            : Column(
                children: [
                  // 1. Search Bar
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: context.textMuted),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: context.textMuted,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),

                  // 2. Active Friends Tray (Only shown when not searching)
                  if (_searchQuery.isEmpty && myActiveStatusEnabled && activeFriendsList.isNotEmpty)
                    ActiveFriendsTray(
                      activeUsers: activeFriendsList,
                      onUserTap: _openChat,
                    ),

                  // 3. Filter Chips
                  ChatFilterChips(
                    selectedFilter: _selectedFilter,
                    unreadCount: unreadTotal,
                    pinnedCount: pinnedTotal,
                    onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
                  ),

                  // 4. Conversation List
                  Expanded(
                    child: displayList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.45,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_searchQuery.isNotEmpty || _selectedFilter != ChatFilter.all) ...[
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 48,
                                          color: context.textMuted,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No conversations found',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Try another filter or search term',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ] else ...[
                                        CustomPaint(
                                          size: const Size(60, 60),
                                          painter: SpeechBubblePainter(color: context.textPrimary),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Say hi to someone',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const MemberSearchSheet()),
                                            );
                                            _loadChats(silent: _chats.isNotEmpty);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context.primaryAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            elevation: 0,
                                            minimumSize: Size.zero,
                                          ),
                                          icon: const Icon(Icons.add_comment_rounded, size: 15),
                                          label: Text(
                                            'New chat',
                                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: displayList.length,
                            addRepaintBoundaries: true,
                            addAutomaticKeepAlives: false,
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 72),
                            separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                            itemBuilder: (context, index) {
                              final chat = displayList[index];
                              final Profile profile = chat['profile'] as Profile;
                              final String lastMsg = chat['last_message'] as String? ?? '';
                              final String time = chat['last_message_time'] as String? ?? '';
                              final int unreadCount = chat['unread_count'] as int? ?? 0;
                              final bool isMe = chat['is_me'] == true;
                              final bool isRead = chat['is_read'] == true;
                              final bool isPinned = _pinnedChatIds.contains(profile.id);
                              final bool isTyping = _typingUsers[profile.id] == true;

                              final bool otherIsActive = profile.isActiveStatusEnabled &&
                                  profile.lastSeen != null &&
                                  DateTime.now().difference(profile.lastSeen!).inMinutes <= 5;
                              final bool showGreenDot = myActiveStatusEnabled && otherIsActive;

                              return RepaintBoundary(
                                child: ListTile(
                                  tileColor: isPinned
                                      ? (isDark ? const Color(0xFF161B22).withValues(alpha: 0.4) : const Color(0xFFF9FAFB))
                                      : Colors.transparent,
                                  onTap: () => _openChat(profile),
                                  onLongPress: () => _showUserActions(context, profile, index),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: context.border,
                                        backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                            ? CachedNetworkImageProvider(profile.avatarUrl!)
                                            : null,
                                        child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                                            ? Icon(Icons.person, size: 22, color: context.textMuted)
                                            : null,
                                      ),
                                      if (showGreenDot)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: context.scaffoldBg, width: 2.5),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                profile.fullName,
                                                style: GoogleFonts.notoSansBengali(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: context.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (profile.isVerified) ...[
                                              const SizedBox(width: 4),
                                              VerificationBadge(
                                                isVerified: true,
                                                badgeType: profile.badgeType,
                                                size: 15,
                                              ),
                                            ],
                                            if (isPinned) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.push_pin_rounded,
                                                size: 13,
                                                color: Color(0xFF10B981),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(
                                        time,
                                        style: GoogleFonts.inter(
                                          color: unreadCount > 0 ? context.primaryAccent : context.textMuted,
                                          fontSize: 12,
                                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: isTyping
                                              ? Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.edit_note_rounded,
                                                      size: 16,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'typing...',
                                                      style: GoogleFonts.inter(
                                                        color: const Color(0xFF10B981),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isMe) ...[
                                                      Icon(
                                                        isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                                        size: 14,
                                                        color: isRead
                                                            ? const Color(0xFF10B981)
                                                            : context.textMuted,
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Flexible(
                                                      child: Text(
                                                        _formatLastMessagePreview(lastMsg),
                                                        style: GoogleFonts.notoSansBengali(
                                                          color: unreadCount > 0 ? context.textPrimary : context.textSecondary,
                                                          fontSize: 13.5,
                                                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                        if (unreadCount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "$unreadCount",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.small(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberSearchSheet()),
            );
            _loadChats(silent: _chats.isNotEmpty);
          },
          backgroundColor: const Color(0xFF1E824C),
          shape: const CircleBorder(),
          elevation: 3,
          child: const Icon(Icons.add, color: Colors.white, size: 23),
        ),
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;
  SpeechBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.9);
    
    // Draw bubble
    path.addArc(rect, 0.75 * 3.14159, 1.75 * 3.14159);
    // Draw bubble tail
    path.lineTo(size.width * 0.15, size.height * 1.0);
    path.lineTo(size.width * 0.32, size.height * 0.85);
    path.close();
    canvas.drawPath(path, paint);
    
    // Draw eyes
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.45), 2.5, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.45), 2.5, eyePaint);
    
    // Draw smile
    final smilePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    final smilePath = Path();
    smilePath.moveTo(size.width * 0.43, size.height * 0.56);
    smilePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.66,
      size.width * 0.57,
      size.height * 0.56,
    );
    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
