import 'package:flutter_test/flutter_test.dart';
import 'package:dak/utils/hashtag_mention_parser.dart';

void main() {
  group('HashtagMentionParser Tests', () {
    test('parse empty string returns empty list', () {
      final tokens = HashtagMentionParser.parse('');
      expect(tokens, isEmpty);
    });

    test('parse plain text returns single plain token', () {
      final tokens = HashtagMentionParser.parse('Hello world this is standard text');
      expect(tokens.length, equals(1));
      expect(tokens[0].type, equals(TextTokenType.plain));
      expect(tokens[0].text, equals('Hello world this is standard text'));
      expect(tokens[0].value, isEmpty);
    });

    test('parse single hashtag returns hashtag token', () {
      final tokens = HashtagMentionParser.parse('#Dak');
      expect(tokens.length, equals(1));
      expect(tokens[0].type, equals(TextTokenType.hashtag));
      expect(tokens[0].text, equals('#Dak'));
      expect(tokens[0].value, equals('Dak'));
    });

    test('parse single mention returns mention token', () {
      final tokens = HashtagMentionParser.parse('@arafath');
      expect(tokens.length, equals(1));
      expect(tokens[0].type, equals(TextTokenType.mention));
      expect(tokens[0].text, equals('@arafath'));
      expect(tokens[0].value, equals('arafath'));
    });

    test('parse text with mix of hashtags, mentions, and plain text', () {
      final tokens = HashtagMentionParser.parse('Hello @arafath, checkout #Dak app!');
      // Tokens:
      // 1. Plain: 'Hello '
      // 2. Mention: '@arafath'
      // 3. Plain: ', checkout '
      // 4. Hashtag: '#Dak'
      // 5. Plain: ' app!'
      expect(tokens.length, equals(5));
      
      expect(tokens[0].type, equals(TextTokenType.plain));
      expect(tokens[0].text, equals('Hello '));

      expect(tokens[1].type, equals(TextTokenType.mention));
      expect(tokens[1].text, equals('@arafath'));
      expect(tokens[1].value, equals('arafath'));

      expect(tokens[2].type, equals(TextTokenType.plain));
      expect(tokens[2].text, equals(', checkout '));

      expect(tokens[3].type, equals(TextTokenType.hashtag));
      expect(tokens[3].text, equals('#Dak'));
      expect(tokens[3].value, equals('Dak'));

      expect(tokens[4].type, equals(TextTokenType.plain));
      expect(tokens[4].text, equals(' app!'));
    });

    test('parse support Bangla unicode in hashtags and mentions', () {
      final tokens = HashtagMentionParser.parse('হ্যালো @আরাফাত এবং #ঘুড্ডি');
      expect(tokens.length, equals(4));

      expect(tokens[1].type, equals(TextTokenType.mention));
      expect(tokens[1].text, equals('@আরাফাত'));
      expect(tokens[1].value, equals('আরাফাত'));

      expect(tokens[3].type, equals(TextTokenType.hashtag));
      expect(tokens[3].text, equals('#ঘুড্ডি'));
      expect(tokens[3].value, equals('ঘুড্ডি'));
    });

    test('extractHashtags returns unique tags', () {
      final tags = HashtagMentionParser.extractHashtags('Love #flutter and #dart, #flutter is cool');
      expect(tags.length, equals(2));
      expect(tags, contains('flutter'));
      expect(tags, contains('dart'));
    });

    test('extractMentions returns unique usernames', () {
      final mentions = HashtagMentionParser.extractMentions('Hey @bob and @alice, is @bob here?');
      expect(mentions.length, equals(2));
      expect(mentions, contains('bob'));
      expect(mentions, contains('alice'));
    });
  });
}
