import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dak/models/thread_post.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/widgets/custom_thread_card.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:dak/state/music_playback_controller.dart';
import 'package:dak/state/monetization_controller.dart';
import 'package:dak/services/view_tracking_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:visibility_detector/visibility_detector.dart';

class MockDatabaseService extends ChangeNotifier implements DatabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  bool isBlocked(String userId) => false;

  @override
  bool isBlockedByMe(String userId) => false;

  @override
  String get currentUid => 'user123';

  @override
  ThreadPost getLatestPost(ThreadPost post) => post;

  @override
  bool isPostDeleted(String postId) => false;

  @override
  bool isSaved(String postId) => false;

  @override
  bool isReposted(String postId) => false;
}

class MockGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

class MockMusicPlaybackController extends ChangeNotifier implements MusicPlaybackController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMonetizationController extends ChangeNotifier implements MonetizationController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);



  @override
  bool isSubscribedTo(String creatorId) => false;
}

class MockViewTrackingService extends ChangeNotifier implements ViewTrackingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  void trackView(String postId) {}
}

class MockSupabaseClient implements sb.SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  final getIt = GetIt.instance;

  setUp(() {
    getIt.reset();
    getIt.registerSingleton<sb.SupabaseClient>(MockSupabaseClient());
  });

  testWidgets('CustomThreadCard renders content and author details correctly', (WidgetTester tester) async {
    // Set large physical size and devicePixelRatio = 1.0 to guarantee enough logical width and avoid layout overflows
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockPost = ThreadPost(
      id: 'post123',
      userId: 'user123',
      author: Profile(
        id: 'user123',
        username: 'john_doe',
        fullName: 'John Doe',
      ),
      content: 'This is a test thread post',
      createdAt: DateTime.now().toIso8601String(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseService>.value(value: MockDatabaseService()),
          ChangeNotifierProvider<GeneralSettingsProvider>.value(value: MockGeneralSettingsProvider()),
          ChangeNotifierProvider<MusicPlaybackController>.value(value: MockMusicPlaybackController()),
          ChangeNotifierProvider<MonetizationController>.value(value: MockMonetizationController()),
          ChangeNotifierProvider<ViewTrackingService>.value(value: MockViewTrackingService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(0.7)),
              child: SingleChildScrollView(
                child: CustomThreadCard(post: mockPost),
              ),
            ),
          ),
        ),
      ),
    );

    // Verify content text is displayed
    expect(
      find.byWidgetPredicate((widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('This is a test thread post')),
      findsOneWidget,
    );
    
    // Verify author's full name is displayed (use textContaining due to trailing space in RichText/TextSpan rendering)
    expect(find.textContaining('John Doe'), findsOneWidget);

    // Verify username is displayed (use textContaining due to concatenation of TextSpans inside RichText)
    expect(find.textContaining('@john_doe'), findsOneWidget);
  });
}
