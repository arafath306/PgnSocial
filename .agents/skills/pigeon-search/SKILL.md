---
name: pigeon-search
description: Use when implementing or modifying Pigeon's search functionality including user search, post search, trending topics, explore screen, search debouncing, filtering, or search result display.
---

# Pigeon Search

## Use this skill when

- modifying `SearchExploreScreen`
- changing user/profile search
- changing post/thread search
- modifying trending topics
- changing explore/discover content
- changing search debounce behavior
- modifying search filters (category, timeframe, sort)
- changing recommended users display
- modifying `searchProfiles()` or `searchThreads()` in `search_ext.dart`

## Do not use this skill when

- working on feed unrelated to search
- changing notification or messaging features
- making unrelated Supabase schema changes

---

## Pigeon Search Architecture

**UI File:** `lib/screens/search_explore_screen.dart` (1803 lines)  
**Backend:** `lib/services/parts/search_ext.dart` (extension on `DatabaseService`)

---

## Backend: searchProfiles()

**Actual implementation in `search_ext.dart`:**

```dart
Future<List<Profile>> searchProfiles(String query) async {
  final response = await _supabase
      .from('profiles')
      .select()
      .or('username.ilike.%$query%,full_name.ilike.%$query%')
      .limit(20);
  
  // Filter out blocked profiles
  results.removeWhere((profile) => _blockedUserIds.contains(profile.id));
  
  // Sort: exact match first, then starts-with, then contains
  results.sort((a, b) { ... });
}
```

**Rules:**
- Searches `username` AND `full_name` (note: `full_name`, NOT `display_name`)
- Uses `ilike` for case-insensitive matching
- Hard limit: **20 results**
- Blocked users are filtered **client-side** after fetch
- Results are sorted: exact match → starts-with → contains

---

## Backend: searchThreads()

**Actual implementation in `search_ext.dart`:**

```dart
Future<List<ThreadPost>> searchThreads(String query, {
  String? communityId,
  List<String>? categories,
  String? timeframe,
  String? sortBy,
}) async {
```

Post search uses `ilike` on `content` column (NOT full-text search):

```dart
dbQuery = dbQuery.ilike('content', '%$query%');
```

Category filtering works by matching hashtags in content:
```dart
final orFilters = categories.map((c) => 'content.ilike.%#${c.trim()}%').join(',');
```

Timeframe filtering:
- `'Today'` → last 24 hours (`Duration(days: 1)`)
- `'This Week'` → last 7 days
- `'This Month'` → last 30 days

Sort options:
- `'Recent'` → `order('created_at', ascending: false)` (default)
- `'Popular'` → `order('likes_count', ascending: false)`

Hard limit: **20 results**

**Post-fetch filtering (client-side):**
- Remove blocked users' posts
- Remove muted users' posts
- Remove hidden posts (`isHiddenFromMe`)
- Remove private account posts where not following

---

## Search Screen State

Key state fields in `SearchExploreScreen`:

```dart
List<Profile> _searchResults = [];           // Account tab results
List<ThreadPost> _searchPostResults = [];     // Posts tab results
List<Profile> _recommended = [];             // Recommended users
List<Map<String, dynamic>> _trendingTopics = [];
bool _isLoading = false;
int _searchTabIndex = 0;                     // 0: Accounts, 1: Posts

// Filters
List<String> _selectedCategories = [];
String _selectedTimeframe = 'Today';
String _selectedSortBy = 'Recent';
bool _filtersApplied = false;

// Explore category chips
String _selectedCategoryChip = 'For you';
final List<String> _categoryChips = ['For you', 'Trending', 'News', 'Sports'];
```

---

## Search Debouncing

Pigeon uses `Timer` for debouncing:

```dart
Timer? _searchDebounceTimer;

void _onSearchChanged(String query) {
  _searchDebounceTimer?.cancel();
  _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
    _performSearch(query);
  });
}
```

**Rules:**
- Always cancel previous timer before creating new one
- Cancel timer in `dispose()`
- Do NOT query on every keystroke

---

## Recommended Users

**Backend:** `getRecommendedProfiles()` in `search_ext.dart`

```dart
// Returns newest users (by created_at), excluding self, limit 10
final response = await _supabase
    .from('profiles')
    .select()
    .neq('id', _currentUid)
    .order('created_at', ascending: false)
    .limit(10);

// Blocked users filtered client-side
results.removeWhere((profile) => _blockedUserIds.contains(profile.id));
```

**Known limitation:** Does NOT filter already-followed users. When improving recommendations, add follow filter.

---

## Storage Upload Path Convention

Post images use the `avatars` bucket (NOT a separate `post-media` bucket):

```
avatars/posts/{userId}/thread_{timestamp}.jpg
```

Chat media also uses `avatars` bucket:
```
avatars/{userId}/chat_{timestamp}.{extension}
```

Voice posts:
```
avatars/voice_posts/{userId}/voice_{timestamp}.{extension}
```

⚠️ All media uses the same `avatars` bucket — keep this consistent when adding new media types.

---

## AutomaticKeepAliveClientMixin

`SearchExploreScreen` uses `AutomaticKeepAliveClientMixin`:
```dart
class _SearchExploreScreenState extends State<SearchExploreScreen> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
```

This preserves state when the tab is switched. Do NOT remove this — it prevents redundant network calls on tab switches.

---

## Disposal Checklist

When modifying `SearchExploreScreen`, ensure these are disposed in `dispose()`:
- `_searchDebounceTimer?.cancel()`
- `_bannerTimer?.cancel()`
- `_searchController.dispose()`

---

## Empty States

Always handle:
- Empty query → show recommended users + trending topics
- Query present, no results → show "No results for {query}"
- Loading → `_isLoading = true` → show shimmer skeleton
- Error → catch silently returns `[]` — currently no retry UI

---

## Performance Notes

- Blocked/muted user filtering is done **client-side** after fetching — can return fewer than 20 results when filtered
- No full-text search index exists — `ilike '%query%'` will do a full table scan on large datasets
- Consider adding `pg_trgm` GIN index on `content` if post search becomes slow
- Profile search is on `username` and `full_name` — both should have indexes
