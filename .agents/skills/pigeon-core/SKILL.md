---
name: pigeon-core
description: Use when working on Pigeon Social (Dak) to understand the project architecture, design patterns, dependency injection, state management, security principles, and engineering rules.
---

# Pigeon Core Architecture Manual

## Use this skill when

- planning, implementing, or reviewing any feature in Pigeon (Dak)
- refactoring or maintaining code across the project
- adding new dependencies, services, or use cases
- designing new data flows between Flutter, SQLite, and Supabase
- troubleshooting cross-cutting architecture issues (state management, DI, service lifecycle)
- ensuring alignment with the project's coding conventions and architectural patterns

## Do not use this skill when

- working on a task completely unrelated to the Pigeon/Dak codebase

---

## High-Level Architecture

Pigeon (Dak) is an end-to-end encrypted social media and private messaging platform built with **Flutter**, **Supabase (PostgreSQL + Auth + Storage + Realtime)**, **SQLite**, and **Firebase Cloud Messaging**.

The codebase follows a hybrid **Clean Architecture + Modular Service Extension** design:

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                    │
│   • Screens: feed_screen, chat_screen, notifications, etc.  │
│   • Widgets: thread_card_components, main_drawer, etc.      │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Listens to ChangeNotifiers)
┌──────────────────────────────▼──────────────────────────────┐
│                    State Management Layer                   │
│   • DatabaseService (Provider / ChangeNotifier)             │
│   • AuthService, ChatSettingsProvider, GeneralSettings...   │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Invokes UseCases via sl<T>())
┌──────────────────────────────▼──────────────────────────────┐
│                  Domain Layer (Clean Architecture)          │
│   • Features: auth, feed, chat, profile, notifications      │
│   • Use Cases: GetFeedUseCase, SendMessageUseCase, etc.     │
│   • Repository Contracts: IFeedRepository, IChatRepository  │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Implements Repositories)
┌──────────────────────────────▼──────────────────────────────┐
│                        Data Layer                           │
│   • Repositories: FeedRepositoryImpl, ChatRepositoryImpl    │
│   • Remote Data Sources: Supabase RPCs, Tables, Storage     │
│   • Local Data Sources: LocalChatDb (SQLite), SharedPreferences
│   • Cryptographic Layer: E2EEService (X25519 + AES-256-GCM) │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Project Design Patterns

### 1. Dependency Injection (`lib/core/injection.dart`)
All services, repositories, datasources, and use cases are registered in GetIt:
```dart
final sl = GetIt.instance;

// Registering singletons
sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
sl.registerLazySingleton<E2EEService>(() => E2EEService(sl()));
sl.registerLazySingleton<GetFeedUseCase>(() => GetFeedUseCase(sl()));
sl.registerLazySingleton<PlaySoundUseCase>(() => PlaySoundUseCase(sl()));
```
Always use `sl<Type>()` to obtain dependencies rather than instantiating them manually.

### 2. Service Extension Pattern (`lib/services/parts/`)
The primary service `DatabaseService` (`lib/services/database_service.dart`) splits its responsibilities across 15 modular Dart `part` extensions in `lib/services/parts/`:
- `feed_ext.dart` — Home feed, user threads, post creation, poll voting
- `algorithmicfeed_ext.dart` — AI personalized feed RPC hydration and verification weighting
- `likes_ext.dart` — Likes, reactions, bookmarks
- `comments_ext.dart` — Nested comments, replies, comment likes
- `topic_ext.dart` — Hashtags, trending RPCs, topic threads
- `reposts_ext.dart` — Reposts and quote posts
- `follow_ext.dart` — Follow/unfollow relationships
- `profile_ext.dart` — Profile queries and updates
- `notifications_ext.dart` — In-app notifications
- `unread_ext.dart` — Unread counts and incoming message dispatch
- `storage_ext.dart` — Media upload handling
- `search_ext.dart` — Search users and threads
- `messaging_ext.dart` — DM chats and conversations
- `verification_ext.dart` — Badges (Gold/Gray/Blue) and verification plans

**Rule:** When adding or modifying database operations, place them in the corresponding `parts/*_ext.dart` file using `part of '../database_service.dart';`.

### 3. Offline-First Chat & SQLite Cache (`LocalChatDb`)
- Chat messages are stored locally in SQLite (`local_chat_db.dart`) for instant loading without network delay.
- Sent messages are saved with `sync_status = 'pending'`, and updated to `'synced'` once Supabase confirms insertion.
- When opening a chat, load from SQLite first, then stream new messages from Supabase Realtime.

### 4. End-to-End Encryption (`E2EEService`)
- Cryptography: X25519 Diffie-Hellman key exchange + AES-256-GCM authenticated encryption.
- Encrypted message payload format: `E2EE:v1:{keyId}:{nonce}:{mac}:{cipherText}`.
- Decryption happens before displaying messages or notifications (`unread_ext.dart`).
- Private keys must never leave local secure storage.

### 5. Centralized In-Memory Post Cache (`_postsCache`)
- All feed lists (`_feed`, `_myThreads`, `_personalizedFeed`, `_savedPosts`) are synchronized via `_postsCache[threadId]`.
- Modifying thread state (like toggling, poll voting, bookmarking) must update `_postsCache` and all active lists simultaneously.

### 6. Media Pipeline (`MediaCompressor`)
- All images must be compressed using `MediaCompressor` before upload to the `avatars` bucket in Supabase Storage.
- Images are displayed using `CachedNetworkImage` with fallback placeholders and error widgets.

### 7. Audio & Haptic Feedback (`sl<PlaySoundUseCase>()`)
- Use `sl<PlaySoundUseCase>().call(SoundType.pop)` on likes and poll votes.
- Use `sl<PlaySoundUseCase>().call(SoundType.chime)` on incoming messages.

### 8. Anti-Spam & Rate Limiting
- `DatabaseService._cooldownDuration` enforces a cooldown period between post creation and comments.
- Duplicate comments are rejected by comparing against `_lastCommentContent`.

### 9. Content Moderation & Safety
- Shadowbanned user content is automatically stripped from unprivileged users' feeds (`p.author.isShadowbanned && p.author.id != _currentUid`).
- User moderation roles: `'Admin'`, `'Moderator'`, `'Junior Mod'`.

---

## Priority Order for Engineering Decisions

When implementing or reviewing changes in Pigeon:

1. **Security & Cryptography**: Never compromise E2EE private keys, never expose Supabase service-role keys, never disable RLS.
2. **Data Integrity & Synchronization**: Ensure optimistic updates rollback on failure and local caches stay in sync with Supabase.
3. **User Experience & Responsiveness**: Provide instant feedback (optimistic UI, sounds, haptics, skeleton loaders).
4. **Performance & Resource Usage**: Always paginate feeds and comments; compress all media; dispose Realtime channels.
5. **Clean Architecture**: Use cases must remain decoupled from Flutter UI widgets.

---

## Absolute Prohibitions (Never Do)

- ❌ Never put direct Supabase PostgREST queries inside Flutter UI widget `build()` methods.
- ❌ Never send unencrypted private messages when E2EE is enabled.
- ❌ Never remove the `part of '../database_service.dart'` declaration when working in `lib/services/parts/`.
- ❌ Never load unbounded lists of posts or comments without `limit` or pagination.
- ❌ Never perform cryptographic operations on the main UI thread without async / isolate consideration.
- ❌ Never ignore `currentActiveChatUserId` when dispatching message push notifications.
