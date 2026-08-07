import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAndPlayVideo();
  }

  Future<void> _initializeAndPlayVideo() async {
    _videoController = VideoPlayerController.asset('assets/splash_video.mp4');
    try {
      await _videoController.initialize();
      await _videoController.setVolume(0.0); // Completely muted, no sound
      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      await _videoController.play();

      _videoController.addListener(() {
        if (_videoController.value.isInitialized &&
            _videoController.value.position >= _videoController.value.duration &&
            !_hasNavigated) {
          _navigateToNextScreen();
        }
      });

      // Safety timer in case listener misses end or video duration is long
      final videoDuration = _videoController.value.duration;
      Future.delayed(videoDuration + const Duration(milliseconds: 300), () {
        if (!_hasNavigated) {
          _navigateToNextScreen();
        }
      });
    } catch (e) {
      debugPrint('Error playing splash video: $e');
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isSignedIn = authService.isUserSignedIn;
    final isEmailVerified = authService.isEmailVerified;

    if (isSignedIn) {
      if (!isEmailVerified) {
        context.go('/verify-email');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1840),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF0C1840)),
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width > 0
                      ? _videoController.value.size.width
                      : 1080,
                  height: _videoController.value.size.height > 0
                      ? _videoController.value.size.height
                      : 1920,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
