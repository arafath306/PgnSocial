import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dak/core/security/e2ee_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class FakeUser implements sb.User {
  final String _id;
  FakeUser(this._id);
  @override
  String get id => _id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoTrueClient implements sb.GoTrueClient {
  @override
  sb.User? currentUser;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #currentUser) return currentUser;
    return super.noSuchMethod(invocation);
  }
}

class FakeSupabaseClient implements sb.SupabaseClient {
  final FakeGoTrueClient _auth = FakeGoTrueClient();
  @override
  FakeGoTrueClient get auth => _auth;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2EEService Safety Number & Media Encryption', () {
    test('Safety Number is identical regardless of key order (symmetric)', () {
      const keyAlice = 'alice_public_key_abc123==';
      const keyBob = 'bob_public_key_xyz789==';

      final sn1 = E2EEService.computeSafetyNumber(keyAlice, keyBob);
      final sn2 = E2EEService.computeSafetyNumber(keyBob, keyAlice);

      expect(sn1.isNotEmpty, isTrue);
      expect(sn1, equals(sn2));
      // Verify standard 12 chunks of 5 digits separated by spaces
      final parts = sn1.split(' ');
      expect(parts.length, equals(12));
      for (final chunk in parts) {
        expect(chunk.length, equals(5));
        expect(int.tryParse(chunk), isNotNull);
      }
    });

    test('Zero-knowledge media encryption and decryption round-trip', () async {
      final clientAlice = FakeSupabaseClient();
      clientAlice.auth.currentUser = FakeUser('user-alice-111');
      final aliceService = E2EEService(clientAlice);
      final aliceKey = await aliceService.initializeKeys();
      expect(aliceKey, isNotNull);

      final clientBob = FakeSupabaseClient();
      clientBob.auth.currentUser = FakeUser('user-bob-222');
      final bobService = E2EEService(clientBob);
      final bobKey = await bobService.initializeKeys();
      expect(bobKey, isNotNull);

      final originalData = Uint8List.fromList(utf8.encode('Top-secret high resolution image bytes 1234567890!'));

      // Alice encrypts for Bob
      final encryptedPacket = await aliceService.encryptMediaBytes(originalData, bobKey!);
      expect(encryptedPacket, isNotNull);
      expect(encryptedPacket, isNot(equals(originalData)));

      // Bob decrypts from Alice
      final decryptedData = await bobService.decryptMediaBytes(encryptedPacket!, aliceKey!);
      expect(decryptedData, isNotNull);
      expect(decryptedData, equals(originalData));
      expect(utf8.decode(decryptedData!), equals('Top-secret high resolution image bytes 1234567890!'));
    });
  });
}
