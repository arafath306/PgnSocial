import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/poll_option.dart';

void main() {
  group('PollOption Model Tests', () {
    test('fromJson parses standard values correctly', () {
      final json = {
        'id': 'opt1',
        'thread_id': 'thread1',
        'option_text': 'Option A',
        'votes_count': 10,
        'image_url': 'http://image.png',
      };

      final option = PollOption.fromJson(json);

      expect(option.id, equals('opt1'));
      expect(option.threadId, equals('thread1'));
      expect(option.optionText, equals('Option A'));
      expect(option.votesCount, equals(10));
      expect(option.imageUrl, equals('http://image.png'));
    });

    test('fromJson handles null votes_count with default 0', () {
      final json = {
        'id': 'opt2',
        'option_text': 'Option B',
        'votes_count': null,
      };

      final option = PollOption.fromJson(json);

      expect(option.votesCount, equals(0));
    });

    test('fromJson handles rawText containing |DakOptionImg| custom suffix format', () {
      final json = {
        'id': 'opt3',
        'option_text': 'Option C|DakOptionImg|http://suffix-image.png',
        'image_url': null,
      };

      final option = PollOption.fromJson(json);

      expect(option.optionText, equals('Option C'));
      expect(option.imageUrl, equals('http://suffix-image.png'));
    });

    test('fromJson calculates votes dynamically when votesList is supplied', () {
      final json = {
        'id': 'opt4',
        'option_text': 'Option D',
        'votes_count': 10,
      };
      final votesList = [
        {'poll_option_id': 'opt4'},
        {'poll_option_id': 'opt4'},
        {'poll_option_id': 'other_opt'},
      ];

      final option = PollOption.fromJson(json, votesList: votesList);

      expect(option.votesCount, equals(2)); // matches 2 votes
    });

    test('toJson serializes standard properties and formats textToSave', () {
      final option = PollOption(
        id: 'opt5',
        threadId: 'thread5',
        optionText: 'Option E',
        votesCount: 3,
        imageUrl: 'http://image5.png',
      );

      final json = option.toJson();

      expect(json['id'], equals('opt5'));
      expect(json['thread_id'], equals('thread5'));
      expect(json['image_url'], equals('http://image5.png'));
      expect(json['votes_count'], equals(3));
      expect(json['option_text'], equals('Option E|DakOptionImg|http://image5.png'));
    });

    test('copyWith updates fields correctly', () {
      final option = PollOption(
        id: 'opt6',
        threadId: 'thread6',
        optionText: 'Option F',
        votesCount: 0,
      );

      final updated = option.copyWith(votesCount: 5, imageUrl: 'http://image6.png');

      expect(updated.id, equals('opt6'));
      expect(updated.votesCount, equals(5));
      expect(updated.imageUrl, equals('http://image6.png'));
    });
  });
}
