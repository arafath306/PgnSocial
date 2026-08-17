import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/create_thread/compose_header.dart';
import '../widgets/create_thread/create_thread_header.dart';
import '../widgets/create_thread/create_thread_toolbar.dart';
import '../widgets/create_thread/media_preview_section.dart';
import '../widgets/create_thread/mention_autocomplete_overlay.dart';
import '../widgets/create_thread/hashtag_autocomplete_overlay.dart';
import '../widgets/create_thread/poll_creator.dart';
import '../widgets/create_thread/url_input_section.dart';
import '../widgets/create_thread/voice_recorder_ui.dart';
import '../widgets/audio_waveform_widget.dart';

import '../models/profile.dart';
import '../models/thread_post.dart';
import '../models/draft_post.dart';
import '../services/draft_service.dart';
import '../utils/routes.dart';
import 'drafts_screen.dart';
import '../utils/shared_photo_editor.dart';
import '../models/music_track.dart';
import '../widgets/music_search_sheet.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/general_settings_provider.dart';
import 'settings/verification/verification_intro_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
part 'create_thread_drafts_extensions.dart';
part 'create_thread_media_extensions.dart';
part 'create_thread_voice_extensions.dart';
part 'create_thread_publish_extensions.dart';


class CreateThreadScreen extends StatefulWidget {
  final ThreadPost? quotePost;
  /// When non-null the screen is in "edit" mode: pre-fills text and saves via editPostContent.
  final ThreadPost? editPost;
  final DraftPost? draftPost;
  final String? communityId;
  const CreateThreadScreen({super.key, this.quotePost, this.editPost, this.draftPost, this.communityId});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  String _privacy = "Public";
  bool _privacyOpen = false;
  int _charCount = 0;
  bool _showImageInput = false;
  final bool _showVideoInput = false;
  bool _isAnonymous = false;
  bool _isSubscriberOnly = false;

  final List<Uint8List> _selectedImagesBytesList = [];
  final List<Uint8List> _originalImagesBytesList = [];
  // ignore: unused_field
  String? _selectedImageName;
  bool _isUploadingImage = false;

  // Additional Interactive UI States
  bool _showPollInput = false;
  final List<TextEditingController> _pollControllers = [
    TextEditingController(),
    TextEditingController()
  ];
  final List<Uint8List?> _pollOptionImageBytes = [null, null];
  Duration _pollDuration = const Duration(hours: 24);
  final List<Map<String, dynamic>> _durations = [
    {"label": "1 Hour", "duration": const Duration(hours: 1)},
    {"label": "6 Hours", "duration": const Duration(hours: 6)},
    {"label": "1 Day", "duration": const Duration(hours: 24)},
    {"label": "3 Days", "duration": const Duration(days: 3)},
    {"label": "7 Days", "duration": const Duration(days: 7)},
  ];
  
  String? _selectedLocation;
  
  bool _showVoiceRecorder = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _recordedAudioPath;
  bool _isPlayingAudio = false;

  bool _isLoadingExistingMedia = false;
  
  int _draftCount = 0;
  final DraftService _draftService = DraftService();
  MusicTrack? _selectedMusic;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _loadDraftCount();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });

    // Always refresh feature flags when this screen opens so that
    // admin changes (e.g. toggling anonymous posting) take effect
    // immediately without requiring an app restart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<GeneralSettingsProvider>(context, listen: false)
            .refreshFeatureFlags();
      }
    });

    if (widget.draftPost != null) {
      _contentController.text = widget.draftPost!.content;
      _privacy = widget.draftPost!.audience;
      _selectedLocation = widget.draftPost!.location;
      if (widget.draftPost!.videoUrl != null) {
        _videoUrlController.text = widget.draftPost!.videoUrl!;
      }
      if (widget.draftPost!.imagePaths.isNotEmpty) {
        _loadDraftImages(widget.draftPost!.imagePaths);
      }
      if (widget.draftPost!.musicTrack != null) {
        _selectedMusic = widget.draftPost!.musicTrack;
      }
    } else if (widget.editPost != null) {
      _contentController.text = widget.editPost!.content;
      _loadExistingMedia();
    }
  }







  List<Profile> _mentionSuggestions = [];
  bool _isSearchingMentions = false;
  String? _activeMentionQuery;
  int _mentionStartIndex = -1;

  List<Map<String, dynamic>> _hashtagSuggestions = [];
  bool _isSearchingHashtags = false;
  String? _activeHashtagQuery;
  int _hashtagStartIndex = -1;

  void _onContentChanged() {
    setState(() {
      _charCount = _contentController.text.length;
    });

    _checkMentionTrigger();
    _checkHashtagTrigger();
  }

  Future<void> _checkHashtagTrigger() async {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.baseOffset <= 0 || selection.baseOffset > text.length) {
      if (_hashtagSuggestions.isNotEmpty) {
        setState(() => _hashtagSuggestions = []);
      }
      return;
    }

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final match = RegExp(r'#([a-zA-Z0-9_\u0980-\u09FF]*)$').firstMatch(textBeforeCursor);

    if (match != null) {
      final query = match.group(1) ?? '';
      _hashtagStartIndex = match.start;
      _activeHashtagQuery = query;

      setState(() => _isSearchingHashtags = true);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final results = await dbService.searchHashtags(query);

      if (mounted && _activeHashtagQuery == query) {
        setState(() {
          _hashtagSuggestions = results;
          _isSearchingHashtags = false;
        });
      }
    } else if (_hashtagSuggestions.isNotEmpty) {
      setState(() {
        _hashtagSuggestions = [];
        _isSearchingHashtags = false;
        _activeHashtagQuery = null;
      });
    }
  }

  void _onHashtagSelected(String tag) {
    if (_hashtagStartIndex < 0) return;
    final text = _contentController.text;
    final cursor = _contentController.selection.baseOffset;
    if (cursor < _hashtagStartIndex || _hashtagStartIndex > text.length) return;

    final prefix = text.substring(0, _hashtagStartIndex);
    final suffix = cursor <= text.length ? text.substring(cursor) : '';
    final inserted = '#$tag ';
    
    _contentController.text = '$prefix$inserted$suffix';
    _contentController.selection = TextSelection.collapsed(
      offset: prefix.length + inserted.length,
    );

    setState(() {
      _hashtagSuggestions = [];
      _activeHashtagQuery = null;
    });
  }

  Future<void> _checkMentionTrigger() async {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.baseOffset <= 0 || selection.baseOffset > text.length) {
      if (_mentionSuggestions.isNotEmpty) {
        setState(() => _mentionSuggestions = []);
      }
      return;
    }

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final match = RegExp(r'@([a-zA-Z0-9_\.\u0980-\u09FF]*)$').firstMatch(textBeforeCursor);

    if (match != null) {
      final query = match.group(1) ?? '';
      _mentionStartIndex = match.start;
      _activeMentionQuery = query;

      setState(() => _isSearchingMentions = true);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final results = await dbService.searchProfiles(query);

      if (mounted && _activeMentionQuery == query) {
        setState(() {
          _mentionSuggestions = results;
          _isSearchingMentions = false;
        });
      }
    } else if (_mentionSuggestions.isNotEmpty) {
      setState(() {
        _mentionSuggestions = [];
        _isSearchingMentions = false;
        _activeMentionQuery = null;
      });
    }
  }

  void _onMentionUserSelected(Profile user) {
    if (_mentionStartIndex < 0) return;
    final text = _contentController.text;
    final cursor = _contentController.selection.baseOffset;
    if (cursor < _mentionStartIndex || _mentionStartIndex > text.length) return;

    final prefix = text.substring(0, _mentionStartIndex);
    final suffix = cursor <= text.length ? text.substring(cursor) : '';
    final inserted = '@${user.username} ';
    
    _contentController.text = '$prefix$inserted$suffix';
    _contentController.selection = TextSelection.collapsed(
      offset: prefix.length + inserted.length,
    );

    setState(() {
      _mentionSuggestions = [];
      _activeMentionQuery = null;
    });
  }

  // --- Voice Recorder Methods ---








  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    for (var controller in _pollControllers) {
      controller.dispose();
    }
    super.dispose();
  }
























  @override
  Widget build(BuildContext context) {
    final prof = context.select((DatabaseService db) => db.myProfile);
    final isEnabled = (_contentController.text.trim().isNotEmpty || _recordedAudioPath != null) && _charCount <= 500 && !_isUploadingImage;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    // Body content tree
    Widget bodyContent = Column(
      children: [
        // ── Custom Header Bar ──────────────────────────────────────
        CreateThreadHeader(
          onClose: _handleClose,
          draftCount: _draftCount,
          isEditMode: widget.editPost != null,
          isQuoteMode: widget.quotePost != null,
          onDraftsPressed: () {
            Navigator.push(context, NoTransitionPageRoute(child: const DraftsScreen()))
                .then((_) => _loadDraftCount());
          },
          showSaveDraftButton: (_contentController.text.trim().isNotEmpty ||
              _selectedImagesBytesList.isNotEmpty ||
              _selectedMusic != null),
          onSaveDraftPressed: () async {
            await _saveCurrentDraft();
            if (context.mounted) Navigator.pop(context);
          },
          isSubmitEnabled: isEnabled,
          onSubmitPressed: _submit,
          isUploadingImage: _isUploadingImage,
        ),

        // ── Scrollable composer area ───────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Profile photo + thread connector line (Threads style)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: context.isDarkMode
                          ? const Color(0xFF1E2030)
                          : const Color(0xFFF3F4F6),
                      backgroundImage: _isAnonymous
                          ? const AssetImage('assets/anonymous_avatar.png') as ImageProvider
                          : ((prof?.avatarUrl != null && prof!.avatarUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(prof.avatarUrl!)
                              : null),
                      child: (!_isAnonymous && (prof?.avatarUrl == null || prof!.avatarUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 23, color: Colors.white54)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 2,
                      height: 160,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Right Side: All composer content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + privacy chip + text field + quote post
                      ComposeHeader(
                        isAnonymous: _isAnonymous,
                        profile: prof,
                        privacy: _privacy,
                        privacyOpen: _privacyOpen,
                        selectedLocation: _selectedLocation,
                        contentController: _contentController,
                        quotePost: widget.quotePost,
                        onPrivacyToggle: () =>
                            setState(() => _privacyOpen = !_privacyOpen),
                        onPrivacyChanged: (label) => setState(() {
                          _privacy = label;
                          _privacyOpen = false;
                        }),
                        onLocationRemove: () =>
                            setState(() => _selectedLocation = null),
                        suggestionOverlay: (_mentionSuggestions.isNotEmpty || _isSearchingMentions)
                            ? MentionAutocompleteOverlay(
                                users: _mentionSuggestions,
                                isLoading: _isSearchingMentions,
                                onUserSelected: _onMentionUserSelected,
                              )
                            : (_hashtagSuggestions.isNotEmpty || _isSearchingHashtags)
                                ? HashtagAutocompleteOverlay(
                                    hashtags: _hashtagSuggestions,
                                    isLoading: _isSearchingHashtags,
                                    onHashtagSelected: _onHashtagSelected,
                                  )
                                : null,
                      ),

                      // Image/media preview strip
                      MediaPreviewSection(
                        selectedImagesBytesList: _selectedImagesBytesList,
                        isLoadingExistingMedia: _isLoadingExistingMedia,
                        selectedMusic: _selectedMusic,
                        onPickMoreImages: _pickImages,
                        onRemoveImage: (index) {
                          setState(() {
                            _selectedImagesBytesList.removeAt(index);
                            _originalImagesBytesList.removeAt(index);
                            if (_selectedImagesBytesList.isEmpty) {
                              _selectedMusic = null;
                            }
                          });
                        },
                        onEditImage: _openPhotoEditorAtIndex,
                        onRemoveMusic: () =>
                            setState(() => _selectedMusic = null),
                      ),

                      // Voice Recorder inline recording controls
                      if (_showVoiceRecorder) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF1E2030)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _recordedAudioPath != null
                                    ? _toggleAudioPreview
                                    : (_isRecording
                                        ? _stopRecording
                                        : _startRecording),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: _isRecording
                                      ? Colors.redAccent
                                      : const Color(0xFF1E824C),
                                  child: Icon(
                                    _recordedAudioPath != null
                                        ? (_isPlayingAudio
                                            ? Icons.pause
                                            : Icons.play_arrow)
                                        : (_isRecording
                                            ? Icons.stop
                                            : Icons.mic),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _recordedAudioPath != null
                                    ? AudioWaveformWidget(
                                        progress: _isPlayingAudio ? 0.6 : 0.0,
                                        seedKey: _recordedAudioPath,
                                        activeColor: const Color(0xFF1E824C),
                                        inactiveColor: context.isDarkMode
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1),
                                        height: 24,
                                      )
                                    : Text(
                                        _isRecording
                                            ? "Recording... ${_recordingSeconds}s"
                                            : "Tap microphone to record voice post",
                                        style: GoogleFonts.inter(
                                          color: _isRecording ? Colors.redAccent : context.textPrimary,
                                          fontWeight:
                                              _isRecording ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                              ),
                              if (_recordedAudioPath != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: _deleteRecording,
                                ),
                            ],
                          ),
                        ),
                      ],

                      // Optional Image URL / Video URL inputs
                      UrlInputSection(
                        imageUrlController: _imageUrlController,
                        videoUrlController: _videoUrlController,
                        showImageInput: _showImageInput,
                        showVideoInput: _showVideoInput,
                      ),



                      // Poll Creator Interface
                      if (_showPollInput)
                        PollCreator(
                          controllers: _pollControllers,
                          optionImageBytesList: _pollOptionImageBytes,
                          selectedDuration: _pollDuration,
                          durations: _durations,
                          onClose: () {
                            setState(() {
                              _showPollInput = false;
                              for (var controller in _pollControllers) {
                                controller.clear();
                              }
                              _pollOptionImageBytes.clear();
                              _pollOptionImageBytes.addAll([null, null]);
                            });
                          },
                          onAddOption: () {
                            setState(() {
                              _pollControllers.add(TextEditingController());
                              _pollOptionImageBytes.add(null);
                            });
                          },
                          onRemoveOption: (index) {
                            setState(() {
                              final controller = _pollControllers.removeAt(index);
                              controller.dispose();
                              if (index < _pollOptionImageBytes.length) {
                                _pollOptionImageBytes.removeAt(index);
                              }
                            });
                          },
                          onPickOptionImage: (index) async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setState(() {
                                while (_pollOptionImageBytes.length <= index) {
                                  _pollOptionImageBytes.add(null);
                                }
                                _pollOptionImageBytes[index] = bytes;
                              });
                            }
                          },
                          onRemoveOptionImage: (index) {
                            setState(() {
                              if (index < _pollOptionImageBytes.length) {
                                _pollOptionImageBytes[index] = null;
                              }
                            });
                          },
                          onDurationChanged: (val) {
                            setState(() {
                              _pollDuration = val;
                            });
                          },
                        ),

                      // Voice Recording Interface (VoiceRecorderUI widget)
                      if (_showVoiceRecorder)
                        VoiceRecorderUI(
                          isRecording: _isRecording,
                          recordingSeconds: _recordingSeconds,
                          onToggleRecording: _toggleRecording,
                          onClose: () {
                            _recordingTimer?.cancel();
                            setState(() {
                              _showVoiceRecorder = false;
                              _isRecording = false;
                              _recordingSeconds = 0;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom Toolbar ─────────────────────────────────────────
        SafeArea(
          child: CreateThreadToolbar(
            charCount: _charCount,
            isActiveImage: _selectedImagesBytesList.isNotEmpty ||
                _imageUrlController.text.isNotEmpty ||
                _showImageInput,
            isActiveMusic: _selectedMusic != null,
            isActivePoll: _showPollInput,
            isActiveVoice: _showVoiceRecorder,
            isActiveAnonymous: _isAnonymous,
            isActiveSubscriber: _isSubscriberOnly,
            canMonetize: context.select<DatabaseService, bool>(
                (db) => db.myProfile?.canMonetize == true),
            onImageTap: _pickImages,
            onCameraTap: _pickCameraImage,
            onMusicTap: () async {
              if (_selectedImagesBytesList.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please add a photo first to attach music.",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }
              final selected = await showModalBottomSheet<MusicTrack>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const MusicSearchSheet(),
              );
              if (selected != null) {
                setState(() {
                  _selectedMusic = selected;
                });
              }
            },
            onPollTap: () => setState(() => _showPollInput = !_showPollInput),
            onVoiceTap: () {
              final db = context.read<DatabaseService>();
              final isPremium = db.myProfile?.isPremium == true;
              if (isPremium) {
                setState(() => _showVoiceRecorder = !_showVoiceRecorder);
              } else {
                _showUpgradePremiumDialog(
                  title: "Voice Posts (Premium Feature)",
                  description: "Voice posts allow you to record and share high-quality audio notes with your followers. Upgrade to any Premium plan to unlock Voice Posts!",
                  icon: Icons.mic_rounded,
                  iconColor: Colors.teal,
                );
              }
            },
            onAnonymousTap: () {
              final db = context.read<DatabaseService>();
              final isPremium = db.myProfile?.isPremium == true;
              if (isPremium) {
                if (_isAnonymous) {
                  setState(() {
                    _isAnonymous = false;
                  });
                  _showAliasSnackBar(false);
                } else {
                  _showPigeonAliasDialog();
                }
              } else {
                _showUpgradePremiumDialog(
                  title: "Pigeon Alias Mode (Premium Feature)",
                  description: "Publish threads under a Pigeon Alias without revealing your real identity or profile. Upgrade to any Premium plan to unlock Pigeon Alias Mode!",
                  icon: Icons.security_rounded,
                  iconColor: Colors.indigo,
                );
              }
            },
            onSubscriberTap: () =>
                setState(() => _isSubscriberOnly = !_isSubscriberOnly),
            onComingSoonTap: _showComingSoonDialog,
          ),
        ),
      ],
    );

    // Responsive wrap: centred card on wide screens
    if (isWide) {
      bodyContent = Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: context.border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              backgroundColor: context.cardBg,
              body: bodyContent,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isWide ? context.scaffoldBg : context.cardBg,
      body: bodyContent,
    );
  }

  void _showAliasSnackBar(bool enabled) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              enabled ? Icons.security_rounded : Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              enabled
                  ? 'Alias Mode ON 🕵️ your identity is hidden'
                  : 'Alias Mode OFF 👤 your identity is visible',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: enabled ? const Color(0xFF1E824C) : const Color(0xFF374151),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPigeonAliasDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1F2937) : Colors.white;
        final titleColor = isDark ? Colors.white : const Color(0xFF111827);
        final textColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
        final btnColor = const Color(0xFF1E824C);

        return AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.security_rounded, color: btnColor, size: 24),
              const SizedBox(width: 10),
              Text(
                "Pigeon Alias Mode",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            "Publishing this post in Pigeon Alias Mode hides your profile details, avatar, and username from other users. \n\n"
            "Your content will be posted under the identity of 'Pigeon Alias'. System administrators can still view the real author to ensure compliance with our community guidelines.",
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isAnonymous = true;
                });
                _showAliasSnackBar(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "Enable Alias",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}
