---
name: pigeon-social-feed
description: Use when implementing, modifying, debugging, or reviewing Pigeon's social feed, threads/posts, comments, likes/reactions, polls, reposts, topics/trending, or feed caching.
---

# Pigeon Social Feed

## Use this skill when

- modifying the Home feed or AI Personalized ("For You") feed
- implementing or updating thread/post creation (text, images, video, audio, polls)
- implementing or modifying likes/reactions, bookmarks, or saved posts
- modifying comment system (nested replies, reply counts, comment images)
- modifying poll creation, voting, and expiration
- modifying reposts or quote posts
- implementing or modifying hashtag/topic system and trending calculations
- modifying feed pagination, caching (`_postsCache`), or optimistic updates
- handling shadowban filtering in feeds
- debugging feed rendering, infinite scrolling, or thread engagement state

## Do not use this skill when

- working exclusively on 1-on-1 chat or E2EE private messaging (use `pigeon-e2ee`)
- modifying push/local notifications only (use `pigeon-notifications`)
- modifying pure Supabase storage upload logic (use `pigeon-media`)
- changing user profile settings unrelated to post feeds

---

## Feed Architecture Overview

Pigeon uses Clean Architecture combined with a centralized `DatabaseService` part-extension pattern and GetIt Service Locator (`sl<T>()`).

```
Feed Screen (UI)
  │
  ▼
DatabaseService (ChangeNotifier / Provider)
  ├── FeedExtension (feed_ext.dart)
  ├── AlgorithmicFeedExtension (algorithmicfeed_ext.dart)
  ├── LikesExtension (likes_ext.dart)
  ├── CommentsExtension (comments_ext.dart)
  ├── TopicExtension (topic_ext.dart)
  └── RepostsExtension (reposts_ext.dart)
  │
  ▼
Domain Layer (Use Cases registered in GetIt `sl`)
  ├── GetFeedUseCase
  ├── CreateThreadUseCase
  ├── ToggleLikeUseCase
  ├── ToggleSaveThreadUseCase
  ├── FetchCommentsUseCase
  └── AddCommentUseCase
  │
  ▼
Repository Layer
  ├── IFeedRepository (interface)
  └── FeedRepositoryImpl (implementation)
  │
  ▼
Data Layer
  ├── FeedRemoteDataSource
  └── Supabase PostgreSQL (tables, RPC functions, triggers)
```

---

## Feed Types & Operations

### 1. Home Feed (Followed Users & Public Threads)
- **Method**: `DatabaseService.fetchFeed({bool silent = false})` in `feed_ext.dart`
- **Use Case**: `sl<GetFeedUseCase>()(silent: silent)`
- **Shadowban Filter**: Always filter out shadowbanned users:
  ```dart
  _feed = entities.map((e) => _entityToModel(e)).toList();
  _feed.removeWhere((p) => p.author.isShadowbanned && p.author.id != _currentUid);
  _updateCache(_feed);
  ```

### 2. Personalized "For You" Feed (Algorithmic / AI Feed)
- **Method**: `DatabaseService.fetchAIFeed({bool silent = false, int limit = 15, bool loadMore = false})` in `algorithmicfeed_ext.dart`
- **Database RPC**: Calls PostgreSQL RPC `get_personalized_feed`:
  ```dart
  final response = await _supabase.rpc(
    'get_personalized_feed',
    params: {
      'p_user_id': _currentUid,
      'p_limit': limit,
      'p_offset': offset,
    },
  );
  ```
- **Thread Hydration**: The RPC returns candidate IDs; full post data is hydrated via join:
  ```dart
  final threadsRes = await _supabase
      .from('threads')
      .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*), comments(profiles(avatar_url))')
      .inFilter('id', threadIds);
  ```
- **Verification Priority Ordering**: When enabled in `GeneralSettingsProvider.isAlgorithmicPriorityEnabled`, posts are prioritized:
  - `gold` badge = Priority 3
  - `gray` badge = Priority 2
  - `isVerified` (Blue) = Priority 1
  - Unverified = Priority 0
- **Reposts Injection**: Followed users' reposts from the `reposts` table are joined and mapped into `ThreadPost(isRepost: true, ...)` for the For You feed.

### 3. User Threads & Bookmarks
- **User Threads**: `fetchMyThreads()` via `IFeedRepository.fetchMyThreads()`
- **Saved Posts (Bookmarks)**: Handled via `saved_posts` table and `ToggleSaveThreadUseCase`

---

## Centralized Post Cache & Synchronization Pattern

Pigeon maintains multiple active post lists simultaneously:
- `_feed` (Home Feed)
- `_myThreads` (Current User Profile)
- `_personalizedFeed` (For You Feed)
- `_savedPosts` (Bookmarks)
- `_postsCache` (`Map<String, ThreadPost>`)

**Critical Rule:** Whenever a thread state changes (like toggled, poll voted, saved, comment added), update `_postsCache[threadId]` AND synchronize across all active lists:

```dart
void updateInList(List<ThreadPost> list) {
  final idx = list.indexWhere((p) => p.id == threadId);
  if (idx != -1) {
    list[idx] = updatedPost;
  }
}
updateInList(_feed);
updateInList(_myThreads);
updateInList(_personalizedFeed);
updateInList(_savedPosts);
updateState();
```

---

## Post / Thread Creation Rules

- **Method**: `createThread(...)` in `feed_ext.dart`
- **Supported Media**:
  - `imageUrls`: `List<String>?` (uploaded to Supabase storage bucket `avatars/threads/...`)
  - `videoUrl`: `String?`
  - `audioUrl`: `String?` (voice posts)
  - `audience`: `'Public'`, `'Followers'`, `'Subscribers'`
  - `pollOptions`: `List<String>?` with `pollDuration: Duration?` (`pollExpiresAt`)
  - `communityId`: `String?` (community posts)
  - `isSubscriberOnly`: `bool`
  - `isAnonymous`: `bool`
- **Cooldown & Rate Limiting**:
  ```dart
  if (_lastPostTime != null) {
    final difference = now.difference(_lastPostTime!);
    if (difference < DatabaseService._cooldownDuration) {
      throw Exception("Please wait ${(DatabaseService._cooldownDuration - difference).inSeconds + 1}s before posting again.");
    }
  }
  _lastPostTime = now;
  ```
- **Analytics**: Log `post_create` event to `FirebaseAnalytics.instance`.
- **Feed Refresh**: Always silently refresh `fetchFeed(silent: true)`, `fetchAIFeed(silent: true)`, and `fetchMyThreads()` after successful creation.

---

## Likes & Reactions

- **Method**: `toggleLike(String threadId, bool shouldLike, {String? reactionType})` in `likes_ext.dart`
- **Haptic/Sound**: Always play pop sound on like: `sl<PlaySoundUseCase>().call(SoundType.pop)`
- **Optimistic UI**: Update `likesCount`, `isLikedByMe`, and `reactionType` immediately in `_postsCache` and all active feed lists before the network call.
- **Backend Trigger**: In PostgreSQL, the `on_like_change` trigger automatically updates `threads.likes_count`, and `notify_on_like` creates an in-app notification for the author.
- **Interaction Logging**: Call `logUserInteraction(threadId, shouldLike ? 'like' : 'scroll_away')` to train personalized ranking.
- **Reactor List**: Fetch reactor profiles via `fetchThreadReactors(threadId)`.

---

## Comments System

- **Method**: `fetchComments(threadId)`, `addComment(threadId, content, {parentId, imageUrl})` in `comments_ext.dart`
- **Nested Replies**: Comments support nested hierarchy via `parentId` (`parent_id REFERENCES comments(id)`).
  - Fetch nested replies with `fetchCommentReplies(commentId)`.
- **Duplicate Prevention & Cooldown**:
  - Check `_lastCommentContent == trimmedContent` to block duplicate comments.
  - Enforce `DatabaseService._cooldownDuration` between comments.
- **Reply Counter Maintenance**:
  - PostgreSQL trigger `handle_comment_change` increments `threads.replies_count` for top-level comments (`parent_id IS NULL`), or `comments.replies_count` for nested replies.
  - Optimistically increment `cached.repliesCount + 1` in `_postsCache`.
- **Comment Bookmarks**: `toggleSaveComment(commentId)` manages `_savedCommentIds`.

---

## Polls System

- **Tables**: `poll_options` (id, thread_id, option_text, votes_count), `poll_votes` (id, poll_option_id, user_id)
- **Method**: `votePoll(String threadId, String optionId)` in `feed_ext.dart`
- **Haptic/Sound**: `sl<PlaySoundUseCase>().call(SoundType.pop)`
- **Optimistic Update**: Check `!cached.hasVotedPoll && !cached.isPollExpired`, increment `votesCount` on the selected option, set `hasVotedPoll = true`, `votedOptionId = optionId`, and update all feed lists.

---

## Topics & Trending System

- **Extension**: `TopicExtension` in `topic_ext.dart`
- **RPC Functions**:
  - `get_trending_topics(limit_val: 10)` — based on recent velocity of hashtag mentions
  - `get_rising_topics(limit_val: 10)`
  - `get_most_discussed_topics(limit_val: 10)`
  - `get_topic_threads(topic_name)` — retrieves thread IDs matching a topic; handles `#` prefix transparently:
    ```dart
    var response = await _supabase.rpc('get_topic_threads', params: {'topic_name': nameWithHash});
    if ((response as List).isEmpty) {
      response = await _supabase.rpc('get_topic_threads', params: {'topic_name': nameWithoutHash});
    }
    ```

---

## Common Pitfalls to Avoid

1. **Never load full feeds without limits/pagination** — always use `limit: 15` or `limit: 20` and cursor/offset.
2. **Never modify `_feed` in isolation** — always sync `_postsCache`, `_myThreads`, and `_personalizedFeed`.
3. **Never forget shadowban filtering** — unprivileged users must not see threads from shadowbanned authors.
4. **Never calculate ranking client-side in widget build** — ranking belongs in Supabase RPC or state extensions.
5. **Never skip `PlaySoundUseCase`** — likes and poll votes expect instant sound/haptic feedback.
6. **Never execute raw SQL for post interactions** — use use-cases (`ToggleLikeUseCase`, `AddCommentUseCase`, etc.) registered in `sl`.