import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class PollWidget extends StatelessWidget {
  final ThreadPost post;
  final DatabaseService dbService;

  const PollWidget({
    super.key,
    required this.post,
    required this.dbService,
  });

  @override
  Widget build(BuildContext context) {
    final options = post.pollOptions;
    if (options == null || options.isEmpty) return const SizedBox.shrink();

    final totalVotes = post.totalPollVotes;
    final isExpired = post.isPollExpired;
    final hasVoted = post.hasVotedPoll;
    final votedOptionId = post.votedOptionId;
    final showResults = isExpired || hasVoted;

    // Find the winning option(s) (highest votes)
    int maxVotes = 0;
    for (var opt in options) {
      if (opt.votesCount > maxVotes) {
        maxVotes = opt.votesCount;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...options.map((option) {
            final double percent = totalVotes > 0 ? (option.votesCount / totalVotes) : 0.0;
            final isWinner = showResults && option.votesCount == maxVotes && maxVotes > 0;
            final isUserChoice = showResults && option.id == votedOptionId;
            final hasOptionImg = option.imageUrl != null && option.imageUrl!.isNotEmpty;

            if (showResults) {
              // --- Voted or Expired view: Animate progress bars ---
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isWinner 
                          ? Colors.blue.withValues(alpha: 0.3) 
                          : context.border,
                      width: isWinner ? 1.2 : 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress fill animation
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: percent),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, val, child) {
                              return FractionallySizedBox(
                                widthFactor: val,
                                heightFactor: 1.0,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isWinner
                                          ? [Colors.blue.withValues(alpha: 0.25), Colors.blue.withValues(alpha: 0.15)]
                                          : [context.textSecondary.withValues(alpha: 0.12), context.textSecondary.withValues(alpha: 0.08)],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Label & stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (hasOptionImg) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: CachedNetworkImage(
                                          imageUrl: option.imageUrl!,
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        option.optionText,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                                          color: isWinner 
                                              ? (context.isDarkMode ? Colors.blue[300] : Colors.blue[900])
                                              : context.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isUserChoice) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.check_circle,
                                        color: context.isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                        size: 15,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(percent * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
                                  color: isWinner 
                                      ? (context.isDarkMode ? Colors.blue[300] : Colors.blue[900])
                                      : context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // --- Active & Not Voted view: Interactive pill-shaped buttons ---
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => dbService.votePoll(post.id, option.id),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.border,
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (hasOptionImg) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: option.imageUrl!,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              option.optionText,
                              textAlign: hasOptionImg ? TextAlign.left : TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 6),
          // Metadata row
          Row(
            children: [
              Text(
                '$totalVotes ${totalVotes == 1 ? "vote" : "votes"}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.textMuted.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getPollDurationString(post.pollExpiresAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPollDurationString(DateTime? expiresAt) {
    if (expiresAt == null) return "Unknown duration";
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return "Final results";
    }
    final diff = expiresAt.difference(now);
    if (diff.inDays >= 1) {
      return "${diff.inDays}d left";
    }
    if (diff.inHours >= 1) {
      return "${diff.inHours}h left";
    }
    if (diff.inMinutes >= 1) {
      return "${diff.inMinutes}m left";
    }
    return "Less than a minute left";
  }
}
