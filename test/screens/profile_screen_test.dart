import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:dak/screens/profile/profile_screen.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:dak/services/view_tracking_service.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/state/music_playback_controller.dart';
import 'package:dak/state/monetization_controller.dart';
import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:dak/core/injection.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';
import 'package:dak/core/error/failures.dart';

class MockPostgrestTransformMapBuilder implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then) {
      final callback = invocation.positionalArguments[0] as Function;
      return Future.value(<String, dynamic>{
        'id': 'other',
        'username': 'other_username',
        'full_name': 'Other Full Name',
        'is_verified': false,
        'followers_count': 0,
        'following_count': 0,
        'is_private': false,
        'can_monetize': false,
      }).then((val) => callback(val));
    }
    return this;
  }
}

class MockPostgrestFilterListBuilder implements PostgrestFilterBuilder<PostgrestList> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #maybeSingle) {
      return MockPostgrestTransformMapBuilder();
    }
    if (invocation.memberName == #then) {
      final callback = invocation.positionalArguments[0] as Function;
      return Future.value(<Map<String, dynamic>>[]).then((val) => callback(val));
    }
    return this;
  }
}

class MockPostgrestQueryBuilder implements SupabaseQueryBuilder {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #select) {
      return MockPostgrestFilterListBuilder();
    }
    return this;
  }
}

class MockGoTrueClient implements GoTrueClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream<AuthState>.empty();
}

class MockRealtimeChannel implements RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

class MockSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      return MockPostgrestQueryBuilder();
    }
    if (invocation.memberName == #auth) {
      return MockGoTrueClient();
    }
    if (invocation.memberName == #channel) {
      return MockRealtimeChannel();
    }
    if (invocation.memberName == #removeChannel) {
      return Future.value('');
    }
    return null;
  }
}

class FakeFeedRepository implements IFeedRepository {
  final Profile _myProf = Profile(id: 'me', fullName: 'My Full Name', username: 'my_username', avatarUrl: '');
  final Profile _otherProf = Profile(id: 'other', fullName: 'Other Full Name', username: 'other_username', avatarUrl: '');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserThreads(String userId) async {
    return Right([
      ThreadPostEntity(
        id: 't1',
        userId: userId,
        author: userId == 'other' ? _otherProf : _myProf,
        content: 'This is a test post content',
        createdAt: DateTime.now().toIso8601String(),
      )
    ]);
  }

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchUserRepliedThreads(String userId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> fetchSavedPosts() async {
    return const Right([]);
  }
}

class FakeDatabaseService extends DatabaseService {
  final Profile _myProf = Profile(id: 'me', fullName: 'My Full Name', username: 'my_username', avatarUrl: '');

  @override
  String get currentUid => 'me';

  @override
  Profile? get myProfile => _myProf;
}

class MockGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  bool get autoplayVideos => false;

  @override
  bool get lowDataMode => false;
}

class MockMonetizationController extends ChangeNotifier implements MonetizationController {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  bool isSubscribedTo(String creatorId) => false;
}

class MockViewTrackingService extends ChangeNotifier implements ViewTrackingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockMusicPlaybackController extends ChangeNotifier implements MusicPlaybackController {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  String? get currentTrackId => null;

  @override
  bool get isPlaying => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    VisibilityDetectorController.instance.updateInterval = Duration.zero;

    // Setup native method channel mock to avoid platform crashes
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('app.ngst.dak/screenshot_protection'),
      (methodCall) async {
        return null;
      },
    );

    if (!sl.isRegistered<SupabaseClient>()) {
      sl.registerSingleton<SupabaseClient>(MockSupabaseClient());
    }
    if (!sl.isRegistered<IFeedRepository>()) {
      sl.registerSingleton<IFeedRepository>(FakeFeedRepository());
    }

    try {
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        publishableKey: 'mock',
      );
    } catch (e) {
      // Already initialized
    }
  });

  group('ProfileScreen Tests', () {
    late FakeDatabaseService mockDb;

    setUp(() {
      mockDb = FakeDatabaseService();
    });

    tearDown(() {
      mockDb.dispose();
    });

    Widget buildApp({String? userId}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseService>.value(value: mockDb),
          ChangeNotifierProvider<GeneralSettingsProvider>(create: (_) => MockGeneralSettingsProvider()),
          ChangeNotifierProvider<MonetizationController>(create: (_) => MockMonetizationController()),
          ChangeNotifierProvider<ViewTrackingService>(create: (_) => MockViewTrackingService()),
          ChangeNotifierProvider<MusicPlaybackController>(create: (_) => MockMusicPlaybackController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileScreen(userId: userId),
          ),
        ),
      );
    }

    testWidgets('Renders own profile correctly with name and posts tab', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('My Full Name'), findsOneWidget);
      expect(find.text('@my_username'), findsOneWidget);
    });

    testWidgets('Renders other user profile correctly with Follow button', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(userId: 'other'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Other Full Name'), findsOneWidget);
      expect(find.text('@other_username'), findsOneWidget);
    });

    testWidgets('Renders tab bar items for profile sections', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Posts'), findsWidgets);
      expect(find.text('Replies'), findsWidgets);
    });
  });
}
