import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class CreateThreadToolbar extends StatelessWidget {
  final int charCount;
  final bool isActiveImage;
  final bool isActiveMusic;
  final bool isActivePoll;
  final bool isActiveVoice;
  final bool isActiveAnonymous;
  final bool isActiveSubscriber;
  final bool canMonetize;
  
  final VoidCallback onImageTap;
  final VoidCallback onCameraTap;
  final VoidCallback onMusicTap;
  final VoidCallback onPollTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onAnonymousTap;
  final VoidCallback onSubscriberTap;
  final Function(String) onComingSoonTap;

  const CreateThreadToolbar({
    super.key,
    required this.charCount,
    required this.isActiveImage,
    required this.isActiveMusic,
    required this.isActivePoll,
    required this.isActiveVoice,
    required this.isActiveAnonymous,
    required this.isActiveSubscriber,
    required this.canMonetize,
    required this.onImageTap,
    required this.onCameraTap,
    required this.onMusicTap,
    required this.onPollTap,
    required this.onVoiceTap,
    required this.onAnonymousTap,
    required this.onSubscriberTap,
    required this.onComingSoonTap,
  });

  Widget _buildToolbarIcon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? color : context.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.border, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Attachment Tool Icons (Horizontal List)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildToolbarIcon(
                    context,
                    icon: Icons.image_outlined,
                    tooltip: "Add Image",
                    color: Theme.of(context).primaryColor,
                    isActive: isActiveImage,
                    onTap: onImageTap,
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.camera_alt_outlined,
                    tooltip: "Camera Capture",
                    color: Colors.deepOrange,
                    isActive: false,
                    onTap: onCameraTap,
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.music_note_rounded,
                    tooltip: "Add Music",
                    color: Colors.redAccent,
                    isActive: isActiveMusic,
                    onTap: onMusicTap,
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.play_circle_outline,
                    tooltip: "Video URL",
                    color: Colors.purple,
                    isActive: false,
                    onTap: () => onComingSoonTap("Video upload/embed"),
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.bar_chart_outlined,
                    tooltip: "Create Poll",
                    color: Colors.orange,
                    isActive: isActivePoll,
                    onTap: onPollTap,
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.mic_outlined,
                    tooltip: "Voice Message",
                    color: Colors.teal,
                    isActive: isActiveVoice,
                    onTap: onVoiceTap,
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.location_on_outlined,
                    tooltip: "Add Location",
                    color: Colors.blue,
                    isActive: false,
                    onTap: () => onComingSoonTap("Location pinning"),
                  ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.security_outlined,
                    tooltip: "Anonymous Post",
                    color: Colors.indigo,
                    isActive: isActiveAnonymous,
                    onTap: onAnonymousTap,
                  ),
                  if (canMonetize)
                    _buildToolbarIcon(
                      context,
                      icon: Icons.monetization_on_outlined,
                      tooltip: "Subscribers Only",
                      color: Colors.amber,
                      isActive: isActiveSubscriber,
                      onTap: onSubscriberTap,
                    ),
                  _buildToolbarIcon(
                    context,
                    icon: Icons.auto_awesome_outlined,
                    tooltip: "AI Writer",
                    color: Colors.pink,
                    isActive: false,
                    onTap: () => onComingSoonTap("AI writer assistant"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Character limit progress bar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$charCount/500",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: charCount > 500 ? Colors.red : context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: (charCount / 500).clamp(0.0, 1.0),
                  backgroundColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                  color: charCount > 500 
                      ? Colors.red 
                      : charCount > 400 
                          ? Colors.orange 
                          : Theme.of(context).primaryColor,
                  strokeWidth: 2.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
