import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../utils/media_saver_utility.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String? mediaUrl;
  final List<dynamic>? mediaItems;
  final int initialIndex;
  final bool isVideo;

  const FullScreenMediaViewer({
    super.key,
    this.mediaUrl,
    this.mediaItems,
    this.initialIndex = 0,
    this.isVideo = false,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<dynamic> _items;

  @override
  void initState() {
    super.initState();
    if (widget.mediaItems != null && widget.mediaItems!.isNotEmpty) {
      _items = List<dynamic>.from(widget.mediaItems!);
    } else if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
      _items = [widget.mediaUrl!];
    } else {
      _items = [];
    }

    _currentIndex = widget.initialIndex.clamp(
      0,
      _items.isEmpty ? 0 : _items.length - 1,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadMedia(BuildContext context) async {
    if (_items.isEmpty) return;
    final currentItem = _items[_currentIndex];
    if (currentItem is String && currentItem.isNotEmpty) {
      await MediaSaverUtility.saveToGallery(
        context,
        currentItem,
        isVideo: widget.isVideo,
      );
    } else if (currentItem is Uint8List) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/save_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(currentItem);
        await Gal.putImage(file.path, album: 'Pigeon');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to gallery!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save image: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _items.length > 1
            ? Text(
                '${_currentIndex + 1} of ${_items.length}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : null,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => _downloadMedia(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 50,
              ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                Widget mediaChild;

                if (item is Uint8List) {
                  mediaChild = Image.memory(
                    item,
                    fit: BoxFit.contain,
                  );
                } else if (item is String && item.isNotEmpty) {
                  mediaChild = CachedNetworkImage(
                    imageUrl: item,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white70,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                } else {
                  mediaChild = const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 50,
                  );
                }

                return Center(
                  child: InteractiveViewer(
                    clipBehavior: Clip.none,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: mediaChild,
                  ),
                );
              },
            ),
    );
  }
}