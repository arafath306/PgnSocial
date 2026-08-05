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
import '../widgets/create_thread/poll_creator.dart';
import '../widgets/create_thread/url_input_section.dart';
import '../widgets/create_thread/voice_recorder_ui.dart';

import '../models/thread_post.dart';
import '../models/draft_post.dart';
import '../services/draft_service.dart';
import '../utils/routes.dart';
import 'drafts_screen.dart';
import 'photo_editor_screen.dart';
import '../models/music_track.dart';
import '../widgets/music_search_sheet.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/general_settings_provider.dart';
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







  void _onContentChanged() {
    setState(() {
      _charCount = _contentController.text.length;
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
                      backgroundImage: CachedNetworkImageProvider(
                        _isAnonymous
                            ? "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150" // anonymous avatar placeholder
                            : (prof?.avatarUrl ?? ""),
                      ),
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
                                child: Text(
                                  _recordedAudioPath != null
                                      ? "Voice message recorded"
                                      : (_isRecording
                                          ? "Recording... ${_recordingSeconds}s"
                                          : "Tap microphone to record"),
                                  style: GoogleFonts.inter(
                                    color: context.textPrimary,
                                    fontWeight:
                                        _isRecording || _recordedAudioPath != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
              final settings = context.read<GeneralSettingsProvider>();
              if (settings.isVoicePostEnabled) {
                setState(() => _showVoiceRecorder = !_showVoiceRecorder);
              } else {
                _showComingSoonDialog("Voice messaging (Pending Admin Approval)");
              }
            },
            onAnonymousTap: () {
              final settings = context.read<GeneralSettingsProvider>();
              if (!settings.isAnonymousPostingEnabled) {
                _showComingSoonDialog("Anonymous Posting (Pending Admin Approval)");
                return;
              }
              setState(() {
                _isAnonymous = !_isAnonymous;
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        _isAnonymous ? Icons.security_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isAnonymous
                            ? 'Anonymous Mode ON 🕵️ (Name & avatar hidden)'
                            : 'Anonymous Mode OFF 👤 (Posting as yourself)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  backgroundColor: _isAnonymous ? Colors.indigo : const Color(0xFF1E824C),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
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

}
