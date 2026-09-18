import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// WhatsApp-style grouped photo album / collage widget.
/// Supports 2, 3, 4, and 5+ photos with responsive dimensions
/// and memory-safe image caching for smooth performance across all devices.
class ImageGroupCollage extends StatelessWidget {
  final List<Map<String, dynamic>> groupMessages;
  final bool isMe;
  final void Function(List<dynamic> mediaItems, int initialIndex) onOpenMedia;
  final VoidCallback? onLongPress;
  final bool hasReplyQuote;
  final bool hasTextCaption;

  const ImageGroupCollage({
    super.key,
    required this.groupMessages,
    required this.isMe,
    required this.onOpenMedia,
    this.onLongPress,
    this.hasReplyQuote = false,
    this.hasTextCaption = false,
  });

  List<dynamic> _extractMediaItems() {
    return groupMessages.map<dynamic>((m) {
      if (m['local_media_bytes'] != null) {
        return m['local_media_bytes'];
      }
      return m['media_url'] ?? '';
    }).toList();
  }

  Widget _buildImageTile(
    BuildContext context,
    Map<String, dynamic> msg,
    int index,
    int total, {
    bool isOverlayTile = false,
  }) {
    final bytes = msg['local_media_bytes'] as Uint8List?;
    final url = msg['media_url'] as String?;
    final bool isSending = msg['is_sending'] as bool? ?? false;

    Widget imageWidget;
    if (bytes != null) {
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 500,
      );
    } else if (url != null && url.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 500,
        placeholder: (context, _) => Container(
          color: Colors.black12,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 26,
            ),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        color: Colors.black12,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final mediaItems = _extractMediaItems();
        onOpenMedia(mediaItems, index);
      },
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          if (isSending)
            Center(
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (isOverlayTile)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Text(
                '+${total - 3}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = groupMessages.length;
    if (count == 0) return const SizedBox.shrink();

    final outerRadius = BorderRadius.only(
      topLeft: hasReplyQuote ? Radius.zero : const Radius.circular(16),
      topRight: hasReplyQuote ? Radius.zero : const Radius.circular(16),
      bottomLeft: hasTextCaption
          ? Radius.zero
          : (isMe ? const Radius.circular(16) : const Radius.circular(4)),
      bottomRight: hasTextCaption
          ? Radius.zero
          : (isMe ? const Radius.circular(4) : const Radius.circular(16)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (MediaQuery.of(context).size.width * 0.75).clamp(240.0, 310.0);

        // Compute responsive height based on image count
        double height;
        if (count == 2) {
          height = (width * 0.65).clamp(150.0, 200.0);
        } else if (count == 3) {
          height = (width * 0.88).clamp(220.0, 270.0);
        } else {
          height = (width * 0.92).clamp(220.0, 280.0);
        }

        Widget collageGrid;

        if (count == 2) {
          // 2 images: 2 side-by-side equal columns
          collageGrid = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildImageTile(context, groupMessages[0], 0, count),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImageTile(context, groupMessages[1], 1, count),
              ),
            ],
          );
        } else if (count == 3) {
          // 3 images: WhatsApp layout (1 large on left, 2 stacked on right)
          collageGrid = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _buildImageTile(context, groupMessages[0], 0, count),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[1], 1, count),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[2], 2, count),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (count == 4) {
          // 4 images: 2x2 grid
          collageGrid = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[0], 0, count),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[1], 1, count),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[2], 2, count),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[3], 3, count),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // 5+ images: 2x2 grid with +N on the 4th tile
          collageGrid = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[0], 0, count),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[1], 1, count),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child:
                          _buildImageTile(context, groupMessages[2], 2, count),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _buildImageTile(
                        context,
                        groupMessages[3],
                        3,
                        count,
                        isOverlayTile: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return ClipRRect(
          borderRadius: outerRadius,
          child: SizedBox(
            width: width,
            height: height,
            child: collageGrid,
          ),
        );
      },
    );
  }
}
