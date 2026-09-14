part of '../custom_thread_card.dart';


  Widget _buildMusicImageStack({
    required BuildContext context,
    required List<String> imageUrls,
    required double height,
    required MusicTrack? musicTrack,
    required String postId,
  }) {
    if (musicTrack == null) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ThreadImageCarousel(imageUrls: imageUrls, height: height),
        ],
      );
    }

    return VisibilityDetector(
      key: Key('music_post_$postId'),
      onVisibilityChanged: (info) {
        final controller = Provider.of<MusicPlaybackController>(
          context,
          listen: false,
        );
        controller.onPostVisibilityChanged(
          postId,
          musicTrack,
          info.visibleFraction,
        );
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ThreadImageCarousel(imageUrls: imageUrls, height: height),
          _buildSmallPlayButton(context, musicTrack, postId),
        ],
      ),
    );
  }

Widget _buildSmallPlayButton(BuildContext context, MusicTrack track, String postId) {
    return Consumer<MusicPlaybackController>(
      builder: (context, controller, child) {
        final isCurrent = controller.currentTrackId == track.trackId;
        final isPlaying = isCurrent && controller.isPlaying;

        return Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.play(track.trackId, track.previewUrl);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Center(
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
