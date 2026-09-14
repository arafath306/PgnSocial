---
name: pigeon-media
description: Use when implementing or modifying Pigeon's image/video picking, compression, upload to Supabase Storage, display with caching, photo editing, or media handling in posts and messages.
---

# Pigeon Media

## Use this skill when

- modifying image picking (gallery or camera)
- modifying video picking or recording
- changing image compression
- changing upload to Supabase Storage
- modifying photo editor integration
- changing media display (CachedNetworkImage)
- handling media in create thread / post
- handling media in chat messages
- modifying full-screen media viewer
- changing avatar or profile picture upload

## Do not use this skill when

- working on non-media UI components
- changing Supabase RLS unrelated to storage
- working on text-only posts

---

## Pigeon Media Stack

- **image_picker** — gallery and camera image/video picking
- **camera** — direct camera control
- **flutter_image_compress** — image compression (via `MediaCompressor`)
- **image_cropper** — crop before upload
- **pro_image_editor** — full photo editing (`SharedPhotoEditorScreen`)
- **cached_network_image** — network image display with caching
- **video_player** — video playback
- **gal** — save to device gallery
- **Supabase Storage** — ALL media stored in `avatars` bucket

---

## Storage Bucket Convention

⚠️ All media uses a single `avatars` bucket (NOT separate buckets):

| Media Type | Path Pattern |
|-----------|--------------|
| Post images | `posts/{userId}/thread_{timestamp}.jpg` |
| Profile avatar | `{userId}/avatar_{timestamp}.jpg` |
| Profile cover | `{userId}/cover_{timestamp}.jpg` |
| Chat media | `{userId}/chat_{timestamp}.{ext}` |
| Voice posts | `voice_posts/{userId}/voice_{timestamp}.{ext}` |

When adding new media types, follow the same `avatars` bucket convention with a descriptive subfolder.

---

## Image Compression: MediaCompressor

All images go through `MediaCompressor` before upload:

```dart
// In storage_ext.dart
final compressedBytes = await MediaCompressor.compressImageBytes(bytes);

// In chat_remote_data_source.dart
if (contentType.startsWith('image/')) {
  uploadBytes = await MediaCompressor.compressImageBytes(bytes);
}
```

**Always** call `MediaCompressor.compressImageBytes()` before uploading — never upload raw bytes directly.

---

## Image Picking

Always use `imageQuality: 80` for initial pick quality:

```dart
// Gallery
final images = await picker.pickMultiImage(imageQuality: 80);

// Camera
final image = await picker.pickImage(
  source: ImageSource.camera,
  imageQuality: 80,
);
```

**Two byte arrays must be maintained:**
- `_selectedImagesBytesList` — current bytes (may be edited)
- `_originalImagesBytesList` — original unedited bytes (for re-editing)

Never overwrite `_originalImagesBytesList` with edited bytes.

---

## Uploading Post Images

**Actual implementation in `storage_ext.dart`:**

```dart
Future<String?> uploadPostImage(Uint8List bytes) async {
  if (_currentUid.isEmpty) return null;
  final compressedBytes = await MediaCompressor.compressImageBytes(bytes);
  final path = 'posts/$_currentUid/thread_${DateTime.now().millisecondsSinceEpoch}.jpg';
  return await _uploadToStorage('avatars', path, compressedBytes);
}
```

Upload uses `upsert: true` and `contentType: 'image/jpeg'`.

Returns the **public URL** from Supabase storage.

---

## Uploading Voice Posts

```dart
Future<String?> uploadPostAudio(Uint8List bytes, String extension) async {
  final path = 'voice_posts/$_currentUid/voice_${DateTime.now().millisecondsSinceEpoch}.$extension';
  return await _uploadToStorage('avatars', path, bytes);
}
```

Voice posts are NOT compressed — raw bytes are uploaded.

---

## Photo Editor Flow

Pigeon uses `SharedPhotoEditorScreen` (backed by `pro_image_editor`):

```dart
// 1. Write bytes to temp file
final dir = await getTemporaryDirectory();
final tempFile = File('${dir.path}/temp_original_${DateTime.now().millisecondsSinceEpoch}.jpg');
await tempFile.writeAsBytes(originalBytes);

if (!mounted) return;

// 2. Navigate to editor
final editedFile = await Navigator.push<XFile?>(
  context,
  MaterialPageRoute(
    builder: (context) => SharedPhotoEditorScreen(imageFile: tempFile),
  ),
);

// 3. Read edited bytes
if (editedFile != null) {
  final editedBytes = await editedFile.readAsBytes();
  if (mounted) {
    setState(() {
      _selectedImagesBytesList[index] = editedBytes;
      // DO NOT update _originalImagesBytesList
    });
  }
}
```

**Rules:**
- Always check `if (!mounted) return;` before and after async gaps
- Only replace `_selectedImagesBytesList[index]`, not `_originalImagesBytesList[index]`

---

## Chat Media Upload

**Actual implementation in `chat_remote_data_source.dart`:**

```dart
Future<String?> uploadChatMedia(String currentUserId, Uint8List bytes, {
  String extension = 'jpg',
  String contentType = 'image/jpeg',
}) async {
  Uint8List uploadBytes = bytes;
  if (contentType.startsWith('image/')) {
    uploadBytes = await MediaCompressor.compressImageBytes(bytes);
  }
  final path = '$currentUserId/chat_${DateTime.now().millisecondsSinceEpoch}.$extension';
  await supabaseClient.storage.from('avatars').uploadBinary(path, uploadBytes, ...);
  final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
  return publicUrl;
}
```

⚠️ Chat media is stored with a **public URL** in the `avatars` bucket. If you need truly private chat media, this needs a private bucket + signed URLs.

---

## Media Display

Always use `CachedNetworkImage` — never `Image.network`:

```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const ShimmerWidget(),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
  fit: BoxFit.cover,
)
```

**Rules:**
- Always provide `placeholder` (shimmer preferred)
- Always provide `errorWidget`
- `fit: BoxFit.cover` for feed cards
- `fit: BoxFit.contain` for full-screen viewer

---

## Local SQLite Cache for Chat Messages

Chat messages are locally cached using `sqflite`:

**File:** `lib/features/chat/data/datasources/local_chat_db.dart`  
**DB:** `chat_messages.db` (version 3)

Schema:
```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  sender_id TEXT, receiver_id TEXT,
  text TEXT,            -- stores decrypted text
  time TEXT, created_at TEXT,
  media_url TEXT, media_type TEXT,
  is_read INTEGER,
  reply_to_id TEXT, reply_to_text TEXT, reply_to_sender TEXT,
  room_id TEXT,
  reactions TEXT,       -- JSON encoded Map<String, String>
  is_pinned INTEGER DEFAULT 0,
  pinned_at TEXT
)
```

Room ID format: `{sortedId1}_{sortedId2}` (always sorted alphabetically).

Indexes: `idx_room_id`, `idx_created_at`.

⚠️ The local SQLite `text` field stores **decrypted** plaintext. The encryption/decryption happens at the remote datasource layer before caching.

---

## Saving Media to Device

Use `gal` package:

```dart
await Gal.putImageBytes(bytes);
await Gal.putVideo(filePath);
```

Show confirmation to user after successful save. Handle permission denied gracefully.

---

## Video Handling

For video playback:
- Use `video_player` package
- Initialize controller before use
- **Always dispose** controller in `dispose()`
- For feed videos: pause when scrolled off-screen using `VisibilityDetector`
- Do NOT autoplay with sound
