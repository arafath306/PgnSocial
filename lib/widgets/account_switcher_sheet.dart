import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/account_switcher_service.dart';
import '../models/saved_account.dart';
import '../utils/app_theme.dart';
import '../widgets/verification_badge.dart';
import '../screens/auth/auth_screen.dart';

void showAccountSwitcherSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const AccountSwitcherSheet(),
  );
}

class AccountSwitcherSheet extends StatelessWidget {
  const AccountSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final switcher = Provider.of<AccountSwitcherService>(context);
    final currentUid = switcher.currentUserId;
    final accounts = switcher.savedAccounts;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: context.border, width: 0.8),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Accounts',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              if (switcher.isSwitching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                    ),
                  ),
                )
              else ...[
                // List of Accounts
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 20,
                      color: context.border.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (ctx, index) {
                      final account = accounts[index];
                      final isCurrent = account.userId == currentUid;

                      return _buildAccountTile(
                        context: context,
                        account: account,
                        isCurrent: isCurrent,
                        onTap: isCurrent
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final success = await switcher.switchToAccount(context, account);
                                if (success && navigator.mounted) {
                                  navigator.pop();
                                }
                              },
                        onRemove: accounts.length > 1
                            ? () => _confirmRemoveAccount(context, switcher, account)
                            : null,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: context.border),
                const SizedBox(height: 8),

                // Add Another Account Button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          onLoginSuccess: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(0xFF1E824C).withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Color(0xFF1E824C),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add another account',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Log into an existing account or create a new one',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required SavedAccount account,
    required bool isCurrent,
    required VoidCallback? onTap,
    required VoidCallback? onRemove,
  }) {
    final avatarUrl = account.avatarUrl;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isCurrent
            ? const Color(0xFF1E824C).withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(Icons.person, color: context.textPrimary, size: 20)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.fullName.isNotEmpty ? account.fullName : account.username,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (account.isVerified) ...[
                        const SizedBox(width: 4),
                        VerificationBadge(
                          isVerified: true,
                          badgeType: account.badgeType,
                          size: 15,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${account.username}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isCurrent)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF1E824C),
                size: 22,
              )
            else if (onRemove != null)
              IconButton(
                icon: Icon(Icons.more_vert, color: context.textMuted, size: 18),
                onPressed: onRemove,
                tooltip: 'Remove account',
                splashRadius: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveAccount(
    BuildContext context,
    AccountSwitcherService switcher,
    SavedAccount account,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove account?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Remove @${account.username} from this device? You can log back in at any time.',
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              switcher.removeAccount(account.userId);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
