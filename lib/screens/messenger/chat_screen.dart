import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/chat_themes.dart';
import '../../utils/media_saver_utility.dart';

import 'widgets/message_list.dart';
import 'widgets/chat_composer.dart';
import 'widgets/blocked_banner.dart';
import 'widgets/full_screen_media_viewer.dart';
import 'widgets/messenger_profile_sheet.dart';
import 'widgets/reaction_bar.dart';
import 'media_preview_screen.dart';
import '../../widgets/theme_picker_sheet.dart';
import '../../widgets/verification_badge.dart';
part 'chat_screen_extensions.dart';


// â”€â”€â”€ ChatScreen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ChatScreen extends StatefulWidget {
  final Profile otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  late Stream<List<Map<String, dynamic>>> _messagesStream;
  List<Map<String, dynamic>> _allMessages = [];
  late Profile _realtimeOtherUser;

  // Optimistic pending messages
  final List<Map<String, dynamic>> _pendingMessages = [];

  // Optimistically deleted IDs â€“ hide them immediately before stream updates
  final Set<String> _deletedIds = {};

  // Static caches to prevent UI flashing while messages stream loads
  static final Map<String, String> _themeCache = {};
  static final Map<String, String> _wallpaperCache = {};

  Timer? _statusUpdateTimer;
  bool _isMuted = false;

  // â”€â”€ These are only managed at the top level (not inline in build) â”€â”€
  Map<String, dynamic>? _replyingToMessage;
  bool _showEmojiPanel = false;
  int _pickerTabIndex = 0;
  String? _currentThemeId;
  String? _customWallpaperUrl;

  StreamSubscription<Map<String, dynamic>>? _typingSub;
  bool _otherIsTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _currentThemeId = _themeCache[widget.otherUser.id];
    _customWallpaperUrl = _wallpaperCache[widget.otherUser.id];
    
    _realtimeOtherUser = widget.otherUser;
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.currentActiveChatUserId = widget.otherUser.id;
    _messagesStream = dbService.getMessagesStream(widget.otherUser.id);

    // Mark read once on enter, not on every rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dbService.markMessagesAsRead(widget.otherUser.id);
    });

    _loadMuteStatus();

    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshOtherUserStatus();
    });

    _typingSub = dbService.getTypingStream(widget.otherUser.id).listen((event) {
      if (!mounted) return;
      final userId = event['user_id'];
      final isTyping = event['is_typing'] == true;
      if (userId == widget.otherUser.id) {
        setState(() => _otherIsTyping = isTyping);
        _typingTimer?.cancel();
        if (isTyping) {
          _typingTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _otherIsTyping = false);
          });
        }
      }
    });
  }

  Future<void> _refreshOtherUserStatus() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final updatedProfile = await dbService.fetchProfile(widget.otherUser.id);
      if (updatedProfile != null && mounted) {
        setState(() => _realtimeOtherUser = updatedProfile);
      }
    } catch (e) {
      debugPrint('Error updating other user status: $e');
    }
  }

  Future<void> _loadMuteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMuted = prefs.getBool('mute_chat_${widget.otherUser.id}') ?? false;
      });
    }
  }

  Future<void> _toggleMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mute_chat_${widget.otherUser.id}', value);
    setState(() => _isMuted = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value ? 'Chat muted' : 'Chat unmuted',
            style: GoogleFonts.inter()),
        backgroundColor: context.primaryAccent,
      ));
    }
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemePickerSheet(
        currentThemeId: _currentThemeId ?? 'default',
        onThemeSelected: (themeId) {
          _sendThemeChangeMessage(themeId);
        },
        onCustomWallpaperSelected: (image) {
          _uploadAndSetCustomWallpaper(image);
        },
        onRemoveWallpaper: () {
          _removeCustomWallpaper();
        },
      ),
    );
  }

  void _sendThemeChangeMessage(String themeId) {
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'text': themeId,
      'isMe': true,
      'time': _formatToDhaka12Hr(DateTime.now()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'media_type': 'theme_change',
      'is_read': false,
      'is_sending': true,
    };

    setState(() => _pendingMessages.add(tempMsg));
    _scrollToBottom();

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.sendMessage(widget.otherUser.id, themeId, mediaType: 'theme_change').then((_) {
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
        });
      }
    });
  }

  void _sendWallpaperChangeMessage(String url) {
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'text': '',
      'media_url': url,
      'isMe': true,
      'time': _formatToDhaka12Hr(DateTime.now()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'media_type': 'wallpaper_change',
      'is_read': false,
      'is_sending': true,
    };

    setState(() => _pendingMessages.add(tempMsg));
    _scrollToBottom();

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.sendMessage(widget.otherUser.id, '', mediaUrl: url, mediaType: 'wallpaper_change').then((_) {
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
        });
      }
    });
  }

  void _uploadAndSetCustomWallpaper(XFile image) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading wallpaper...')));
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final bytes = await image.readAsBytes();
    final url = await dbService.uploadChatMedia(bytes, extension: 'jpg', contentType: 'image/jpeg');
    if (url != null) {
      _sendWallpaperChangeMessage(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload wallpaper')));
      }
    }
  }

  void _removeCustomWallpaper() {
    _sendWallpaperChangeMessage('none');
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _statusUpdateTimer?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.currentActiveChatUserId = null;
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────────────────────
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
  }



  // â”€â”€â”€ Send text message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€ Send media message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // ─────────────────── Send camera message ──────────────────────────────

  // â”€â”€â”€ Send GIF â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



  // â”€â”€â”€ Edit message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€ Delete message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€ Message action menu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _downloadMedia(String url) async {
    await MediaSaverUtility.saveToGallery(context, url);
  }

  void _openFullScreenMedia(String mediaUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FullScreenMediaViewer(mediaUrl: mediaUrl)),
    );
  }

  // â”€â”€â”€ Confirm block/delete conversation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


  // ——————————————————————————————————————————————————————————————————————————

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _formatToDhaka12Hr(DateTime dt) {
    final dhakaTime = dt.toUtc().add(const Duration(hours: 6));
    final hour24 = dhakaTime.hour;
    final minute = dhakaTime.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12:$minute $period';
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    // Only watch GeneralSettingsProvider (not DatabaseService) to prevent
    // full rebuilds on unrelated database notifyListeners() calls.
    final settings =
        Provider.of<GeneralSettingsProvider>(context, listen: true);
    final myActiveStatusEnabled = settings.isActiveStatusEnabled;

    final activeTheme = getChatThemeById(_currentThemeId);

    Color? bgColor = context.scaffoldBg;
    Gradient? bgGradient;

    if (_currentThemeId != null && _currentThemeId != 'default') {
      if (!_currentThemeId!.startsWith('custom:')) {
        if (activeTheme.gradientColors != null) {
          bgGradient = LinearGradient(
            colors: activeTheme.gradientColors!
                .map((c) => c.withValues(alpha: context.isDarkMode ? 0.15 : 0.08))
                .toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          bgColor = null;
        } else {
          bgColor = activeTheme.primaryColor
              .withValues(alpha: context.isDarkMode ? 0.1 : 0.05);
        }
      }
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    final db = Provider.of<DatabaseService>(context, listen: false);
    final bool isBlocked = context.select<DatabaseService, bool>(
        (db) => db.blockedUserIds.contains(widget.otherUser.id));
    final bool blockedByMe = context.select<DatabaseService, bool>(
        (db) => db.blockedByMeIds.contains(widget.otherUser.id));

    final bool otherIsActive = _realtimeOtherUser.isActiveStatusEnabled &&
        _realtimeOtherUser.lastSeen != null &&
        DateTime.now().difference(_realtimeOtherUser.lastSeen!).inMinutes <= 5;

    final bool showGreenDot = myActiveStatusEnabled && otherIsActive;

    String statusText = 'Offline';
    if (_realtimeOtherUser.isActiveStatusEnabled) {
      if (otherIsActive) {
        statusText = 'Active now';
      } else if (_realtimeOtherUser.lastSeen != null) {
        final diff = DateTime.now().difference(_realtimeOtherUser.lastSeen!);
        if (diff.inMinutes < 60) {
          statusText = 'Active ${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          statusText = 'Active ${diff.inHours}h ago';
        } else {
          statusText = 'Active ${diff.inDays}d ago';
        }
      }
    }

    if (_otherIsTyping) {
      statusText = 'Typing...';
    }

    Widget mainContent = Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: _showMessengerProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: context.border,
                      backgroundImage:
                          _realtimeOtherUser.avatarUrl != null &&
                                  _realtimeOtherUser.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(_realtimeOtherUser.avatarUrl!)
                              : null,
                    ),
                    if (showGreenDot)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: context.scaffoldBg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _realtimeOtherUser.fullName,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_realtimeOtherUser.isVerified) ...[
                            const SizedBox(width: 4),
                            VerificationBadge(
                              isVerified: true,
                              badgeType: _realtimeOtherUser.badgeType,
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: (_otherIsTyping || otherIsActive)
                              ? Colors.green
                              : context.textMuted,
                          fontWeight: (_otherIsTyping || otherIsActive)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outlined,
                color: context.textPrimary, size: 20),
            onPressed: _showMessengerProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: bgColor,
          gradient: bgGradient,
          image: _customWallpaperUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(_customWallpaperUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: context.isDarkMode ? 0.5 : 0.1),
                  BlendMode.darken,
                ),
              )
            : (_currentThemeId != null && _currentThemeId!.startsWith('custom:') 
              ? DecorationImage(
                  image: CachedNetworkImageProvider(_currentThemeId!.substring(7)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: context.isDarkMode ? 0.5 : 0.1),
                    BlendMode.darken,
                  ),
                )
              : null),
        ),
        child: Column(
          children: [
          // â”€â”€ Message list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: MessageList(
              stream: _messagesStream,
              activeTheme: activeTheme,
              pendingMessages: _pendingMessages,
              deletedIds: _deletedIds,
              scrollController: _scrollController,
              onAllMessagesUpdated: (msgs) {
                _allMessages = msgs;
                String? newThemeId;
                String? newWallpaperUrl;
                
                for (final msg in msgs.reversed) {
                  if (msg['media_type'] == 'theme_change') {
                    final text = msg['text']?.toString() ?? '';
                    if (newThemeId == null && !text.startsWith('custom:')) {
                      newThemeId = text;
                    }
                    if (newWallpaperUrl == null && text.startsWith('custom:')) {
                      newWallpaperUrl = text.substring(7);
                    }
                  } else if (msg['media_type'] == 'wallpaper_change') {
                    if (newWallpaperUrl == null) {
                      final url = msg['media_url']?.toString() ?? '';
                      if (url == 'none') {
                        newWallpaperUrl = ''; // Indicates removed
                      } else {
                        newWallpaperUrl = url;
                      }
                    }
                  }
                  
                  if (newThemeId != null && newWallpaperUrl != null) break;
                }
                
                if (newWallpaperUrl == '') newWallpaperUrl = null;
                
                if (newThemeId != _currentThemeId || newWallpaperUrl != _customWallpaperUrl) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        if (newThemeId != null) {
                          _currentThemeId = newThemeId;
                          _themeCache[widget.otherUser.id] = newThemeId;
                        }
                        _customWallpaperUrl = newWallpaperUrl;
                        if (newWallpaperUrl != null) {
                          _wallpaperCache[widget.otherUser.id] = newWallpaperUrl;
                        } else {
                          _wallpaperCache.remove(widget.otherUser.id);
                        }
                      });
                    }
                  });
                }
              },
              onScrollToBottom: () => _scrollToBottom(animated: false),
              onMessageAction: _showMessageActionMenu,
              onReply: (msg) => setState(() => _replyingToMessage = msg),
              onOpenMedia: _openFullScreenMedia,
              onToggleReaction: (msg, emoji) => _toggleMessageReaction(msg['id'] as String, emoji),
              currentUserId: sb.Supabase.instance.client.auth.currentUser?.id,
            ),
          ),

          // â”€â”€ Composer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          isBlocked
              ? BlockedBanner(
                  otherUser: widget.otherUser,
                  blockedByMe: blockedByMe,
                  db: db,
                )
              : ChatComposer(
                  replyingToMessage: _replyingToMessage,
                  realtimeOtherUser: _realtimeOtherUser,
                  showEmojiPanel: _showEmojiPanel,
                  pickerTabIndex: _pickerTabIndex,
                  activeTheme: activeTheme,
                  onSend: (text, parent) => _sendMessage(text, parent),
                  onPickMedia: _sendMediaMessage,
                  onPickCamera: _sendCameraMessage,
                  onClearReply: () =>
                      setState(() => _replyingToMessage = null),
                  onToggleEmojiPanel: (show, tabIdx) => setState(() {
                    _showEmojiPanel = show;
                    _pickerTabIndex = tabIdx;
                  }),
                  onGifSelected: (gifUrl) => _sendGifMessage(gifUrl),
                  onSendAudio: (bytes) => _sendAudioMessage(bytes),
                ),
        ],
      ),
      ),
    );

    if (isWide) {
      mainContent = Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: context.border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: mainContent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isWide ? context.cardBg : context.scaffoldBg,
      body: mainContent,
    );
  }


}

// â”€â”€â”€ Isolated Message List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// This is a separate StatefulWidget so the stream update NEVER causes the
// composer or the AppBar to rebuild.