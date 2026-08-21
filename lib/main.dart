import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/community_service.dart';
import 'services/notification_settings_provider.dart';
import 'services/chat_settings_provider.dart';
import 'services/general_settings_provider.dart';
import 'services/view_tracking_service.dart';
import 'state/verification_controller.dart';
import 'state/monetization_controller.dart';
import 'state/music_playback_controller.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
import 'services/log_service.dart';
import 'package:go_router/go_router.dart';
import 'core/injection.dart';
import 'core/config/app_config.dart';
import 'core/security/pinned_http_client.dart';
import 'dart:async';
import 'widgets/custom_error_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  runZonedGuarded(() async {
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
    WidgetsFlutterBinding.ensureInitialized();
    LogService.info("Pigeon App starting initialization...", tag: "MAIN");

    // Set custom error widget builder for UI rendering crashes
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorScreen(details: details);
    };

    // Initialize Firebase (Mobile/Desktop platforms)
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        
        // Pass all uncaught framework errors to Crashlytics
        FlutterError.onError = (FlutterErrorDetails details) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e) {
        debugPrint("Firebase initialization failed: $e");
      }
    }

    // Initialize Supabase
    LogService.info("Initializing Supabase Client...", tag: "SUPABASE");
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      httpClient: kIsWeb ? null : PinnedHttpClient(),
    );
    LogService.info("Supabase Client initialized successfully", tag: "SUPABASE");

    // Initialize dependency injection
    LogService.info("Initializing Dependency Injection Container...", tag: "DI");
    await initInjection();
    LogService.info("Dependency Injection Container initialized successfully", tag: "DI");

    // Initialize notifications
    try {
      LogService.info("Initializing Notification Services...", tag: "NOTIFICATION");
      await LocalNotificationService.initialize();
      await PushNotificationService().initialize();
      LogService.info("Notification Services initialized successfully", tag: "NOTIFICATION");
    } catch (e) {
      LogService.error("Notification initialization failed: $e", tag: "NOTIFICATION");
    }
    LogService.info("All services initialized. Launching app widget tree.", tag: "MAIN");

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => DatabaseService()),
          ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
          ChangeNotifierProvider(create: (_) => ChatSettingsProvider()),
          ChangeNotifierProvider(create: (_) => GeneralSettingsProvider()),
          ChangeNotifierProvider(create: (_) => VerificationController()),
          ChangeNotifierProvider(create: (_) => MonetizationController()),
          ChangeNotifierProvider(create: (_) => MusicPlaybackController()),
          ChangeNotifierProvider(create: (_) => CommunityService()),
          ChangeNotifierProvider(create: (_) => ViewTrackingService()),
        ],
        child: const PigeonApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint("Uncaught global error: $error");
    debugPrint(stackTrace.toString());
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    } catch (_) {}
  });
}


class PigeonApp extends StatefulWidget {
  const PigeonApp({super.key});

  @override
  State<PigeonApp> createState() => _PigeonAppState();
}

class _PigeonAppState extends State<PigeonApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(context);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GeneralSettingsProvider>(context);

    return MaterialApp.router(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Pigeon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      locale: settingsProvider.appLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  // Remove scrollbar from all scrollable widgets
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  // Globally remove the stretch/sponge overscroll indicator on Android
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
