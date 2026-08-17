import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/profile.dart';
import '../../models/thread_post.dart';
import '../../utils/app_theme.dart';

/// The right-side compose column content:
/// user name row, privacy chip + inline dropdown, location chip,
/// main text field, and the optional quote-post preview card.
///
/// State updates are driven via callbacks so all state stays in
/// [_CreateThreadScreenState].
class ComposeHeader extends StatelessWidget {
  final bool isAnonymous;
  final Profile? profile;
  final String privacy;
  final bool privacyOpen;
  final String? selectedLocation;
  final TextEditingController contentController;
  final ThreadPost? quotePost;
  final VoidCallback onPrivacyToggle;
  final void Function(String label) onPrivacyChanged;
  final VoidCallback onLocationRemove;

  const ComposeHeader({
    super.key,
    required this.isAnonymous,
    required this.profile,
    required this.privacy,
    required this.privacyOpen,
    required this.selectedLocation,
    required this.contentController,
    required this.quotePost,
    required this.onPrivacyToggle,
    required this.onPrivacyChanged,
    required this.onLocationRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── User name row ──────────────────────────────────────────
        Row(
          children: [
            Text(
              isAnonymous ? "Pigeon Alias" : (profile?.fullName ?? "User"),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: context.textPrimary,
              ),
            ),
            if (isAnonymous) ...[
              const SizedBox(width: 4),
              const Icon(Icons.security, color: Colors.indigo, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 4),

        // ── Privacy chip + location chip + inline dropdown ─────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Privacy chip
                GestureDetector(
                  onTap: onPrivacyToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          privacy == "Public"
                              ? Icons.public
                              : privacy == "Friends"
                                  ? Icons.people_alt
                                  : Icons.lock_outline,
                          size: 11,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          privacy,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: privacyOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 12,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Location chip (only when a location is set)
                if (selectedLocation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1A2333)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 11, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          selectedLocation!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 3),
                        GestureDetector(
                          onTap: onLocationRemove,
                          child: const Icon(Icons.close, size: 11, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Inline animated privacy dropdown
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: privacyOpen
                  ? Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          {"label": "Public", "icon": Icons.public},
                          {"label": "Friends", "icon": Icons.people_alt},
                          {"label": "Only Me", "icon": Icons.lock_outline},
                        ].map((opt) {
                          final label = opt["label"] as String;
                          final icon = opt["icon"] as IconData;
                          final isSel = privacy == label;
                          return InkWell(
                            onTap: () => onPrivacyChanged(label),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 14,
                                    color: isSel
                                        ? Theme.of(context).primaryColor
                                        : context.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: isSel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSel
                                          ? Theme.of(context).primaryColor
                                          : context.textPrimary,
                                    ),
                                  ),
                                  if (isSel) ...[
                                    const Spacer(),
                                    Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Main text input ────────────────────────────────────────
        TextField(
          controller: contentController,
          maxLines: null,
          minLines: 4,
          style: GoogleFonts.inter(
            fontSize: 15.5,
            color: context.textPrimary,
            height: 1.45,
          ),
          decoration: InputDecoration(
            hintText: "Send your thoughts...",
            hintStyle:
                GoogleFonts.inter(color: context.textMuted, fontSize: 14.5),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        // ── Quote post preview ─────────────────────────────────────
        if (quotePost != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: context.border, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: quotePost!.author.avatarUrl != null &&
                              quotePost!.author.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(
                              quotePost!.author.avatarUrl!)
                          : null,
                      child: quotePost!.author.avatarUrl == null ||
                              quotePost!.author.avatarUrl!.isEmpty
                          ? const Icon(Icons.person, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quotePost!.author.fullName,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: context.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "@${quotePost!.author.username}",
                      style:
                          TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  quotePost!.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 13.5, color: context.textPrimary),
                ),
                if (quotePost!.imageUrls != null &&
                    quotePost!.imageUrls!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: CachedNetworkImage(
                      imageUrl: quotePost!.imageUrls!.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
