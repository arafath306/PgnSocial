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
    if (invocation.memberName == #currentUser) {
      return currentUser;
    }
    return super.noSuchMethod(invocation);
  }
}

class MockPostgrestFilterBuilder {
  final Map<String, dynamic>? val;
  MockPostgrestFilterBuilder(this.val);

  MockPostgrestFilterBuilder eq(String column, Object? value) => this;

  Future<Map<String, dynamic>?> maybeSingle() async => val;
}

class MockPostgrestQueryBuilder {
  final Map<String, dynamic>? selectResult;
  MockPostgrestQueryBuilder({this.selectResult});

  MockPostgrestFilterBuilder select([String? columns]) {
    return MockPostgrestFilterBuilder(selectResult);
  }

  MockPostgrestFilterBuilder update(Map<dynamic, dynamic> values) {
    return MockPostgrestFilterBuilder(null);
  }
}

class FakeSupabaseClient implements sb.SupabaseClient {
  final FakeGoTrueClient _auth = FakeGoTrueClient();
  Map<String, dynamic>? profileResult;

  @override
  FakeGoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      return MockPostgrestQueryBuilder(selectResult: profileResult);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('E2EEService Deterministic Key & Cryptographic Tests', () {
    late FakeSupabaseClient fakeSupabase;

    setUp(() {
      fakeSupabase = FakeSupabaseClient();
    });

    test('initializeKeys generates identical deterministic public keys for same UID', () async {
      fakeSupabase.auth.currentUser = FakeUser('alice_uid_123');

      // First initialization of Alice
      final service1 = E2EEService(fakeSupabase);
      final pubKey1 = await service1.initializeKeys();

      // Second initialization of Alice
      final service2 = E2EEService(fakeSupabase);
      final pubKey2 = await service2.initializeKeys();

      expect(pubKey1, isNotNull);
      expect(pubKey1, equals(pubKey2)); // Determinism check
    });

    test('initializeKeys generates different public keys for different UIDs', () async {
      // Alice Key Gen
      fakeSupabase.auth.currentUser = FakeUser('alice_uid');
      final aliceService = E2EEService(fakeSupabase);
      final alicePubKey = await aliceService.initializeKeys();

      // Bob Key Gen
      fakeSupabase.auth.currentUser = FakeUser('bob_uid');
      final bobService = E2EEService(fakeSupabase);
      final bobPubKey = await bobService.initializeKeys();

      expect(alicePubKey, isNotNull);
      expect(bobPubKey, isNotNull);
      expect(alicePubKey, isNot(equals(bobPubKey)));
    });

    test('encryptMessage and decryptMessage successfully performs full end-to-end cryptographic flow', () async {
      // Setup Alice
      fakeSupabase.auth.currentUser = FakeUser('alice_uid');
      final aliceService = E2EEService(fakeSupabase);
      final alicePubKey = await aliceService.initializeKeys();

      // Setup Bob
      fakeSupabase.auth.currentUser = FakeUser('bob_uid');
      final bobService = E2EEService(fakeSupabase);
      final bobPubKey = await bobService.initializeKeys();

      // Alice encrypts for Bob
      fakeSupabase.auth.currentUser = FakeUser('alice_uid');
      final plainText = 'Top Secret Message 🤫';
      final encryptedResult = await aliceService.encryptMessage(plainText, bobPubKey!);

      expect(encryptedResult, isNotNull);
      expect(encryptedResult!.cipherTextBase64, isNotEmpty);
      expect(encryptedResult.nonceBase64, isNotEmpty);
      expect(encryptedResult.macBase64, isNotEmpty);

      // Bob decrypts Alice's message
      fakeSupabase.auth.currentUser = FakeUser('bob_uid');
      final decryptedText = await bobService.decryptMessage(
        encryptedResult.cipherTextBase64,
        encryptedResult.nonceBase64,
        encryptedResult.macBase64,
        alicePubKey!,
      );

      expect(decryptedText, equals(plainText));
    });

    test('decryptMessage returns null when wrong public key is used', () async {
      // Setup Alice
      fakeSupabase.auth.currentUser = FakeUser('alice_uid');
      final aliceService = E2EEService(fakeSupabase);
      final alicePubKey = await aliceService.initializeKeys();

      // Setup Bob
      fakeSupabase.auth.currentUser = FakeUser('bob_uid');
      final bobService = E2EEService(fakeSupabase);
      final bobPubKey = await bobService.initializeKeys();

      // Setup Eve (intruder)
      fakeSupabase.auth.currentUser = FakeUser('eve_uid');
      final eveService = E2EEService(fakeSupabase);
      await eveService.initializeKeys();

      // Alice encrypts for Bob
      fakeSupabase.auth.currentUser = FakeUser('alice_uid');
      final encryptedResult = await aliceService.encryptMessage('Hello Bob', bobPubKey!);

      // Eve attempts to decrypt Alice's message using Eve's keys
      fakeSupabase.auth.currentUser = FakeUser('eve_uid');
      final decryptedText = await eveService.decryptMessage(
        encryptedResult!.cipherTextBase64,
        encryptedResult.nonceBase64,
        encryptedResult.macBase64,
        alicePubKey!,
      );

      expect(decryptedText, isNull); // Eve shouldn't be able to decrypt it
    });
  });
}
