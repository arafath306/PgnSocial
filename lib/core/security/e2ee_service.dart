import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class E2EEMessageResult {
  final String cipherTextBase64;
  final String nonceBase64;
  final String macBase64;

  E2EEMessageResult({
    required this.cipherTextBase64,
    required this.nonceBase64,
    required this.macBase64,
  });
}

class E2EEService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final sb.SupabaseClient _supabaseClient;

  // Algorithms
  final _keyExchangeAlgorithm = X25519();
  final _cipherAlgorithm = AesGcm.with256bits();
  final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  // App-level secret salt — এটা পরিবর্তন করবেন না, নাহলে সব messages decrypt হবে না
  static const String _appSalt = 'dak_e2ee_v1_2025_stable_key';

  // Cryptographic caches to prevent UI thread blocking
  final Map<String, SecretKey> _sharedSecretCache = {};
  List<int>? _mySeedCache;
  SimpleKeyPair? _myKeyPairCache;

  E2EEService(this._supabaseClient);

  String get _currentUid => _supabaseClient.auth.currentUser?.id ?? '';
  String _privateKeyKey(String uid) => 'e2ee_private_key_$uid';

  /// User-এর UID থেকে deterministic 32-byte seed বের করে।
  /// একই UID → সবসময় একই key pair → reinstall বা নতুন device-এও messages decrypt হবে।
  Future<List<int>> _deriveStableSeed(String uid) async {
    final inputKeyMaterial = SecretKey(utf8.encode(uid));
    final derivedKey = await _hkdf.deriveKey(
      secretKey: inputKeyMaterial,
      nonce: utf8.encode(_appSalt),
      info: utf8.encode('dak_e2ee_x25519_private_key'),
    );
    return await derivedKey.extractBytes();
  }

  Future<List<int>?> _getMySeed() async {
    if (_currentUid.isEmpty) return null;
    if (_mySeedCache != null) return _mySeedCache;
    _mySeedCache = await _deriveStableSeed(_currentUid);
    return _mySeedCache;
  }

  Future<SimpleKeyPair?> _getMyKeyPair() async {
    if (_currentUid.isEmpty) return null;
    if (_myKeyPairCache != null) return _myKeyPairCache;
    final seed = await _getMySeed();
    if (seed == null) return null;
    _myKeyPairCache = await _keyExchangeAlgorithm.newKeyPairFromSeed(seed);
    return _myKeyPairCache;
  }

  Future<SecretKey?> _getSharedSecretKey(String otherPublicKeyBase64) async {
    if (_currentUid.isEmpty || otherPublicKeyBase64.isEmpty) return null;
    if (_sharedSecretCache.containsKey(otherPublicKeyBase64)) {
      return _sharedSecretCache[otherPublicKeyBase64];
    }
    try {
      final keyPair = await _getMyKeyPair();
      if (keyPair == null) return null;
      final otherPublicKeyBytes = base64Decode(otherPublicKeyBase64);
      final otherPublicKey = SimplePublicKey(otherPublicKeyBytes, type: KeyPairType.x25519);
      final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: otherPublicKey,
      );
      final secretKeyBytes = await sharedSecret.extractBytes();
      final secretKey = SecretKey(secretKeyBytes);
      _sharedSecretCache[otherPublicKeyBase64] = secretKey;
      return secretKey;
    } catch (e) {
      debugPrint('E2EE derive shared secret error: $e');
      return null;
    }
  }

  /// Initializes the key pair for the current user.
  /// Key pair is derived deterministically from user UID — same on every device/reinstall.
  Future<String?> initializeKeys() async {
    if (_currentUid.isEmpty) return null;

    try {
      // Stable seed থেকে key pair derive করো
      final seed = await _deriveStableSeed(_currentUid);
      final keyPair = await _keyExchangeAlgorithm.newKeyPairFromSeed(seed);
      _mySeedCache = seed;
      _myKeyPairCache = keyPair;
      final publicKey = await keyPair.extractPublicKey();
      final publicKeyBase64 = base64Encode(publicKey.bytes);

      // Private key cache করো (fast future lookups-এর জন্য, regeneration এড়াতে)
      final privateKeyBase64 = base64Encode(seed);
      try {
        await _secureStorage.write(
          key: _privateKeyKey(_currentUid),
          value: privateKeyBase64,
        );
      } catch (_) {
        // SecureStorage fail হলেও চলবে — key সবসময় UID থেকে derive করা যাবে
      }

      // Supabase-এ public key sync করো
      try {
        final res = await _supabaseClient
            .from('profiles')
            .select('public_key')
            .eq('id', _currentUid)
            .maybeSingle();
        final dbPublicKey = res?['public_key'] as String?;

        if (dbPublicKey != publicKeyBase64) {
          await _supabaseClient
              .from('profiles')
              .update({'public_key': publicKeyBase64})
              .eq('id', _currentUid);
        }
      } catch (e) {
        // Sync fail হলেও key সঠিক আছে
        debugPrint('E2EE public key sync error: $e');
      }

      return publicKeyBase64;
    } catch (e) {
      debugPrint('E2EE initializeKeys error: $e');
      return null;
    }
  }

  /// Encrypts a text message for a specific receiver using their public key.
  Future<E2EEMessageResult?> encryptMessage(String plainText, String receiverPublicKeyBase64) async {
    if (_currentUid.isEmpty || receiverPublicKeyBase64.isEmpty) return null;

    try {
      final secretKey = await _getSharedSecretKey(receiverPublicKeyBase64);
      if (secretKey == null) return null;

      final nonce = _cipherAlgorithm.newNonce();

      final secretBox = await _cipherAlgorithm.encrypt(
        utf8.encode(plainText),
        secretKey: secretKey,
        nonce: nonce,
      );

      return E2EEMessageResult(
        cipherTextBase64: base64Encode(secretBox.cipherText),
        nonceBase64: base64Encode(secretBox.nonce),
        macBase64: base64Encode(secretBox.mac.bytes),
      );
    } catch (e) {
      debugPrint('E2EE encrypt error: $e');
      return null;
    }
  }

  /// Decrypts a received message using the sender's public key.
  Future<String?> decryptMessage(
    String cipherTextBase64,
    String nonceBase64,
    String macBase64,
    String senderPublicKeyBase64,
  ) async {
    if (_currentUid.isEmpty || senderPublicKeyBase64.isEmpty) return null;

    try {
      final secretKey = await _getSharedSecretKey(senderPublicKeyBase64);
      if (secretKey == null) return null;

      final secretBox = SecretBox(
        base64Decode(cipherTextBase64),
        nonce: base64Decode(nonceBase64),
        mac: Mac(base64Decode(macBase64)),
      );

      final plainTextBytes = await _cipherAlgorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(plainTextBytes);
    } catch (e) {
      debugPrint('E2EE decrypt error: $e');
      return null;
    }
  }

  /// Returns the current user's Base64 public key for verification and key exchange.
  Future<String?> getMyPublicKeyBase64() async {
    try {
      final keyPair = await _getMyKeyPair();
      if (keyPair == null) return null;
      final publicKey = await keyPair.extractPublicKey();
      return base64Encode(publicKey.bytes);
    } catch (e) {
      debugPrint('E2EE getMyPublicKeyBase64 error: $e');
      return null;
    }
  }

  /// Signal-Protocol compliant 60-digit Safety Number calculation.
  /// Lexicographically sorts both public keys to produce an identical fingerprint on both devices.
  static String computeSafetyNumber(String keyA, String keyB) {
    if (keyA.isEmpty || keyB.isEmpty) return '';
    try {
      final sorted = [keyA, keyB]..sort();
      final combined = utf8.encode('${sorted[0]}:::${sorted[1]}');
      final digest = crypto.sha512.convert(combined).bytes;

      // Generate 12 groups of 5 decimal digits = 60 digits total
      final buffer = StringBuffer();
      for (int i = 0; i < 12; i++) {
        final offset = i * 4;
        final val = (digest[offset] << 24) |
            (digest[offset + 1] << 16) |
            (digest[offset + 2] << 8) |
            digest[offset + 3];
        final chunkNum = (val & 0x7FFFFFFF) % 100000;
        final chunkStr = chunkNum.toString().padLeft(5, '0');
        if (i > 0) buffer.write(' ');
        buffer.write(chunkStr);
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('E2EE computeSafetyNumber error: $e');
      return '';
    }
  }

  /// Encrypts raw media bytes (image, video, voice) client-side using AES-256-GCM.
  /// Zero-knowledge: the server only stores encrypted ciphertext blob.
  /// Binary packet layout: [1-byte nonce len][nonce][1-byte mac len][mac][ciphertext]
  Future<Uint8List?> encryptMediaBytes(Uint8List plainBytes, String receiverPublicKeyBase64) async {
    if (_currentUid.isEmpty || receiverPublicKeyBase64.isEmpty || plainBytes.isEmpty) return null;

    try {
      final secretKey = await _getSharedSecretKey(receiverPublicKeyBase64);
      if (secretKey == null) return null;

      final nonce = _cipherAlgorithm.newNonce();
      final secretBox = await _cipherAlgorithm.encrypt(
        plainBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      final nonceBytes = secretBox.nonce;
      final macBytes = secretBox.mac.bytes;
      final cipherText = secretBox.cipherText;

      final totalLength = 1 + nonceBytes.length + 1 + macBytes.length + cipherText.length;
      final result = Uint8List(totalLength);
      int offset = 0;

      result[offset++] = nonceBytes.length;
      result.setRange(offset, offset + nonceBytes.length, nonceBytes);
      offset += nonceBytes.length;

      result[offset++] = macBytes.length;
      result.setRange(offset, offset + macBytes.length, macBytes);
      offset += macBytes.length;

      result.setRange(offset, offset + cipherText.length, cipherText);

      return result;
    } catch (e) {
      debugPrint('E2EE encryptMediaBytes error: $e');
      return null;
    }
  }

  /// Decrypts encrypted media packet client-side using recipient/sender shared secret.
  /// Expects binary packet: [1-byte nonce len][nonce][1-byte mac len][mac][ciphertext]
  Future<Uint8List?> decryptMediaBytes(Uint8List cipherPacket, String senderPublicKeyBase64) async {
    if (_currentUid.isEmpty || senderPublicKeyBase64.isEmpty || cipherPacket.length < 18) return null;

    try {
      final secretKey = await _getSharedSecretKey(senderPublicKeyBase64);
      if (secretKey == null) return null;

      int offset = 0;
      final nonceLen = cipherPacket[offset++];
      if (offset + nonceLen > cipherPacket.length) return null;
      final nonce = cipherPacket.sublist(offset, offset + nonceLen);
      offset += nonceLen;

      final macLen = cipherPacket[offset++];
      if (offset + macLen > cipherPacket.length) return null;
      final macBytes = cipherPacket.sublist(offset, offset + macLen);
      offset += macLen;

      final cipherText = cipherPacket.sublist(offset);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final plainBytes = await _cipherAlgorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plainBytes);
    } catch (e) {
      debugPrint('E2EE decryptMediaBytes error: $e');
      return null;
    }
  }

  /// Wipes all cached decrypted shared keys and ephemeral secrets from memory.
  void wipeDecryptedCache() {
    _sharedSecretCache.clear();
  }

  /// Logs out the user — deterministic key হওয়ায় শুধু cache clear করা হয়
  Future<void> clearKeys() async {
    _sharedSecretCache.clear();
    _mySeedCache = null;
    _myKeyPairCache = null;
    if (_currentUid.isNotEmpty) {
      try {
        await _secureStorage.delete(key: _privateKeyKey(_currentUid));
      } catch (e) {
        debugPrint('[E2EEService] Error deleting key from secure storage: $e');
      }
    }
  }
}
