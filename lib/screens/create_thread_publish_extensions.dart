// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

part of 'create_thread_screen.dart';

extension CreateThreadPublishExtensions on _CreateThreadScreenState {
  void _submit() async {
    final text = _contentController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final videoUrl = _videoUrlController.text.trim();

    if (text.isEmpty && _recordedAudioPath == null && _selectedImagesBytesList.isEmpty && imageUrl.isEmpty && videoUrl.isEmpty && _selectedMusic == null) return;

    // -----------------------------------------------------------------------
    // ANTI-SPAM LINK CHECK (TEMPORARILY DISABLED FOR THREAD POSTS):
    // If any URL is detected in text, block submission and notify user gently.
    // -----------------------------------------------------------------------
    if (HashtagMentionParser.urlRegex.hasMatch(text)) {
      _showLinkNotAllowedGentleNotice();
      return;
    }

    setState(() => _isUploadingImage = true);
    final db = Provider.of<DatabaseService>(context, listen: false);

    // â”€â”€ Edit mode: just update the existing post content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (widget.editPost != null) {
      List<String>? uploadedUrls;
      if (_selectedImagesBytesList.isNotEmpty) {
        uploadedUrls = [];
        try {
          for (final bytes in _selectedImagesBytesList) {
            final imagePublicUrl = await db.uploadPostImage(bytes);
            if (imagePublicUrl != null) {
              uploadedUrls.add(imagePublicUrl);
            }
          }
          if (uploadedUrls.isEmpty) {
            uploadedUrls = null;
          }
        } catch (uploadError) {
          debugPrint("Edit post images upload failed: $uploadError");
        }
      }

      final success = await db.editPostContent(
        widget.editPost!.id,
        text,
        imageUrls: uploadedUrls ?? [],
      );

      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Post updated successfully', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ]),
            backgroundColor: const Color(0xFF1E824C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // return true = edited
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post', style: GoogleFonts.inter())),
        );
      }
      return;
    }

    // ——— Create / Quote mode ——————————————————————————————————————————————————————
    String finalContent = text;
    if (_selectedLocation != null) {
      finalContent += "\n\n📍 $_selectedLocation";
    }
    if (_selectedMusic != null) {
      finalContent += " 🎵DakMusic🎵${_selectedMusic!.toJson()}";
    }

    List<String>? pollOptions;
    Duration? pollDuration;
    if (_showPollInput) {
      final List<String> filledOptions = [];
      for (int i = 0; i < _pollControllers.length; i++) {
        final text = _pollControllers[i].text.trim();
        if (text.isNotEmpty) {
          String optStr = text;
          if (_pollOptionImageBytes.length > i && _pollOptionImageBytes[i] != null) {
            try {
              final uploadedOptionImg = await db.uploadPostImage(_pollOptionImageBytes[i]!);
              if (uploadedOptionImg != null) {
                optStr += '|DakOptionImg|$uploadedOptionImg';
              }
            } catch (optErr) {
              debugPrint("Failed to upload poll option image: $optErr");
            }
          }
          filledOptions.add(optStr);
        }
      }
      if (filledOptions.length >= 2) {
        pollOptions = filledOptions;
        pollDuration = _pollDuration;
      } else {
        // Block submission and show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Poll must have at least 2 options', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ]),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() => _isUploadingImage = false);
        }
        return;
      }
    }

    List<String>? uploadedUrls;
    if (_selectedImagesBytesList.isNotEmpty) {
      uploadedUrls = [];
      try {
        for (final bytes in _selectedImagesBytesList) {
          final imagePublicUrl = await db.uploadPostImage(bytes);
          if (imagePublicUrl != null) {
            uploadedUrls.add(imagePublicUrl);
          }
        }
        if (uploadedUrls.isEmpty) {
          uploadedUrls = null;
        }
      } catch (uploadError) {
        debugPrint("Post images upload failed: $uploadError");
      }
    } else if (imageUrl.isNotEmpty) {
      uploadedUrls = [imageUrl];
    }

    String? audioPublicUrl;
    if (_recordedAudioPath != null) {
      try {
        final bytes = await File(_recordedAudioPath!).readAsBytes();
        audioPublicUrl = await db.uploadPostAudio(bytes, 'm4a');
        if (audioPublicUrl == null) {
          throw Exception('Audio upload returned null');
        }
      } catch (e) {
        debugPrint("Voice post upload failed: $e");
        if (mounted) {
          setState(() => _isUploadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.mic_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Voice upload failed. Please check your connection and try again.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // Block post submission
      }
    }

    bool success = false;
    try {
      if (widget.quotePost != null) {
        success = await db.repostThread(
          widget.quotePost!.id,
          quoteText: finalContent,
        );
      } else {
        success = await db.createThread(
          finalContent,
          imageUrls: uploadedUrls,
          videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
          audioUrl: audioPublicUrl,
          audience: _privacy,
          pollOptions: pollOptions,
          pollDuration: pollDuration,
          communityId: widget.communityId,
          isSubscriberOnly: _isSubscriberOnly,
          isAnonymous: _isAnonymous,
        );
      }

      if (mounted) {
        setState(() => _isUploadingImage = false);
        if (success) {
          if (widget.draftPost != null) {
            await _draftService.deleteDrafts([widget.draftPost!.id]);
          }
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to publish post", style: GoogleFonts.inter()),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", ""), style: GoogleFonts.inter()),
          ),
        );
      }
    }
  }

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1E824C)),
            const SizedBox(width: 8),
            Text(
              "Coming Soon!",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ],
        ),
        content: Text(
          "$featureName feature is under development. Stay tuned for updates!",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Dismiss",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradePremiumDialog({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    showUpgradePremiumSheet(
      context: context,
      title: title,
      description: description,
      icon: icon,
      iconColor: iconColor,
    );
  }
}
