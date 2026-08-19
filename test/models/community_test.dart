import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/community.dart';

void main() {
  group('Community Model Tests', () {
    test('fromJson parses correctly with all values', () {
      final json = {
        'id': 'comm1',
        'name': 'Flutter Devs',
        'handle': 'flutter_devs',
        'topic': 'Programming',
        'description': 'A community for Flutter developers',
        'avatar_url': 'http://avatar.png',
        'banner_url': 'http://banner.png',
        'privacy': 'private',
        'owner_id': 'owner123',
        'member_count': 42,
        'is_verified': true,
        'created_at': '2025-08-12T10:30:00Z',
      };

      final community = Community.fromJson(json, myRole: 'moderator');

      expect(community.id, equals('comm1'));
      expect(community.name, equals('Flutter Devs'));
      expect(community.handle, equals('flutter_devs'));
      expect(community.topic, equals('Programming'));
      expect(community.description, equals('A community for Flutter developers'));
      expect(community.avatarUrl, equals('http://avatar.png'));
      expect(community.bannerUrl, equals('http://banner.png'));
      expect(community.privacy, equals('private'));
      expect(community.ownerId, equals('owner123'));
      expect(community.memberCount, equals(42));
      expect(community.isVerified, isTrue);
      expect(community.createdAt, equals('2025-08-12T10:30:00Z'));
      expect(community.myRole, equals('moderator'));
    });

    test('fromJson handles missing fields with default values', () {
      final json = {
        'id': 'comm2',
        'name': 'Gophers',
        'owner_id': 'owner456',
        'created_at': '2025-08-12T11:00:00Z',
      };

      final community = Community.fromJson(json);

      expect(community.privacy, equals('public'));
      expect(community.memberCount, equals(1));
      expect(community.isVerified, isFalse);
      expect(community.myRole, isNull);
    });

    test('toJson serializes correctly', () {
      final community = Community(
        id: 'comm3',
        name: 'Rustaceans',
        ownerId: 'owner789',
        createdAt: '2025-08-12T12:00:00Z',
        memberCount: 15,
        isVerified: true,
      );

      final json = community.toJson();

      expect(json['id'], equals('comm3'));
      expect(json['name'], equals('Rustaceans'));
      expect(json['owner_id'], equals('owner789'));
      expect(json['created_at'], equals('2025-08-12T12:00:00Z'));
      expect(json['member_count'], equals(15));
      expect(json['is_verified'], isTrue);
      expect(json['privacy'], equals('public'));
    });

    test('copyWith updates fields correctly', () {
      final community = Community(
        id: 'comm4',
        name: 'Kotlin Devs',
        ownerId: 'owner999',
        createdAt: '2025-08-12T13:00:00Z',
      );

      final updated = community.copyWith(memberCount: 200, isVerified: true, myRole: 'owner');

      expect(updated.name, equals('Kotlin Devs'));
      expect(updated.memberCount, equals(200));
      expect(updated.isVerified, isTrue);
      expect(updated.myRole, equals('owner'));
    });
  });
}
