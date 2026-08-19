import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dak/models/thread_post.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/widgets/comment_item.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockDatabaseService extends ChangeNotifier implements DatabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);



  @override
  Profile? get myProfile => Profile(id: 'my_uid', username: 'my_user', fullName: 'My User');

  @override
  String get currentUid => 'my_uid';
}

class MockGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

class MockSupabaseClient implements sb.SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    getIt.reset();
    getIt.registerSingleton<sb.SupabaseClient>(MockSupabaseClient());
  });

  testWidgets('CommentItem renders content and commenter name correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockPost = ThreadPost(
      id: 'post123',
      userId: 'user123',
      author: Profile(id: 'user123', username: 'author', fullName: 'Author'),
      content: 'Original Post',
      createdAt: DateTime.now().toIso8601String(),
    );

    final mockComment = {
      'id': 'comment_abc',
      'user_id': 'commenter_xyz',
      'content': 'This is a test comment!',
      'created_at': DateTime.now().toIso8601String(),
      'profiles': {
        'id': 'commenter_xyz',
        'username': 'commenter_user',
        'full_name': 'Commenter Name',
        'avatar_url': null,
        'is_verified': false,
        'badge_type': null,
      },
      'author': Profile(
        id: 'commenter_xyz',
        username: 'commenter_user',
        fullName: 'Commenter Name',
      ),
      'likes_count': 5,
      'replies_count': 2,
    };

    final mockDbService = MockDatabaseService();

    await tester.pumpWidget(
      ChangeNotifierProvider<GeneralSettingsProvider>.value(
        value: MockGeneralSettingsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: CommentItem(
              comment: mockComment,
              effectiveThreadId: 'post123',
              dbService: mockDbService,
              post: mockPost,
              isPostAuthor: false,
              index: 0,
              isLast: true,
              onReloadComments: () {},
              onCommentDeleted: (_) {},
              onCommentHidden: (_) {},
            ),
          ),
        ),
      ),
    );

    // Verify comment text content is displayed
    expect(
      find.byWidgetPredicate((widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('This is a test comment!')),
      findsOneWidget,
    );

    // Verify commenter full name is displayed
    expect(find.textContaining('Commenter Name'), findsOneWidget);

    // Verify likes count text is rendered
    expect(find.text('5'), findsOneWidget);
  });
}
