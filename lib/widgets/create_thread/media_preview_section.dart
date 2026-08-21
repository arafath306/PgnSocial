import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/music_track.dart';
import '../../utils/app_theme.dart';

/// Horizontal image preview strip with edit/remove overlays, an
/// "Add More" card, and a music track badge overlaid on the images.
/// Renders images with dynamic aspect ratio based on user edit/crop or natural dimensions.
class MediaPreviewSection extends StatelessWidget {
  final List<Uint8List> selectedImagesBytesList;
  final bool isLoadingExistingMedia;
  final MusicTrack? selectedMusic;
  final VoidCallback onPickMoreImages;
  final void Function(int index) onRemoveImage;
  final void Function(int index) onEditImage;
  final VoidCallback onRemoveMusic;

  const MediaPreviewSection({
    super.key,
    required this.selectedImagesBytesList,
    required this.isLoadingExistingMedia,
    required this.selectedMusic,
    required this.onPickMoreImages,
    required this.onRemoveImage,
    required this.onEditImage,
    required this.onRemoveMusic,
  });

  @override
  Widget build(BuildContext context) {
    // ── Loading skeleton ───────────────────────────────────────────
    if (isLoadingExistingMedia) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1E2030)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 0.8),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Loading attached media...",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Nothing to show
    if (selectedImagesBytesList.isEmpty) return const SizedBox.shrink();

    // ── Image strip + music badge ──────────────────────────────────
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Horizontal image list
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: selectedImagesBytesList.length + 1,
                itemBuilder: (context, index) {
                  // "Add More" card at the end
                  if (index == selectedImagesBytesList.length) {
                    return GestureDetector(
                      onTap: onPickMoreImages,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1E2030)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.border, width: 0.8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: context.primaryAccent,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add More",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Individual dynamic aspect-ratio image card
                  final bytes = selectedImagesBytesList[index];
                  return _DynamicMemoryImageCard(
                    bytes: bytes,
                    index: index,
                    onRemove: onRemoveImage,
                    onEdit: onEditImage,
                  );
                },
              ),
            ),

            // Music badge overlay
            if (selectedMusic != null)
              Positioned(
                left: 8,
                right: 20,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${selectedMusic!.trackName} - ${selectedMusic!.artistName}",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemoveMusic,
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DynamicMemoryImageCard extends StatefulWidget {
  final Uint8List bytes;
  final int index;
  final void Function(int) onRemove;
  final void Function(int) onEdit;

  const _DynamicMemoryImageCard({
    required this.bytes,
    required this.index,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  State<_DynamicMemoryImageCard> createState() => _DynamicMemoryImageCardState();
}

class _DynamicMemoryImageCardState extends State<_DynamicMemoryImageCard> {
  double _aspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    _resolveSize();
  }

  @override
  void didUpdateWidget(covariant _DynamicMemoryImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      _resolveSize();
    }
  }

  void _resolveSize() {
    try {
      final ImageStream stream = MemoryImage(widget.bytes).resolve(const ImageConfiguration());
      stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          final double w = info.image.width.toDouble();
          final double h = info.image.height.toDouble();
          if (w > 0 && h > 0) {
            final double calculatedRatio = w / h;
            setState(() {
              _aspectRatio = calculatedRatio.clamp(0.75, 1.85);
            });
          }
        }
      }));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = (160 * _aspectRatio).clamp(110.0, 240.0);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              widget.bytes,
              width: cardWidth,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          // Remove button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => widget.onRemove(widget.index),
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
          // Edit/Crop button
          Positioned(
            bottom: 6,
            left: 6,
            child: GestureDetector(
              onTap: () => widget.onEdit(widget.index),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: const Icon(
                  Icons.crop_rotate_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
