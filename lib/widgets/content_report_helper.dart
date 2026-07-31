import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/general_settings_provider.dart';
import '../utils/app_theme.dart';

class ContentReportHelper {
  static void showReportSheet({
    required BuildContext context,
    required String targetId,
    required String targetAuthorUsername,
    required String targetAuthorUserId,
    required String contentType, // 'post' or 'comment'
  }) {
    final categoryMap = <String, List<String>>{
      'Harassment or Bullying': [
        'It\'s harassing me directly',
        'It\'s harassing a friend or family member',
        'It\'s harassing someone else / public figure',
      ],
      'Hate Speech or Discrimination': [
        'Race, ethnicity or national origin',
        'Religious beliefs or practices',
        'Gender identity or sexual orientation',
        'Disability or medical condition',
      ],
      'Nudity or Sexual Content': [
        'Nudity or explicit exposure',
        'Explicit sexual acts or pornography',
        'Non-consensual sexual content / abuse',
      ],
      'Violence, Threat or Danger': [
        'Direct threat of physical violence',
        'Self-harm or suicide encouragement',
        'Dangerous or violent organization',
      ],
      'Scam, Fraud or Impersonation': [
        'Pretending to be me or someone I know',
        'Phishing, financial or crypto scam',
        'Spam or fake automated account',
      ],
      'False Information / Misinformation': [
        'Medical or health misinformation',
        'Political or election misinformation',
        'Fraudulent news / Dangerous hoax',
      ],
      'Intellectual Property Violation': [
        'Copyright infringement',
        'Trademark or brand violation',
      ],
      'Other Issue (specify details)': [],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (reportCtx) => Container(
        decoration: BoxDecoration(
          color: reportCtx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: reportCtx.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Report $contentType',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: reportCtx.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Select a category that best describes this issue:',
                    style: GoogleFonts.inter(fontSize: 13, color: reportCtx.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: reportCtx.border),
                ...categoryMap.entries.map((entry) {
                  final catTitle = entry.key;
                  final subCats = entry.value;
                  final isOther = subCats.isEmpty;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(reportCtx);
                        if (isOther) {
                          _showCustomReasonDialog(
                            context: context,
                            targetId: targetId,
                            targetAuthorUsername: targetAuthorUsername,
                            targetAuthorUserId: targetAuthorUserId,
                            contentType: contentType,
                          );
                        } else {
                          _showSubCategoryReportSheet(
                            context: context,
                            mainCategory: catTitle,
                            subCategories: subCats,
                            targetId: targetId,
                            targetAuthorUsername: targetAuthorUsername,
                            targetAuthorUserId: targetAuthorUserId,
                            contentType: contentType,
                          );
                        }
                      },
                      splashColor: Colors.red.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                catTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: reportCtx.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: reportCtx.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showSubCategoryReportSheet({
    required BuildContext context,
    required String mainCategory,
    required List<String> subCategories,
    required String targetId,
    required String targetAuthorUsername,
    required String targetAuthorUserId,
    required String contentType,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (subCtx) => Container(
        decoration: BoxDecoration(
          color: subCtx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subCtx.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  mainCategory,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: subCtx.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select a specific reason to help us understand:',
                  style: GoogleFonts.inter(fontSize: 13, color: subCtx.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: subCtx.border),
              ...subCategories.map((subCat) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(subCtx);
                        final fullReason = '$mainCategory - $subCat';
                        final dbService = Provider.of<DatabaseService>(context, listen: false);
                        final bool success = contentType == 'comment'
                            ? await dbService.reportComment(targetId, fullReason)
                            : await dbService.reportPost(targetId, fullReason);
                        if (!context.mounted) return;
                        if (success) {
                          _showReportSuccessSheet(
                            context: context,
                            username: targetAuthorUsername,
                            userId: targetAuthorUserId,
                          );
                        }
                      },
                      splashColor: Colors.red.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subCat,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: subCtx.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: subCtx.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static void _showCustomReasonDialog({
    required BuildContext context,
    required String targetId,
    required String targetAuthorUsername,
    required String targetAuthorUserId,
    required String contentType,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: dlgCtx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Report $contentType",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: dlgCtx.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please provide specific details about why you are reporting this $contentType:",
              style: GoogleFonts.inter(fontSize: 13, color: dlgCtx.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: dlgCtx.textPrimary),
              decoration: InputDecoration(
                hintText: "Enter details here...",
                hintStyle: GoogleFonts.inter(fontSize: 14, color: dlgCtx.textMuted),
                fillColor: dlgCtx.isDarkMode ? const Color(0xFF161B22) : const Color(0xFFF6F8FA),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dlgCtx.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text("Cancel", style: GoogleFonts.inter(color: dlgCtx.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(dlgCtx);
              final dbService = Provider.of<DatabaseService>(context, listen: false);
              final bool success = contentType == 'comment'
                  ? await dbService.reportComment(targetId, 'Other: $reason')
                  : await dbService.reportPost(targetId, 'Other: $reason');
              if (!context.mounted) return;
              if (success) {
                _showReportSuccessSheet(
                  context: context,
                  username: targetAuthorUsername,
                  userId: targetAuthorUserId,
                );
              }
            },
            child: Text("Submit", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _showReportSuccessSheet({
    required BuildContext context,
    required String username,
    required String userId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: sheetCtx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetCtx.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E824C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thanks for letting us know',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: sheetCtx.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'We use these reports to keep Pigeon safe for everyone.',
                            style: GoogleFonts.inter(fontSize: 12.5, color: sheetCtx.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: sheetCtx.border),
                const SizedBox(height: 16),
                Text(
                  'What else you can do:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: sheetCtx.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.block_outlined, color: Colors.redAccent),
                  title: Text('Block @$username', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  subtitle: Text('They won\'t be able to see your posts or contact you.', style: GoogleFonts.inter(fontSize: 12, color: sheetCtx.textSecondary)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showBlockConfirm(context, username, userId);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.volume_off_outlined, color: Colors.orangeAccent),
                  title: Text('Mute @$username', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: sheetCtx.textPrimary)),
                  subtitle: Text('Stop seeing content from @$username in your feed.', style: GoogleFonts.inter(fontSize: 12, color: sheetCtx.textSecondary)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final settingsProvider = Provider.of<GeneralSettingsProvider>(context, listen: false);
                    final dbService = Provider.of<DatabaseService>(context, listen: false);
                    await settingsProvider.muteUserById(userId);
                    await dbService.fetchBlockedMutedLists();
                    await dbService.fetchFeed();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('@$username has been muted')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showBlockConfirm(BuildContext context, String username, String userId) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: dlgCtx.cardBg,
        title: Text('Block @$username?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: dlgCtx.textPrimary)),
        content: Text('They will no longer be able to see your profile or posts.', style: GoogleFonts.inter(color: dlgCtx.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: dlgCtx.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final settingsProvider = Provider.of<GeneralSettingsProvider>(context, listen: false);
              final dbService = Provider.of<DatabaseService>(context, listen: false);
              await settingsProvider.blockUserById(userId);
              await dbService.fetchBlockedMutedLists();
              await dbService.fetchFeed();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('@$username has been blocked')),
                );
              }
            },
            child: Text('Block', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
