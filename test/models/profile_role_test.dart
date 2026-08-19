import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/profile.dart';

void main() {
  group('Profile Model Role Tests', () {
    test('fromJson parses role field correctly', () {
      final json = {
        'id': 'user123',
        'username': 'admin_user',
        'full_name': 'Administrator',
        'role': 'Admin',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, equals('user123'));
      expect(profile.username, equals('admin_user'));
      expect(profile.fullName, equals('Administrator'));
      expect(profile.role, equals('Admin'));
    });

    test('fromJson handles null role field gracefully', () {
      final json = {
        'id': 'user456',
        'username': 'normal_user',
        'full_name': 'Normal User',
        'role': null,
      };

      final profile = Profile.fromJson(json);

      expect(profile.role, isNull);
    });

    test('toJson serializes role field correctly', () {
      final profile = Profile(
        id: 'user123',
        username: 'admin_user',
        fullName: 'Administrator',
        role: 'Admin',
      );

      final json = profile.toJson();

      expect(json['id'], equals('user123'));
      expect(json['username'], equals('admin_user'));
      expect(json['full_name'], equals('Administrator'));
      expect(json['role'], equals('Admin'));
    });

    test('toJson omits role field if it is null', () {
      final profile = Profile(
        id: 'user456',
        username: 'normal_user',
        fullName: 'Normal User',
        role: null,
      );

      final json = profile.toJson();

      expect(json.containsKey('role'), isFalse);
    });
  });
}
