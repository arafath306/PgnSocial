import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../models/notification.dart';
import '../models/verification_plan_pricing.dart';
import 'log_service.dart';

import '../core/injection.dart';
import 'general_settings_provider.dart';
import '../features/feed/domain/usecases/get_feed_use_case.dart';
import '../features/feed/domain/usecases/create_thread_use_case.dart';
import '../features/feed/domain/usecases/toggle_like_use_case.dart';
import '../features/feed/domain/usecases/toggle_save_thread_use_case.dart';
import '../features/feed/domain/usecases/fetch_comments_use_case.dart';
import '../features/feed/domain/usecases/add_comment_use_case.dart';
import '../features/feed/domain/entities/thread_post_entity.dart';
import '../features/feed/domain/repositories/feed_repository.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_active_chats_use_case.dart';
import '../features/chat/domain/usecases/get_messages_stream_use_case.dart';
import '../features/chat/domain/usecases/send_message_use_case.dart';
import '../features/chat/domain/usecases/mark_messages_as_read_use_case.dart';
import '../features/chat/domain/usecases/delete_conversation_use_case.dart';
import '../features/chat/domain/usecases/upload_chat_media_use_case.dart';
import '../features/profile/domain/usecases/submit_verification_use_case.dart';
import '../features/profile/domain/usecases/get_verification_status_use_case.dart';
import '../features/profile/domain/usecases/update_profile_use_case.dart';
import '../features/profile/domain/usecases/upload_verification_image_use_case.dart';
import '../features/profile/domain/usecases/update_profile_image_use_case.dart';
import '../features/profile/domain/usecases/fetch_verification_plans_use_case.dart';
import '../features/profile/domain/usecases/update_verification_plan_price_use_case.dart';
import '../features/profile/domain/usecases/fetch_admin_verification_requests_use_case.dart';
import '../features/profile/domain/usecases/update_verification_request_status_use_case.dart';
import '../features/notifications/domain/usecases/show_notification_use_case.dart';
import '../features/notifications/domain/usecases/play_sound_use_case.dart';
import '../core/security/e2ee_service.dart';
import '../utils/media_compressor.dart';

part 'parts/profile_ext.dart';
part 'parts/follow_ext.dart';
part 'parts/search_ext.dart';
part 'parts/storage_ext.dart';
part 'parts/feed_ext.dart';
part 'parts/likes_ext.dart';
part 'parts/author_ext.dart';
part 'parts/notifications_ext.dart';
part 'parts/unread_ext.dart';
part 'parts/messaging_ext.dart';
part 'parts/comments_ext.dart';
part 'parts/reposts_ext.dart';
part 'parts/topic_ext.dart';
part 'parts/algorithmicfeed_ext.dart';
part 'parts/verification_ext.dart';

class DatabaseService with ChangeNotifier {
  static String? activeChatUserId;
  String? get currentActiveChatUserId => activeChatUserId;
  set currentActiveChatUserId(String? val) {
    activeChatUserId = val;
  }
  void updateState() => notifyListeners();
  final _supabase = sl<SupabaseClient>();

  // Cooldown / Rate Limiting fields
  DateTime? _lastPostTime;
  DateTime? _lastCommentTime;
  String? _lastCommentContent;
  static const Duration _cooldownDuration = Duration(seconds: 3);

  ThreadPost _entityToModel(ThreadPostEntity entity) {
    return ThreadPost(
      id: entity.id,
      userId: entity.userId,
      author: entity.author,
      content: entity.content,
      imageUrls: entity.imageUrls,
      videoUrl: entity.videoUrl,
      likesCount: entity.likesCount,
      repliesCount: entity.repliesCount,
      repostsCount: entity.repostsCount,
      savesCount: entity.savesCount,
      sharesCount: entity.sharesCount,
      viewsCount: entity.viewsCount,
      createdAt: entity.createdAt,
      isLikedByMe: entity.isLikedByMe,
      reactionType: entity.reactionType,
      isPinned: entity.isPinned,
      muteNotifications: entity.muteNotifications,
      hideFromProfile: entity.hideFromProfile,
      isHiddenFromMe: entity.isHiddenFromMe,
      commenterAvatars: entity.commenterAvatars,
      isRepost: entity.isRepost,
      repostedPost: entity.repostedPost != null ? _entityToModel(entity.repostedPost!) : null,
      quoteText: entity.quoteText,
      isSubscriberOnly: entity.isSubscriberOnly,
      pollOptions: entity.pollOptions,
      pollExpiresAt: entity.pollExpiresAt,
      hasVotedPoll: entity.hasVotedPoll,
      votedOptionId: entity.votedOptionId,
      musicTrack: entity.musicTrack,
    );
  }

  // Cache variables
  Profile? _myProfile;
  Profile? get myProfile => _myProfile;

  List<ThreadPost> _feed = [];
  List<ThreadPost> get feed => _feed;

  List<ThreadPost> _personalizedFeed = [];
  List<ThreadPost> get personalizedFeed => _personalizedFeed;

  int _aiFeedPage = 0;
  bool _aiFeedHasMore = true;
  bool get aiFeedHasMore => _aiFeedHasMore;

  List<ThreadPost> _myThreads = [];
  List<ThreadPost> get myThreads => _myThreads;

  final List<ThreadPost> _myReplies = [];
  List<ThreadPost> get myReplies => _myReplies;

  final Map<String, ThreadPost> _postsCache = {};
  final Set<String> _deletedPostIds = {};

  bool isPostDeleted(String id) => _deletedPostIds.contains(id);

  void _updateCache(List<ThreadPost> posts) {
    for (final post in posts) {
      _postsCache[post.id] = post;
    }
  }

  void _updatePostInLists(String threadId, ThreadPost updatedPost) {
    _postsCache[threadId] = updatedPost;
    void updateInList(List<ThreadPost> list) {
      final idx = list.indexWhere((p) => p.id == threadId);
      if (idx != -1) {
        list[idx] = updatedPost;
      }
    }
    updateInList(_feed);
    updateInList(_myThreads);
    updateInList(_personalizedFeed);
    updateInList(_myReplies);
    updateInList(_savedPosts);
  }





  Future<void> _reloadThread(String threadId, {bool isNew = false}) async {
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*), comments(profiles(avatar_url))')
          .eq('id', threadId)
          .maybeSingle();

      if (response != null) {
        final updatedPost = ThreadPost.fromJson(response, currentUid: _currentUid);
        
        if (isNew) {
          final alreadyInFeed = _feed.any((p) => p.id == threadId);
          if (!alreadyInFeed) {
            _feed.insert(0, updatedPost);
          }
          final isAuthorMe = updatedPost.userId == _currentUid;
          if (isAuthorMe) {
            final alreadyInMyThreads = _myThreads.any((p) => p.id == threadId);
            if (!alreadyInMyThreads) {
              _myThreads.insert(0, updatedPost);
            }
          }
          _postsCache[threadId] = updatedPost;
        } else {
          _updatePostInLists(threadId, updatedPost);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reloading/inserting thread: $e');
    }
  }



  ThreadPost getLatestPost(ThreadPost fallbackPost) {
    final cached = _postsCache[fallbackPost.id];
    if (cached == null) {
      _postsCache[fallbackPost.id] = fallbackPost;
      return fallbackPost;
    }
    return cached;
  }

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  Set<String> _followingIds = {};
  Set<String> get followingIds => _followingIds;

  Set<String> _blockedUserIds = {};
  Set<String> get blockedUserIds => _blockedUserIds;

  Set<String> _blockedByMeIds = {};
  Set<String> get blockedByMeIds => _blockedByMeIds;

  Set<String> _mutedUserIds = {};
  Set<String> get mutedUserIds => _mutedUserIds;

  Set<String> _savedThreadIds = {};
  Set<String> get savedThreadIds => _savedThreadIds;

  List<ThreadPost> _savedPosts = [];
  List<ThreadPost> get savedPosts => _savedPosts;

  Set<String> _savedCommentIds = {};
  Set<String> get savedCommentIds => _savedCommentIds;

  List<Map<String, dynamic>> _savedComments = [];
  List<Map<String, dynamic>> get savedComments => _savedComments;

  Set<String> _repostedThreadIds = {};
  Set<String> get repostedThreadIds => _repostedThreadIds;
  bool isReposted(String threadId) => _repostedThreadIds.contains(threadId);

  Future<void> fetchRepostedThreadIds() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('reposts')
          .select('thread_id')
          .eq('user_id', _currentUid)
          .isFilter('quote_text', null);
      final List<dynamic> data = response as List<dynamic>;
      _repostedThreadIds = data.map((json) => json['thread_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch reposted thread ids error: $e');
    }
  }

  bool isBlocked(String targetUserId) => _blockedUserIds.contains(targetUserId);
  bool isBlockedByMe(String targetUserId) => _blockedByMeIds.contains(targetUserId);
  bool isMuted(String targetUserId) => _mutedUserIds.contains(targetUserId);
  bool isSaved(String threadId) => _savedThreadIds.contains(threadId);
  bool isCommentSaved(String commentId) => _savedCommentIds.contains(commentId);

  Future<void> toggleSaveThread(String threadId) async {
    final wasAlreadySaved = _savedThreadIds.contains(threadId);
    // Optimistic update
    if (wasAlreadySaved) {
      _savedThreadIds.remove(threadId);
      _savedPosts.removeWhere((p) => p.id == threadId);
    } else {
      _savedThreadIds.add(threadId);
    }

    final cached = _postsCache[threadId];
    if (cached != null) {
      final int countDelta = wasAlreadySaved ? -1 : 1;
      _postsCache[threadId] = cached.copyWith(
        savesCount: (cached.savesCount + countDelta).clamp(0, 999999),
      );
    }

    void updatePostSavesCount(List<ThreadPost> list) {
      final idx = list.indexWhere((p) => p.id == threadId);
      if (idx != -1) {
        final post = list[idx];
        final int countDelta = wasAlreadySaved ? -1 : 1;
        list[idx] = post.copyWith(
          savesCount: (post.savesCount + countDelta).clamp(0, 999999),
        );
      }
    }
    updatePostSavesCount(_feed);
    updatePostSavesCount(_myThreads);
    updatePostSavesCount(_personalizedFeed);

    notifyListeners();

    if (_currentUid.isEmpty) return;
    final result = await sl<ToggleSaveThreadUseCase>()(threadId, wasAlreadySaved);
    await result.fold(
      (failure) async {
        debugPrint('Toggle save thread error: ${failure.message}');
        // Rollback optimistic update
        if (wasAlreadySaved) {
          _savedThreadIds.add(threadId);
        } else {
          _savedThreadIds.remove(threadId);
        }

        final cachedRollback = _postsCache[threadId];
        if (cachedRollback != null) {
          final int countDelta = wasAlreadySaved ? 1 : -1;
          _postsCache[threadId] = cachedRollback.copyWith(
            savesCount: (cachedRollback.savesCount + countDelta).clamp(0, 999999),
          );
        }

        void updatePostSavesCountRollback(List<ThreadPost> list) {
          final idx = list.indexWhere((p) => p.id == threadId);
          if (idx != -1) {
            final post = list[idx];
            final int countDelta = wasAlreadySaved ? 1 : -1;
            list[idx] = post.copyWith(
              savesCount: (post.savesCount + countDelta).clamp(0, 999999),
            );
          }
        }
        updatePostSavesCountRollback(_feed);
        updatePostSavesCountRollback(_myThreads);
        updatePostSavesCountRollback(_personalizedFeed);

        notifyListeners();
      },
      (_) async {
        if (!wasAlreadySaved) {
          await fetchSavedPosts();
          logUserInteraction(threadId, 'save');
        }
      },
    );
  }

  Future<void> fetchSavedThreadIds() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_posts')
          .select('thread_id')
          .eq('user_id', _currentUid);
      final List<dynamic> data = response as List<dynamic>;
      _savedThreadIds = data.map((json) => json['thread_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch saved thread ids error: $e');
    }
  }

  Future<void> fetchSavedPosts() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_posts')
          .select('thread_id, threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id), comments(profiles(avatar_url)))')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      final List<ThreadPost> posts = [];
      for (final row in data) {
        final threadMap = row['threads'] as Map<String, dynamic>?;
        if (threadMap != null) {
          try {
            posts.add(ThreadPost.fromJson(threadMap, currentUid: _currentUid));
          } catch (e) {
            debugPrint('Error parsing saved post: $e');
          }
        }
      }
      _updateCache(posts);
      _savedPosts = posts;
      _savedThreadIds = posts.map((p) => p.id).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch saved posts error: $e');
      // Fallback: filter from feed
      _savedPosts = _feed.where((p) => _savedThreadIds.contains(p.id)).toList();
      notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Cached UID — set on signIn/tokenRefresh, cleared only on signOut.
  // This prevents empty-UUID errors during Supabase token refresh windows
  // where auth.currentUser briefly returns null.
  String _cachedUid = '';

  // Supabase session UID — used for all database operations (UUID format)
  String get _supabaseSessionUid => _supabase.auth.currentUser?.id ?? _cachedUid;

  // Effective UID: ONLY use Supabase session UID (UUID format).
  // Firebase UID is NOT a valid UUID and CANNOT be used for Supabase queries.
  String get _currentUid => _supabaseSessionUid;

  String get currentUid => _currentUid;

  int _unreadMessagesCount = 0;
  int get unreadMessagesCount => _unreadMessagesCount;

  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  List<Map<String, dynamic>> _verificationPlans = [];
  List<Map<String, dynamic>> get verificationPlans => _verificationPlans;

  final StreamController<Map<String, dynamic>> _incomingNotificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incomingNotificationStream =>
      _incomingNotificationStreamController.stream;

  RealtimeChannel? _threadsChannel;
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _repliesChannel;
  RealtimeChannel? _followsChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _blocksChannel;
  RealtimeChannel? _mutesChannel;
  RealtimeChannel? _pollVotesChannel;
  RealtimeChannel? _profilesChannel;
  StreamSubscription<AuthState>? _supabaseAuthSub;
  Timer? _lastSeenTimer;

  DatabaseService() {
    // Initialize _cachedUid from existing session (app restart after login)
    _cachedUid = _supabase.auth.currentUser?.id ?? '';
    LogService.database("DatabaseService initialized. Cached UID: $_cachedUid");

    // Listen to Supabase auth state — auto-reload when session established
    _supabaseAuthSub = _supabase.auth.onAuthStateChange.listen((data) {
      LogService.database("Supabase Auth event received: ${data.event}");
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        // Cache the UID so it survives brief token refresh windows
        final uid = data.session?.user.id ?? _supabase.auth.currentUser?.id ?? '';
        if (uid.isNotEmpty) {
          _cachedUid = uid;
          LogService.database("Supabase UID cached: $_cachedUid. Loading user settings and feeds.");
          _onUserReady();
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        LogService.database("Supabase signed out event. Clearing cached data.");
        _cachedUid = '';
        _clearAllData();
      }
    });

    subscribeToRealtime();
    if (_currentUid.isNotEmpty) {
      _onUserReady();
    }
  }

  /// Called on full logout
  void clearUser() {
    _clearAllData();
  }

  Future<void> _loadCachedAIFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('cached_ai_feed_$_currentUid');
      if (cachedJson != null) {
        final List<dynamic> decodedList = jsonDecode(cachedJson);
        final List<ThreadPost> cachedPosts = [];
        for (final json in decodedList) {
          try {
            cachedPosts.add(ThreadPost.fromJson(json, currentUid: _currentUid));
          } catch (e) {
            debugPrint('Error parsing cached post: $e');
          }
        }
        if (cachedPosts.isNotEmpty && _personalizedFeed.isEmpty) {
          _personalizedFeed = cachedPosts;
          _updateCache(cachedPosts);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached feed: $e');
    }
  }

  void _onUserReady() async {
    _isLoading = true;
    notifyListeners();
    
    // Load offline cached profile and feed first in parallel
    await Future.wait([
      _loadCachedProfile(),
      _loadCachedAIFeed(),
    ]);
    
    // Fetch critical lists and profile in parallel
    await Future.wait([
      fetchBlockedMutedLists(),
      fetchMyProfile(),
      fetchFollowingList(),
    ]);

    // Fetch feed, notifications, unreads, and other metadata concurrently in the background
    Future.wait([
      fetchFeed(silent: true),
      fetchAIFeed(silent: true),
      fetchNotifications(),
      fetchUnreadCounts(),
      fetchSavedThreadIds(),
      fetchSavedCommentIds(),
      fetchSavedPosts(),
      fetchSavedComments(),
      fetchRepostedThreadIds(),
    ]);

    subscribeToRealtime();

    // Periodically update active status
    updateLastSeen();
    _lastSeenTimer?.cancel();
    _lastSeenTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      updateLastSeen();
    });
  }

  void _clearAllData() {
    _myProfile = null;
    _feed = [];
    _personalizedFeed = [];
    _aiFeedPage = 0;
    _aiFeedHasMore = true;
    _myThreads = [];
    _notifications = [];
    _followingIds = {};
    _blockedUserIds = {};
    _blockedByMeIds = {};
    _mutedUserIds = {};
    _savedThreadIds = {};
    _savedCommentIds = {};
    _savedPosts = [];
    _savedComments = [];
    _repostedThreadIds = {};
    _postsCache.clear();
    _deletedPostIds.clear();
    _lastSeenTimer?.cancel();
    unsubscribeRealtime();
    notifyListeners();
  }

  void subscribeToRealtime() {
    // Unsubscribe if channels already exist
    unsubscribeRealtime();

    // -------------------------------------------------------------------------
    // PRODUCTION SCALABILITY FIX:
    // Global subscriptions to threads, likes, comments, follows, and poll_votes
    // have been disabled. Subscribing to these tables globally causes massive
    // performance issues and connection crashes when the user base grows, 
    // as every user receives every global event.
    // Use pull-to-refresh instead for these global feeds.
    // -------------------------------------------------------------------------

    /*
    _threadsChannel = _supabase
        .channel('public:threads')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'threads',
            callback: (payload) {
              final threadId = (payload.newRecord['id'] ?? payload.oldRecord['id']) as String?;
              if (threadId != null) {
                if (payload.eventType == PostgresChangeEvent.insert) {
                  _reloadThread(threadId, isNew: true);
                } else if (payload.eventType == PostgresChangeEvent.update) {
                  _reloadThread(threadId, isNew: false);
                } else if (payload.eventType == PostgresChangeEvent.delete) {
                  _removePostFromLists(threadId);
                  notifyListeners();
                }
              }
            })
        .subscribe();

    _likesChannel = _supabase
        .channel('public:likes')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'likes',
            callback: (payload) {
              final threadId = (payload.newRecord['thread_id'] ?? payload.oldRecord['thread_id']) as String?;
              final userId = (payload.newRecord['user_id'] ?? payload.oldRecord['user_id']) as String?;
              if (threadId != null && userId != null) {
                _handleLikeRealtimeUpdate(threadId, userId, payload.eventType);
              }
            })
        .subscribe();

    _repliesChannel = _supabase
        .channel('public:comments')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'comments',
            callback: (payload) {
              final threadId = (payload.newRecord['thread_id'] ?? payload.oldRecord['thread_id']) as String?;
              final parentId = (payload.newRecord['parent_id'] ?? payload.oldRecord['parent_id']) as String?;
              if (threadId != null && parentId == null) {
                _updateReplyCountInCache(threadId, payload.eventType);
              }
            })
        .subscribe();

    _followsChannel = _supabase
        .channel('public:follows')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'follows',
            callback: (payload) {
              fetchFollowingList();
              fetchMyProfile();
            })
        .subscribe();
    */

    _notificationsChannel = _supabase
        .channel('public:notifications:$_currentUid')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _currentUid,
            ),
            callback: (payload) {
              fetchNotifications();
              fetchUnreadCounts();
              
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newNotif = payload.newRecord;
                if (newNotif['user_id'] == _currentUid && (newNotif['actor_id'] != _currentUid || newNotif['type'] == 'mention')) {
                  _handleIncomingNotification(newNotif);
                }
              }
            })
        .subscribe();

    _messagesChannel = _supabase
        .channel('public:messages:$_currentUid')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'receiver_id',
              value: _currentUid,
            ),
            callback: (payload) {
              fetchUnreadCounts();
              
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newMsg = payload.newRecord;
                if (newMsg['receiver_id'] == _currentUid && newMsg['sender_id'] != _currentUid) {
                  _handleIncomingMessage(newMsg);
                }
              }
            })
        .subscribe();

    _blocksChannel = _supabase
        .channel('public:blocks:$_currentUid')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'blocks',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _currentUid,
            ),
            callback: (payload) {
              fetchBlockedMutedLists();
              fetchFeed(silent: true);
            })
        .subscribe();

    _mutesChannel = _supabase
        .channel('public:mutes:$_currentUid')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'mutes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _currentUid,
            ),
            callback: (payload) {
              fetchBlockedMutedLists();
              fetchFeed(silent: true);
            })
        .subscribe();

    _profilesChannel = _supabase
        .channel('public:profiles:$_currentUid')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'profiles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: _currentUid,
            ),
            callback: (payload) {
              fetchMyProfile();
            })
        .subscribe();

    /*
    _pollVotesChannel = _supabase
        .channel('public:poll_votes')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'poll_votes',
            callback: (payload) {
              final threadId = (payload.newRecord['thread_id'] ?? payload.oldRecord['thread_id']) as String?;
              if (threadId != null) {
                _reloadThread(threadId);
              }
            })
        .subscribe();
    */
  }

  void unsubscribeRealtime() {
    if (_threadsChannel != null) _supabase.removeChannel(_threadsChannel!);
    if (_likesChannel != null) _supabase.removeChannel(_likesChannel!);
    if (_repliesChannel != null) _supabase.removeChannel(_repliesChannel!);
    if (_followsChannel != null) _supabase.removeChannel(_followsChannel!);
    if (_notificationsChannel != null) _supabase.removeChannel(_notificationsChannel!);
    if (_messagesChannel != null) _supabase.removeChannel(_messagesChannel!);
    if (_blocksChannel != null) {
      _supabase.removeChannel(_blocksChannel!);
      _blocksChannel = null;
    }
    if (_mutesChannel != null) {
      _supabase.removeChannel(_mutesChannel!);
      _mutesChannel = null;
    }
    if (_pollVotesChannel != null) {
      _supabase.removeChannel(_pollVotesChannel!);
      _pollVotesChannel = null;
    }
    if (_profilesChannel != null) {
      _supabase.removeChannel(_profilesChannel!);
      _profilesChannel = null;
    }
  }
  @override
  void dispose() {
    _supabaseAuthSub?.cancel();
    _lastSeenTimer?.cancel();
    unsubscribeRealtime();
    super.dispose();
  }
}
extension IterableExtension<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e)).toList();
  }
}

