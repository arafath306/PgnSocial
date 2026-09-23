import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/profile.dart';
import '../../../services/database_service.dart';
import '../../../services/general_settings_provider.dart';
import '../../../utils/app_theme.dart';

class UserActionsSheet extends StatelessWidget {
  final Profile profile;
  final VoidCallback onChatRemoved;
  final bool isPinned;
  final VoidCallback? onTogglePin;

  const UserActionsSheet({
    super.key,
    required this.profile,
    required this.onChatRemoved,
    this.isPinned = false,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // User info header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.border,
                    backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(profile.avatarUrl!)
                        : null,
                    child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, size: 16, color: context.textMuted)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.fullName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: context.border, height: 1),

            // 0. Pin / Unpin Conversation
            if (onTogglePin != null)
              _actionTile(
                context: context,
                icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: isPinned ? context.textPrimary : context.textPrimary,
                label: isPinned ? 'Unpin Conversation' : 'Pin to Top',
                onTap: () {
                  Navigator.pop(context);
                  onTogglePin!();
                },
              ),

            // 1. Delete Conversation (chat + history)
            _actionTile(
              context: context,
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              label: 'Delete Conversation',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: context.cardBg,
                    title: Text('Delete Conversation?',
                        style: GoogleFonts.inter(color: context.textPrimary)),
                    content: Text(
                      'All messages with ${profile.fullName} will be permanently deleted.',
                      style: GoogleFonts.inter(color: context.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dCtx);
                          final success = await db.deleteConversation(profile.id);
                          if (success) {
                            onChatRemoved();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(success ? 'Conversation deleted.' : 'Failed to delete.'),
                              backgroundColor: success ? Colors.red : Colors.orange,
                            ));
                          }
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 2. Clear Chat
            _actionTile(
              context: context,
              icon: Icons.cleaning_services_outlined,
              color: context.textPrimary,
              label: 'Clear Chat',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: context.cardBg,
                    title: Text('Clear Chat?',
                        style: GoogleFonts.inter(color: context.textPrimary)),
                    content: Text(
                      'All messages will be cleared permanently. This cannot be undone.',
                      style: GoogleFonts.inter(color: context.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dCtx);
                          final success = await db.deleteConversation(profile.id);
                          if (success) {
                            onChatRemoved();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(success ? 'Chat cleared.' : 'Failed to clear chat.'),
                              backgroundColor: success ? Colors.deepPurple : Colors.orange,
                            ));
                          }
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.deepPurple)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 3. Block User
            _actionTile(
              context: context,
              icon: Icons.block_flipped,
              color: Colors.red,
              label: 'Block User',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: context.cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text('Block ${profile.fullName}?',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'When you block someone:',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: context.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        _blockBullet(context, '• They cannot message you'),
                        _blockBullet(context, '• You will unfollow each other'),
                        _blockBullet(context, '• They won\'t see your posts'),
                        _blockBullet(context, '• You can unblock anytime'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(color: context.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dCtx);
                          await settings.blockUserById(profile.id);
                          await db.fetchBlockedMutedLists();
                          await db.fetchFollowingList();
                          onChatRemoved();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${profile.fullName} has been blocked.'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Block',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 4. Report User
            _actionTile(
              context: context,
              icon: Icons.flag_outlined,
              color: context.textSecondary,
              label: 'Report User',
              onTap: () {
                Navigator.pop(context);
                _showReportSheet(context, profile, db);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
      ),
    );
  }

  void _showReportSheet(BuildContext context, Profile profile, DatabaseService db) {
    final List<String> reasons = [
      'Spam or unwanted messages',
      'Harassment or bullying',
      'Inappropriate content',
      'Impersonation',
      'Other',
    ];
    String? selectedReason;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (rCtx) {
        return StatefulBuilder(
          builder: (rCtx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(rCtx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Report ${profile.fullName}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text('Select a reason:',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: context.textSecondary)),
                  const SizedBox(height: 12),
                  ...reasons.map((r) => InkWell(
                        onTap: () => setSheetState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedReason == r
                                        ? context.primaryAccent!
                                        : context.textMuted,
                                    width: 2,
                                  ),
                                  color: selectedReason == r
                                      ? context.primaryAccent
                                      : Colors.transparent,
                                ),
                                child: selectedReason == r
                                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(r,
                                    style: GoogleFonts.inter(
                                        fontSize: 13.5, color: context.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedReason == null
                          ? null
                          : () async {
                              Navigator.pop(rCtx);
                              final success = await db.reportProfile(
                                  profile.id, selectedReason!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(success
                                      ? 'Report submitted. Thank you.'
                                      : 'Failed to submit report.'),
                                  backgroundColor:
                                      success ? Colors.green : Colors.orange,
                                ));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Submit Report',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
