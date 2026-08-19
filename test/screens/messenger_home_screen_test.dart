import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dak/screens/messenger/messenger_home_screen.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/core/injection.dart';
import 'package:dak/features/chat/domain/repositories/chat_repository.dart';
import 'package:dak/features/chat/domain/usecases/get_active_chats_use_case.dart';
import 'package:dak/core/error/failures.dart';

class FakeDatabaseService extends DatabaseService {
  final StreamController<Map<String, dynamic>> _streamController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get incomingNotificationStream => _streamController.stream;

  @override
  String? get currentActiveChatUserId => null;

  Future<List<Profile>> fetchSuggestedProfiles({int limit = 10}) async => [];

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}

class FakeChatRepository implements IChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchActiveChats() async {
    return Right([
      {
        'profile': Profile(id: 'u1', fullName: 'John Doe', username: 'johndoe', avatarUrl: ''),
        'lastMessage': 'Hello there!',
        'lastMessageTime': '10:30 AM',
        'unreadCount': 2,
        'timeRaw': DateTime.now().toIso8601String(),
      }
    ]);
  }
}


class MockGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isActiveStatusEnabled => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!sl.isRegistered<SupabaseClient>()) {
      sl.registerSingleton<SupabaseClient>(
        SupabaseClient('https://mock.supabase.co', 'mock-anon-key'),
      );
    }
    final fakeChatRepo = FakeChatRepository();
    if (!sl.isRegistered<IChatRepository>()) {
      sl.registerSingleton<IChatRepository>(fakeChatRepo);
    }
    if (!sl.isRegistered<GetActiveChatsUseCase>()) {
      sl.registerSingleton<GetActiveChatsUseCase>(
        GetActiveChatsUseCase(fakeChatRepo),
      );
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

  group('MessengerHomeScreen Tests', () {
    late FakeDatabaseService mockDb;

    setUp(() {
      mockDb = FakeDatabaseService();
    });

    tearDown(() {
      mockDb.dispose();
    });

    Widget buildApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseService>.value(value: mockDb),
          ChangeNotifierProvider<GeneralSettingsProvider>(create: (_) => MockGeneralSettingsProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MessengerHomeScreen(),
          ),
        ),
      );
    }

    testWidgets('Renders chat home screen and loads active chats list', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MessengerHomeScreen), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Hello there!'), findsOneWidget);
    });
  });
}
