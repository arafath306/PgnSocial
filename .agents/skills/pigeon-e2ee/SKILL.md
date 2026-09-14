---
name: pigeon-e2ee
description: Use when implementing, modifying, debugging, or reviewing Pigeon's end-to-end encrypted private messaging and cryptographic key handling.
---

# Pigeon E2EE

## Use this skill when

- modifying encrypted messaging
- modifying key exchange or key derivation
- changing message encryption or decryption
- changing key storage
- debugging encrypted chat
- reviewing E2EE security
- modifying `E2EEService` or `ChatRemoteDataSource`

## Do not use this skill when

- working on public posts
- working on non-sensitive UI
- changing unrelated database features

---

## Pigeon E2EE Stack (Actual Implementation)

**File:** `lib/core/security/e2ee_service.dart`  
**Used by:** `lib/features/chat/data/datasources/chat_remote_data_source.dart`

- **Key Exchange:** X25519 (via `cryptography` package)
- **Encryption:** AES-256-GCM (`AesGcm.with256bits()`)
- **Key Derivation:** HKDF-SHA256 (`Hkdf(hmac: Hmac.sha256(), outputLength: 32)`)
- **Key Storage:** `flutter_secure_storage` + in-memory cache
- **Public Key Storage:** `profiles.public_key` column in Supabase

---

## Key Design: Deterministic Keys

**CRITICAL:** Pigeon uses **deterministic key derivation** from user UID, NOT random keys.

```dart
// App-level salt — এটা পরিবর্তন করবেন না
static const String _appSalt = 'dak_e2ee_v1_2025_stable_key';

// UID → seed → X25519 key pair
Future<List<int>> _deriveStableSeed(String uid) async {
  final inputKeyMaterial = SecretKey(utf8.encode(uid));
  final derivedKey = await _hkdf.deriveKey(
    secretKey: inputKeyMaterial,
    nonce: utf8.encode(_appSalt),
    info: utf8.encode('dak_e2ee_x25519_private_key'),
  );
  return await derivedKey.extractBytes();
}
```

**Why deterministic:** Same UID always produces same key pair → messages remain decryptable across reinstalls and new devices without key backup.

**⚠️ NEVER change `_appSalt`** — changing it will make ALL existing messages permanently undecryptable.

---

## Encrypted Message Format

Messages stored in Supabase `messages.content` use this format:

```
E2EE:v1:{nonceBase64}:{macBase64}:{cipherTextBase64}
```

Example:
```
E2EE:v1:abc123==:xyz789==:encryptedPayload==
```

When decrypting, check if message starts with `E2EE:v1:` before attempting decryption.

Plain text messages (from before E2EE was enabled or if encryption failed) do NOT have this prefix.

---

## Encryption Flow

```
Sender:
1. Fetch receiver's public_key from profiles (cached in _publicKeyCache)
2. Derive shared secret: X25519(my_private_key, receiver_public_key)
3. Encrypt with AES-256-GCM: generates cipherText + nonce + mac
4. Format: "E2EE:v1:{nonce}:{mac}:{cipherText}"
5. Store formatted string in messages.content
```

```
Receiver:
1. Read messages.content from Supabase
2. Check if starts with "E2EE:v1:"
3. Parse: split by ":" → [prefix, version, nonce, mac, cipherText]
4. Derive shared secret: X25519(my_private_key, sender_public_key)
5. Decrypt with AES-256-GCM using nonce + mac + cipherText
6. Return decrypted UTF-8 string
```

---

## Key Caches

`E2EEService` maintains three in-memory caches:

| Cache | Type | Purpose |
|-------|------|---------|
| `_sharedSecretCache` | `Map<String, SecretKey>` | Derived shared secrets per contact public key |
| `_mySeedCache` | `List<int>?` | My HKDF seed |
| `_myKeyPairCache` | `SimpleKeyPair?` | My X25519 key pair |

**Rules:**
- Caches are populated lazily on first use
- Caches are cleared on `clearKeys()` (logout)
- Never persist shared secrets to disk — only derive in memory

---

## Public Key Management

Public keys are stored in `profiles.public_key` (Base64 encoded X25519 public key).

`initializeKeys()` must be called after login:
1. Derives seed from UID
2. Generates X25519 key pair from seed
3. Extracts public key
4. Syncs public key to `profiles.public_key` if changed
5. Stores seed in `flutter_secure_storage` as cache

`flutter_secure_storage` failure is non-fatal — key is always rederivable from UID.

---

## Chat Media Encryption

Chat media is uploaded to the `avatars` bucket (NOT encrypted at rest):

```
Path: {currentUserId}/chat_{timestamp}.{extension}
```

⚠️ Chat media is currently stored in the public `avatars` bucket with a public URL. This means chat media is accessible by URL without authentication. Consider using private bucket + signed URLs for sensitive media.

---

## Fallback Behavior

If encryption fails (e.g., receiver has no public key), content is sent as **plain text**:

```dart
} catch (e) {
  debugPrint('Encryption failed: $e');
}
return content; // Fallback to plain text
```

**This is a known design choice** — do not remove the fallback without implementing proper error handling and UX feedback for the user.

---

## `clearKeys()` — Logout

On logout, call `clearKeys()`:
- Clears `_sharedSecretCache`
- Clears `_mySeedCache`
- Clears `_myKeyPairCache`
- Deletes seed from `flutter_secure_storage`

Keys are rederivable from UID on next login.

---

## Critical Rules

**Never log:**
- Plaintext message content
- Encryption keys, seeds, or nonces
- Shared secrets
- Decrypted message content

**Never:**
- Change `_appSalt` — this breaks all existing messages permanently
- Reuse a nonce — AES-GCM nonces must be unique per encryption
- Store shared secrets on disk
- Skip decryption failure handling
- Fall back to plaintext without logging it as a warning

**Always:**
- Parse `E2EE:v1:` prefix before attempting decryption
- Handle `null` return from `encryptMessage()` / `decryptMessage()` gracefully
- Call `initializeKeys()` after login and before any message send

---

## Realtime Message Stream

Messages use Supabase Realtime (`PostgresChanges`) scoped to `messages` table filtered by `receiver_id` and `sender_id`.

Channel name format: `messages_realtime:{otherUserId}`

The stream is implemented in `getMessagesRealtimeStream()` in `ChatRemoteDataSource`.

---

## Typing Indicator

Typing indicators use Supabase Broadcast (not database).

Channel name format: `typing_{sortedId1}_{sortedId2}` (sorted to be symmetric).

Typing events are ephemeral — not stored in database.