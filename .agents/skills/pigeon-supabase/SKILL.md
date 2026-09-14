---
name: pigeon-supabase
description: Use when working with Pigeon's Supabase backend, database schema, migrations, triggers, RPC functions, Realtime channels, Storage buckets, or RLS policies.
---

# Pigeon Supabase Backend

## Use this skill when

- writing or modifying Supabase database queries in Flutter
- creating or reviewing PostgreSQL schema migrations in `supabase/`
- inspecting or writing database triggers and stored functions (RPCs)
- managing Supabase Realtime subscriptions in Flutter services
- managing Supabase Storage uploads and bucket policies (`avatars` bucket)
- implementing or debugging Row Level Security (RLS) policies
- working with native Supabase Auth and the `profiles` synchronization trigger
- debugging backend data flows between Flutter, Edge Functions, and PostgreSQL

## Do not use this skill when

- making purely frontend UI layout changes
- working on local SQLite caching only (`local_chat_db.dart`)
- modifying pure client-side state in widgets

---

## Architecture & Client Access

Pigeon connects to Supabase via `supabase_flutter`.

- **Service Locator Registration**: `sl<SupabaseClient>()` (defined in `lib/core/injection.dart`)
- **Central Service**: `DatabaseService` (in `lib/services/database_service.dart`) holds the `_supabase` instance and delegates queries across modular `part` extensions in `lib/services/parts/`:
  - `feed_ext.dart` — Home feed, my threads, create thread, polls
  - `algorithmicfeed_ext.dart` — AI personalized feed RPC hydration
  - `likes_ext.dart` — Likes, reactions, bookmarks
  - `comments_ext.dart` — Nested comments, replies, comment likes
  - `topic_ext.dart` — Hashtags, trending RPCs, topic threads
  - `reposts_ext.dart` — Reposts and quote posts
  - `follow_ext.dart` — Follow/unfollow, followers/following lists
  - `profile_ext.dart` — Profile fetch and updates
  - `notifications_ext.dart` — In-app notification list and read status
  - `unread_ext.dart` — Unread counts and incoming message dispatch
  - `storage_ext.dart` — Image and media uploads
  - `search_ext.dart` — User and thread search
  - `messaging_ext.dart` — DM chats and conversations
  - `verification_ext.dart` — Blue/Gold/Gray badges and verification plans

---

## Core Database Tables Schema

All primary tables use UUID keys matching `auth.users(id)`.

### 1. `profiles`
References Supabase `auth.users(id)` ON DELETE CASCADE.
- `id` (UUID, PK)
- `username` (TEXT, UNIQUE)
- `full_name` (TEXT)
- `bio` (TEXT), `avatar_url` (TEXT), `cover_url` (TEXT)
- `followers_count` (INT, default 0), `following_count` (INT, default 0)
- `fcm_token` (TEXT) — Stores FCM device registration token
- `is_verified` (BOOL), `badge_type` (TEXT: `'gold'`, `'gray'`, `'blue'`)
- `role` (TEXT: `'Admin'`, `'Moderator'`, `'Junior Mod'`)
- `is_suspended` (BOOL), `is_banned` (BOOL), `is_private` (BOOL)
- `reach_multiplier` (NUMERIC, default 1.0)
- `created_at` (TIMESTAMPTZ)

### 2. `threads` (Posts)
- `id` (UUID, PK)
- `user_id` (UUID, FK -> `profiles.id`)
- `content` (TEXT)
- `image_urls` (TEXT[]) — Array of Supabase Storage URLs
- `video_url` (TEXT), `audio_url` (TEXT)
- `likes_count`, `replies_count`, `reposts_count`, `saves_count`, `shares_count`, `views_count` (INT)
- `is_pinned` (BOOL), `mute_notifications` (BOOL)
- `audience` (TEXT: `'Public'`, `'Followers'`, `'Subscribers'`)
- `is_boosted` (BOOL), `boost_status` (TEXT)
- `created_at` (TIMESTAMPTZ)

### 3. `likes`
- `id` (UUID, PK)
- `user_id` (UUID, FK -> `profiles.id`)
- `thread_id` (UUID, FK -> `threads.id`)
- `reaction_type` (TEXT, default `'❤️'`)
- CONSTRAINT: `UNIQUE(user_id, thread_id)`

### 4. `comments` & `comment_likes`
- `comments`: `id`, `thread_id`, `user_id`, `content`, `parent_id` (FK -> `comments.id` for nested replies), `image_url`, `likes_count`, `created_at`
- `comment_likes`: `id`, `user_id`, `comment_id`, `UNIQUE(user_id, comment_id)`

### 5. `follows`
- `id` (UUID, PK)
- `follower_id` (UUID, FK -> `profiles.id`)
- `following_id` (UUID, FK -> `profiles.id`)
- CONSTRAINT: `UNIQUE(follower_id, following_id)`

### 6. `messages` (Private DMs)
- `id` (UUID, PK)
- `sender_id` (UUID, FK -> `profiles.id`)
- `receiver_id` (UUID, FK -> `profiles.id`)
- `content` (TEXT: plaintext or encrypted `E2EE:v1:{keyId}:{nonce}:{mac}:{cipherText}`)
- `is_read` (BOOL, default false)
- `created_at` (TIMESTAMPTZ)

### 7. `notifications` (In-App)
- `id` (UUID, PK)
- `user_id` (UUID, FK -> `profiles.id` — recipient)
- `actor_id` (UUID, FK -> `profiles.id` — sender)
- `type` (TEXT: `'like'`, `'comment'`, `'reply'`, `'follow'`, `'mention'`, `'message'`)
- `thread_id` (UUID, FK -> `threads.id`, nullable)
- `content` (TEXT)
- `is_read` (BOOL, default false)
- `created_at` (TIMESTAMPTZ)

### 8. Auxiliary Tables
- `reposts`: `user_id`, `thread_id`, `quote_text`, UNIQUE(`user_id`, `thread_id`)
- `poll_options` & `poll_votes`: Poll attachments and voter tracking
- `saved_posts`: Bookmarks (`user_id`, `thread_id`)
- `topics` & `thread_topics`: Hashtag extraction and categorization
- `communities` & `community_members`: Group hubs
- `blocks`, `mutes`, `thread_hides`: Safety and filtering
- `reports`, `audit_logs`, `system_settings`: Admin and moderation

---

## Automated Database Triggers

Pigeon relies on PostgreSQL triggers to maintain data integrity and counter caches:

| Trigger Name | Source Table | Target / Action |
|--------------|--------------|-----------------|
| `on_auth_user_created` | `auth.users` | Executes `handle_new_user()` to populate `profiles` on signup |
| `on_like_change` | `likes` | Increments/decrements `threads.likes_count` |
| `on_comment_change` | `comments` | Increments/decrements `threads.replies_count` (or parent comment) |
| `on_repost_change` | `reposts` | Increments/decrements `threads.reposts_count` |
| `on_follow_change` | `follows` | Increments/decrements `profiles.following_count` & `followers_count` |
| `on_comment_inserted` | `comments` | Executes `notify_on_comment()` -> inserts row into `notifications` |
| `on_like_inserted` | `likes` | Executes `notify_on_like()` -> inserts row into `notifications` |
| `on_follow_inserted` | `follows` | Executes `notify_on_follow()` -> inserts row into `notifications` |
| `on_push_trigger` | `messages` / `comments` | Uses `pg_net` to call Edge Function `send_auto_push` for FCM dispatch |

---

## Stored Procedures / RPC Functions

Always call RPCs via `_supabase.rpc('function_name', params: { ... })`:

1. **`get_personalized_feed`**:
   - Parameters: `p_user_id UUID, p_limit INT, p_offset INT`
   - Returns ranked thread IDs based on user interaction weights, followed activity, and recency.
2. **`get_trending_topics`**:
   - Parameters: `limit_val INT` (typically 10)
   - Returns top hashtags ranked by recent velocity.
3. **`get_rising_topics`**:
   - Parameters: `limit_val INT`
4. **`get_most_discussed_topics`**:
   - Parameters: `limit_val INT`
5. **`get_topic_threads`**:
   - Parameters: `topic_name TEXT`
   - Returns thread IDs belonging to the given hashtag.

---

## Supabase Storage

- **Bucket Name**: `avatars` (Public bucket)
- **Path Structure**:
  - Profiles: `avatars/{uid}/profile_{timestamp}.jpg`
  - Covers: `avatars/{uid}/cover_{timestamp}.jpg`
  - Threads: `threads/{uid}/{timestamp}.jpg`
  - Chat Attachments: `chat/{chatId}/{timestamp}.jpg`
  - Comments: `comments/{threadId}/{timestamp}.jpg`
  - Verification Documents: `verification/{uid}/{timestamp}.jpg`
- **Upload Flow**: Always compress before upload using `MediaCompressor`, then call `storage.from('avatars').uploadBinary(...)`.
- **Public URL**: Call `storage.from('avatars').getPublicUrl(path)`.

---

## Realtime Subscriptions Pattern

Realtime subscriptions must be strictly managed to prevent memory leaks and duplicate notifications:

```dart
// Example: Listening for new incoming messages for the current user
final channel = _supabase.channel('messages_$_currentUid')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'receiver_id',
      value: _currentUid,
    ),
    callback: (payload) {
      _handleIncomingMessage(payload.newRecord);
    },
  )
  .subscribe();
```

**Lifecycle Rules:**
- Subscribe after user authentication is confirmed.
- Save channel references to unregister on logout or screen unmount:
  ```dart
  await _supabase.removeChannel(channel);
  ```
- Never create un-filtered, table-wide subscriptions on large tables (`threads`, `messages`, `likes`).

---

## Row Level Security (RLS) & Security Best Practices

1. **Never expose `service_role` key** — Flutter client must only use `anonKey`.
2. **Always validate `auth.uid()` in RLS policies**:
   - Read permissions: allow public reads on `threads` where `audience = 'Public'` and author is not blocked.
   - Insert permissions: enforce `WITH CHECK (auth.uid() = user_id)`.
   - Update/Delete permissions: enforce `USING (auth.uid() = user_id)`.
3. **Admin Actions**: Admin-only operations (verifying users, changing badges, banning users) must check the user's role:
   ```sql
   EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Admin')
   ```
4. **Foreign Key Deletes**: User-owned content must use `ON DELETE CASCADE` linked to `profiles(id)`.