import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneralSettingsProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  String get _currentUid => _supabase.auth.currentUser?.id ?? '';

  GeneralSettingsProvider() {
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    _lowDataMode = prefs.getBool('lowDataMode') ?? false;
    String? langCode = prefs.getString('app_language');
    if (langCode != null) {
      _appLocale = Locale(langCode);
    }
    notifyListeners();
  }

  // Privacy State
  bool _isPrivateAccount = false;
  bool get isPrivateAccount => _isPrivateAccount;

  String _allowMentionsFrom = 'everyone'; // 'everyone', 'people_you_follow', 'no_one'
  String get allowMentionsFrom => _allowMentionsFrom;

  bool _filterAdultContent = true;
  bool get filterAdultContent => _filterAdultContent;

  bool _autoplayVideos = true;
  bool get autoplayVideos => _autoplayVideos;

  bool _isActiveStatusEnabled = true;
  bool get isActiveStatusEnabled => _isActiveStatusEnabled;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isVoicePostEnabled = false;
  bool get isVoicePostEnabled => _isVoicePostEnabled;

  bool _isTieredBadgesEnabled = false;
  bool get isTieredBadgesEnabled => _isTieredBadgesEnabled;

  bool _isAlgorithmicPriorityEnabled = false;
  bool get isAlgorithmicPriorityEnabled => _isAlgorithmicPriorityEnabled;

  bool _isAnonymousPostingEnabled = false;
  bool get isAnonymousPostingEnabled => _isAnonymousPostingEnabled;

  Future<void> fetchSettings() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    // ── Feature flags are loaded FIRST and INDEPENDENTLY ──────────────────
    // Any failure in profile/blocks/mutes will NOT prevent flags from loading.
    await _loadFeatureFlags(uid);

    try {
      // ── Run 3 independent queries in parallel ──────────────────────────
      final results = await Future.wait<dynamic>([
        // [0] Privacy settings + badge
        _supabase
            .from('profiles')
            .select('is_private, allow_mentions, filter_adult, autoplay_videos, is_active_status_enabled, verified_badge')
            .eq('id', uid)
            .maybeSingle() as Future<dynamic>,

        // [1] Blocked user IDs
        _supabase
            .from('blocks')
            .select('blocked_id')
            .eq('blocker_id', uid) as Future<dynamic>,

        // [2] Muted user IDs
        _supabase
            .from('mutes')
            .select('muted_id')
            .eq('muter_id', uid) as Future<dynamic>,
      ]);

      // ── [0] Apply profile/privacy settings ────────────────────────────
      final profileRes = results[0] as Map<String, dynamic>?;
      if (profileRes != null) {
        _isPrivateAccount = profileRes['is_private'] as bool? ?? false;
        _allowMentionsFrom = profileRes['allow_mentions'] as String? ?? 'everyone';
        _filterAdultContent = profileRes['filter_adult'] as bool? ?? true;
        _autoplayVideos = profileRes['autoplay_videos'] as bool? ?? true;
        _isActiveStatusEnabled = profileRes['is_active_status_enabled'] as bool? ?? true;
      }

      // ── [1] Blocked accounts — fetch profiles for blocked IDs ─────────
      _blockedAccounts.clear();
      final blockedRes = results[1] as List<dynamic>;
      if (blockedRes.isNotEmpty) {
        final blockedIds = blockedRes.map((r) => r['blocked_id'] as String).toList();
        final blockedProfilesRes = await _supabase
            .from('profiles')
            .select('id, full_name, username, avatar_url')
            .inFilter('id', blockedIds);
        for (var profile in blockedProfilesRes) {
          _blockedAccounts.add({
            'id': profile['id'] as String,
            'name': profile['full_name'] as String? ?? '',
            'username': profile['username'] as String? ?? '',
            'avatar': profile['avatar_url'] as String? ?? '',
          });
        }
      }

      // ── [2] Muted accounts — fetch profiles for muted IDs ────────────
      _mutedAccounts.clear();
      final mutedRes = results[2] as List<dynamic>;
      if (mutedRes.isNotEmpty) {
        final mutedIds = mutedRes.map((r) => r['muted_id'] as String).toList();
        final mutedProfilesRes = await _supabase
            .from('profiles')
            .select('id, full_name, username, avatar_url')
            .inFilter('id', mutedIds);
        for (var profile in mutedProfilesRes) {
          _mutedAccounts.add({
            'id': profile['id'] as String,
            'name': profile['full_name'] as String? ?? '',
            'username': profile['username'] as String? ?? '',
            'avatar': profile['avatar_url'] as String? ?? '',
          });
        }
      }

      // ── [3] Active sessions (depends on profile) ──────────────────────
      await fetchActiveSessions();

    } catch (e) {
      debugPrint('[GeneralSettings] Fetch settings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Evaluates whether a feature flag grants access.
  /// Handles both old 'true'/'false' string format and new JSON format.
  /// Also handles both TEXT and JSONB column types (val may be String or Map).
  bool _evaluateAccess(dynamic val, String uid, String? badgeType) {
    if (val == null) return false;
    try {
      final Map<String, dynamic> parsed = val is String
          ? Map<String, dynamic>.from(jsonDecode(val) as Map)
          : Map<String, dynamic>.from(val as Map);
      final access = parsed['access'];
      if (access == 'global') return true;
      if (access == 'verified' && badgeType != null && badgeType != 'none') return true;
      if (access == 'specific') {
        final users = parsed['users'];
        if (users is List && users.contains(uid)) return true;
      }
      return false;
    } catch (_) {
      return val.toString() == 'true';
    }
  }

  /// Loads ONLY feature flags from system_settings — isolated so any other
  /// query failure cannot prevent flags from being applied.
  Future<void> _loadFeatureFlags(String uid) async {
    try {
      final results = await Future.wait<dynamic>([
        _supabase
            .from('profiles')
            .select('verified_badge')
            .eq('id', uid)
            .maybeSingle() as Future<dynamic>,
        _supabase
            .from('system_settings')
            .select('key, value')
            .inFilter('key', [
          'enable_voice_posts',
          'enable_tiered_badges',
          'enable_algorithmic_priority',
          'enable_anonymous_posting',
        ]) as Future<dynamic>,
      ]);

      final profileRes = results[0] as Map<String, dynamic>?;
      final String? badgeType = profileRes?['verified_badge'] as String?;
      final sysRes = results[1] as List<dynamic>;

      debugPrint('[FeatureFlags] _loadFeatureFlags: ${sysRes.length} rows, badge=$badgeType');

      for (var row in sysRes) {
        final key = row['key'] as String;
        final isEnabled = _evaluateAccess(row['value'], uid, badgeType);
        debugPrint('[FeatureFlags] $key => $isEnabled (raw: ${row['value']})');
        if (key == 'enable_voice_posts') {
          _isVoicePostEnabled = isEnabled;
        } else if (key == 'enable_tiered_badges') {
          _isTieredBadgesEnabled = isEnabled;
        } else if (key == 'enable_algorithmic_priority') {
          _isAlgorithmicPriorityEnabled = isEnabled;
        } else if (key == 'enable_anonymous_posting') {
          _isAnonymousPostingEnabled = isEnabled;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[FeatureFlags] _loadFeatureFlags error: $e');
    }
  }

  /// Public refresh of feature flags — delegates to the shared _loadFeatureFlags.
  /// Call this when opening CreateThreadScreen or on app resume.
  Future<void> refreshFeatureFlags() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    await _loadFeatureFlags(uid);
  }

  Future<void> updatePrivacy({
    bool? isPrivateAccount,
    String? allowMentionsFrom,
    bool? filterAdultContent,
    bool? autoplayVideos,
    bool? isActiveStatusEnabled,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    if (isPrivateAccount != null) _isPrivateAccount = isPrivateAccount;
    if (allowMentionsFrom != null) _allowMentionsFrom = allowMentionsFrom;
    if (filterAdultContent != null) _filterAdultContent = filterAdultContent;
    if (autoplayVideos != null) _autoplayVideos = autoplayVideos;
    if (isActiveStatusEnabled != null) _isActiveStatusEnabled = isActiveStatusEnabled;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (isPrivateAccount != null) updates['is_private'] = isPrivateAccount;
      if (allowMentionsFrom != null) updates['allow_mentions'] = allowMentionsFrom;
      if (filterAdultContent != null) updates['filter_adult'] = filterAdultContent;
      if (autoplayVideos != null) updates['autoplay_videos'] = autoplayVideos;
      if (isActiveStatusEnabled != null) updates['is_active_status_enabled'] = isActiveStatusEnabled;

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', uid);
      }
    } catch (e) {
      debugPrint('[GeneralSettings] Update privacy error: $e');
    }
  }

  // Security State
  bool _isTwoFactorEnabled = false;
  bool get isTwoFactorEnabled => _isTwoFactorEnabled;

  void toggleTwoFactor(bool val) {
    _isTwoFactorEnabled = val;
    notifyListeners();
  }

  final List<Map<String, String>> _activeSessions = [
    {'id': '1', 'device': 'Chrome (Windows 11)', 'location': 'Dhaka, Bangladesh', 'status': 'Active now'},
    {'id': '2', 'device': 'iPhone 15 Pro', 'location': 'Chittagong, Bangladesh', 'status': 'Last active 2 hours ago'},
    {'id': '3', 'device': 'Pixel 8 Pro', 'location': 'Sylhet, Bangladesh', 'status': 'Last active 1 day ago'},
  ];
  List<Map<String, String>> get activeSessions => _activeSessions;

  Future<void> fetchActiveSessions() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedSessionId = prefs.getString('current_session_id');
      if (cachedSessionId == null) {
        cachedSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
        await prefs.setString('current_session_id', cachedSessionId);
      }

      // Determine device name
      String deviceName = 'Web Client';
      if (!kIsWeb) {
        deviceName = defaultTargetPlatform == TargetPlatform.android
            ? 'Android Device'
            : (defaultTargetPlatform == TargetPlatform.iOS ? 'iOS Device' : 'Desktop App');
      }

      // Sync/Upsert this session in database
      try {
        final existing = await _supabase
            .from('user_sessions')
            .select('id')
            .eq('id', cachedSessionId)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('user_sessions').insert({
            'id': cachedSessionId,
            'user_id': uid,
            'device_name': deviceName,
            'location': 'Dhaka, Bangladesh',
            'status': 'Active now',
          });
        } else {
          await _supabase.from('user_sessions').update({
            'last_active': DateTime.now().toUtc().toIso8601String(),
            'status': 'Active now',
          }).eq('id', cachedSessionId);
        }
      } catch (dbError) {
        debugPrint('[GeneralSettings] Sync current session to DB failed (falling back): $dbError');
      }

      // Fetch all sessions
      final res = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', uid)
          .order('last_active', ascending: false);

      final List<dynamic> data = res as List<dynamic>;
      
      // If we are logged in, but our current session is not in the fetched data, we were revoked!
      final hasCurrentSession = data.any((item) => item['id'] == cachedSessionId);
      if (!hasCurrentSession && data.isNotEmpty) {
        debugPrint('[GeneralSettings] Current session was revoked!');
        await _supabase.auth.signOut();
        return;
      }

      _activeSessions.clear();
      for (var item in data) {
        final String sessionId = item['id'] as String;
        final bool isCurrent = sessionId == cachedSessionId;
        _activeSessions.add({
          'id': sessionId,
          'device': item['device_name'] as String? ?? 'Unknown Device',
          'location': item['location'] as String? ?? 'Unknown Location',
          'status': isCurrent ? 'Active now' : _formatLastActive(item['last_active'] as String?),
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[GeneralSettings] fetchActiveSessions error: $e');
    }
  }

  String _formatLastActive(String? isoString) {
    if (isoString == null) return 'Last active unknown';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        return 'Last active just now';
      } else if (diff.inMinutes < 60) {
        return 'Last active ${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return 'Last active ${diff.inHours}h ago';
      } else {
        return 'Last active ${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Last active recently';
    }
  }

  Future<void> revokeSession(String id) async {
    _activeSessions.removeWhere((session) => session['id'] == id);
    notifyListeners();

    final uid = _currentUid;
    if (uid.isNotEmpty) {
      try {
        await _supabase.from('user_sessions').delete().eq('id', id);
      } catch (e) {
        debugPrint('[GeneralSettings] revokeSession error: $e');
      }
    }
  }

  // Saved Threads State
  // Note: Real saved posts are fetched via DatabaseService.fetchSavedPosts()
  // This list is kept for any legacy usage but starts empty.
  final List<Map<String, dynamic>> _savedThreads = [];
  List<Map<String, dynamic>> get savedThreads => _savedThreads;

  void unsaveThread(String id) {
    _savedThreads.removeWhere((thread) => thread['id'] == id);
    notifyListeners();
  }

  // Blocked Accounts State
  final List<Map<String, String>> _blockedAccounts = [];
  List<Map<String, String>> get blockedAccounts => _blockedAccounts;

  Future<void> unblockAccount(String id) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    try {
      await _supabase
          .from('blocks')
          .delete()
          .eq('blocker_id', uid)
          .eq('blocked_id', id);

      _blockedAccounts.removeWhere((account) => account['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[GeneralSettings] Unblock user error: $e');
    }
  }

  Future<bool> blockAccount(String queryText) async {
    final uid = _currentUid;
    if (uid.isEmpty) return false;

    try {
      // Find user matching username or full name
      final searchRes = await _supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('username.ilike.%$queryText%,full_name.ilike.%$queryText%')
          .limit(1)
          .maybeSingle();

      if (searchRes == null) {
        return false;
      }

      final targetId = searchRes['id'] as String;
      if (targetId == uid) {
        throw Exception("You cannot block yourself.");
      }

      // Add to database
      await _supabase.from('blocks').upsert({
        'blocker_id': uid,
        'blocked_id': targetId,
      }, onConflict: 'blocker_id, blocked_id');

      // Update local cache list
      _blockedAccounts.removeWhere((account) => account['id'] == targetId);
      _blockedAccounts.add({
        'id': targetId,
        'name': searchRes['full_name'] as String? ?? '',
        'username': searchRes['username'] as String? ?? '',
        'avatar': searchRes['avatar_url'] as String? ?? '',
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GeneralSettings] Block account error: $e');
      rethrow;
    }
  }

  // Muted Accounts State
  final List<Map<String, String>> _mutedAccounts = [];
  List<Map<String, String>> get mutedAccounts => _mutedAccounts;

  Future<void> unmuteAccount(String id) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    try {
      await _supabase
          .from('mutes')
          .delete()
          .eq('muter_id', uid)
          .eq('muted_id', id);

      _mutedAccounts.removeWhere((account) => account['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[GeneralSettings] Unmute user error: $e');
    }
  }

  Future<bool> muteAccount(String queryText) async {
    final uid = _currentUid;
    if (uid.isEmpty) return false;

    try {
      // Find user matching username or full name
      final searchRes = await _supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('username.ilike.%$queryText%,full_name.ilike.%$queryText%')
          .limit(1)
          .maybeSingle();

      if (searchRes == null) {
        return false;
      }

      final targetId = searchRes['id'] as String;
      if (targetId == uid) {
        throw Exception("You cannot mute yourself.");
      }

      // Add to database
      await _supabase.from('mutes').upsert({
        'muter_id': uid,
        'muted_id': targetId,
      });

      // Update local cache list
      _mutedAccounts.removeWhere((account) => account['id'] == targetId);
      _mutedAccounts.add({
        'id': targetId,
        'name': searchRes['full_name'] as String? ?? '',
        'username': searchRes['username'] as String? ?? '',
        'avatar': searchRes['avatar_url'] as String? ?? '',
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GeneralSettings] Mute account error: $e');
      rethrow;
    }
  }

  Future<void> blockUserById(String targetId) async {
    final uid = _currentUid;
    if (uid.isEmpty || targetId == uid) return;

    try {
      // 1. Add block record
      await _supabase.from('blocks').upsert({
        'blocker_id': uid,
        'blocked_id': targetId,
      }, onConflict: 'blocker_id, blocked_id');

      // 2. Remove follows in BOTH directions (standard block behavior)
      //    - I unfollow them
      //    - They unfollow me
      await Future.wait([
        _supabase
            .from('follows')
            .delete()
            .eq('follower_id', uid)
            .eq('following_id', targetId),
        _supabase
            .from('follows')
            .delete()
            .eq('follower_id', targetId)
            .eq('following_id', uid),
      ]);

      // 3. Refresh local state
      await fetchSettings();
    } catch (e) {
      debugPrint('[GeneralSettings] Block user by ID error: $e');
      rethrow;
    }
  }

  Future<void> muteUserById(String targetId) async {
    final uid = _currentUid;
    if (uid.isEmpty || targetId == uid) return;

    try {
      // Add to database
      await _supabase.from('mutes').upsert({
        'muter_id': uid,
        'muted_id': targetId,
      });

      // Update local settings state
      await fetchSettings();
    } catch (e) {
      debugPrint('[GeneralSettings] Mute user by ID error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, String>>> searchProfiles(String queryText) async {
    final uid = _currentUid;
    if (uid.isEmpty || queryText.trim().isEmpty) return [];

    try {
      final res = await _supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('username.ilike.%${queryText.trim()}%,full_name.ilike.%${queryText.trim()}%')
          .neq('id', uid)
          .limit(20);

      final List<dynamic> data = res as List<dynamic>;
      return data.map<Map<String, String>>((item) {
        return {
          'id': item['id'] as String? ?? '',
          'name': item['full_name'] as String? ?? '',
          'username': item['username'] as String? ?? '',
          'avatar': item['avatar_url'] as String? ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('[GeneralSettings] Search profiles error: $e');
      return [];
    }
  }

  // Theme Settings
  bool _isDarkTheme = true;

  bool get isDarkTheme => _isDarkTheme;
  ThemeMode get themeMode => _isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme(bool val) async {
    _isDarkTheme = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', val);
  }

  // Language Settings
  Locale? _appLocale;
  Locale? get appLocale => _appLocale;

  Future<void> changeLanguage(Locale locale) async {
    _appLocale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
  }

  // Low Data Mode
  bool _lowDataMode = false;
  bool get lowDataMode => _lowDataMode;

  Future<void> toggleLowDataMode(bool val) async {
    _lowDataMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lowDataMode', val);
  }
}
