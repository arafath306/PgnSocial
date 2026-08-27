import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';
import 'chat_settings_screen.dart';
import 'member_search_sheet.dart';
import '../../widgets/chat_shimmer.dart';

import 'widgets/user_actions_sheet.dart';
import '../../services/general_settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  void initState() {
    super.initState();
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
      if (event['type'] == 'message') {
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
            
            final bool isCurrentlyInChat = dbService.currentActiveChatUserId == senderId;
            
            if (existingIndex >= 0) {
              final chat = _chats.removeAt(existingIndex);
              chat['last_message'] = body;
              chat['last_message_time'] = createdAt;
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
                'last_message_time': createdAt,
                'unread_count': isCurrentlyInChat ? 0 : 1,
                'latest_message_id': '',
              });
            }
          });
        }
        _loadChats(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
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

  void _showUserActions(BuildContext ctx, Profile profile, int chatIndex) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return UserActionsSheet(
          profile: profile,
          onChatRemoved: () {
            setState(() {
              _chats.removeAt(chatIndex);
              final myId = Supabase.instance.client.auth.currentUser?.id;
              if (myId != null) _globalChatsCache[myId] = _chats;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mySettings = Provider.of<GeneralSettingsProvider>(context, listen: false);
    final bool myActiveStatusEnabled = mySettings.isActiveStatusEnabled;

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
            icon: Icon(Icons.mail_outline_rounded, color: context.textPrimary, size: 22),
            onPressed: () {},
          ),
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
            : _chats.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MemberSearchSheet()),
                                ),
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
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _chats.length,
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 72),
                    separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final Profile profile = chat['profile'] as Profile;
                      final String lastMsg = chat['last_message'] as String;
                      final String time = chat['last_message_time'] as String;
                      final int unreadCount = chat['unread_count'] as int;

                      final bool otherIsActive = profile.isActiveStatusEnabled &&
                          profile.lastSeen != null &&
                          DateTime.now().difference(profile.lastSeen!).inMinutes <= 5;
                      final bool showGreenDot = myActiveStatusEnabled && otherIsActive;

                      return RepaintBoundary(
                        child: ListTile(
                        tileColor: Colors.transparent,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ChatScreen(otherUser: profile)),
                          );
                          _loadChats(silent: _chats.isNotEmpty);
                        },
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
                                    color: Colors.green,
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
                                      style: GoogleFonts.hindSiliguri(
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
                                child: Text(
                                  lastMsg,
                                  style: GoogleFonts.hindSiliguri(
                                    color: unreadCount > 0 ? context.textPrimary : context.textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text(
                                    "$unreadCount",
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),);
                    },
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
            // Refresh chat list after new chat is started
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
