import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/hashtag_mention_parser.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search_explore_screen.dart';

class FormattedContentText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final Color? linkColor;

  const FormattedContentText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.linkColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final baseStyle = style ?? GoogleFonts.inter(
      fontSize: 14,
      color: context.textPrimary,
      height: 1.4,
    );

    final activeLinkColor = linkColor ?? const Color(0xFF1D9BF0);

    final tokens = HashtagMentionParser.parse(text);

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: baseStyle,
        children: tokens.map((token) {
          if (token.type == TextTokenType.hashtag) {
            return TextSpan(
              text: token.text,
              style: baseStyle.copyWith(
                color: activeLinkColor,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _handleHashtagTap(context, token.value),
            );
          } else if (token.type == TextTokenType.mention) {
            return TextSpan(
              text: token.text,
              style: baseStyle.copyWith(
                color: activeLinkColor,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _handleMentionTap(context, token.value),
            );
          } else {
            return TextSpan(text: token.text, style: baseStyle);
          }
        }).toList(),
      ),
    );
  }

  void _handleHashtagTap(BuildContext context, String tag) {
    final cleanTag = tag.startsWith('#') ? tag : '#$tag';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchExploreScreen(
          initialQuery: cleanTag,
          initialTabIndex: 1, // Switch to Posts tab for hashtag results
        ),
      ),
    );
  }

  Future<void> _handleMentionTap(BuildContext context, String username) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final profiles = await dbService.searchProfiles(username);
    
    if (!context.mounted) return;

    if (profiles.isNotEmpty) {
      final targetUser = profiles.firstWhere(
        (p) => p.username.toLowerCase() == username.toLowerCase(),
        orElse: () => profiles.first,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: targetUser.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User @$username not found'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
