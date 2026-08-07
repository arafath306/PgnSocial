enum TextTokenType { plain, hashtag, mention }

class TextToken {
  final String text;
  final TextTokenType type;
  final String value; // The raw hashtag tag (without #) or username (without @)

  const TextToken({
    required this.text,
    required this.type,
    required this.value,
  });
}

class HashtagMentionParser {
  // Regex supporting English, digits, underscore, dot and Bangla unicode (\u0980-\u09FF)
  static final RegExp mentionRegex = RegExp(r'@([a-zA-Z0-9_\.\u0980-\u09FF]+)');
  static final RegExp hashtagRegex = RegExp(r'#([a-zA-Z0-9_\u0980-\u09FF]+)');

  // Combined regex matching either mention or hashtag
  static final RegExp combinedRegex = RegExp(
    r'(@[a-zA-Z0-9_\.\u0980-\u09FF]+)|(#[a-zA-Z0-9_\u0980-\u09FF]+)',
  );

  /// Parses text into a list of plain, hashtag, or mention tokens.
  static List<TextToken> parse(String text) {
    if (text.isEmpty) return [];

    final List<TextToken> tokens = [];
    int lastMatchEnd = 0;

    for (final Match match in combinedRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        tokens.add(TextToken(
          text: text.substring(lastMatchEnd, match.start),
          type: TextTokenType.plain,
          value: '',
        ));
      }

      final String matchedText = match.group(0)!;
      if (matchedText.startsWith('@')) {
        tokens.add(TextToken(
          text: matchedText,
          type: TextTokenType.mention,
          value: matchedText.substring(1),
        ));
      } else if (matchedText.startsWith('#')) {
        tokens.add(TextToken(
          text: matchedText,
          type: TextTokenType.hashtag,
          value: matchedText.substring(1),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      tokens.add(TextToken(
        text: text.substring(lastMatchEnd),
        type: TextTokenType.plain,
        value: '',
      ));
    }

    return tokens;
  }

  /// Extracts all unique hashtags from text.
  static List<String> extractHashtags(String text) {
    return hashtagRegex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }

  /// Extracts all unique mentioned usernames from text.
  static List<String> extractMentions(String text) {
    return mentionRegex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }
}
