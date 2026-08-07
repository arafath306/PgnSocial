import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'formatted_content_text.dart';

class ExpandablePostText extends StatefulWidget {
  final String text;
  final int maxChars;
  final TextStyle? style;

  const ExpandablePostText({
    super.key,
    required this.text,
    this.maxChars = 220,
    this.style,
  });

  @override
  State<ExpandablePostText> createState() => _ExpandablePostTextState();
}

class _ExpandablePostTextState extends State<ExpandablePostText> {
  bool _isExpanded = false;
  late TapGestureRecognizer _toggleRecognizer;

  @override
  void initState() {
    super.initState();
    _toggleRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      };
  }

  @override
  void dispose() {
    _toggleRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ??
        GoogleFonts.hindSiliguri(
          fontSize: 16.5,
          color: context.textPrimary,
          height: 1.45,
        );

    final text = widget.text;
    if (text.isEmpty) return const SizedBox.shrink();

    // Check line break or character count threshold
    final lineMatches = '\n'.allMatches(text).toList();
    final hasManyLines = lineMatches.length >= 4;
    final isLong = text.length > widget.maxChars || hasManyLines;

    if (!isLong) {
      return FormattedContentText(text: text, style: defaultStyle);
    }

    if (_isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormattedContentText(text: text, style: defaultStyle),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Text(
              'Show less',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D9BF0),
              ),
            ),
          ),
        ],
      );
    }

    // Find a clean cutoff near maxChars
    int cutIndex = widget.maxChars;
    if (cutIndex > text.length) cutIndex = text.length;

    // If there are many linebreaks before maxChars, cut at 4th linebreak
    if (lineMatches.length >= 4 && lineMatches[3].start < cutIndex) {
      cutIndex = lineMatches[3].start;
    }

    final truncatedText = '${text.substring(0, cutIndex).trimRight()}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormattedContentText(text: truncatedText, style: defaultStyle),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = true),
          child: Text(
            'See more',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D9BF0),
            ),
          ),
        ),
      ],
    );
  }
}
