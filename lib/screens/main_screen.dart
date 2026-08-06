import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'feed_screen.dart';
import 'search_explore_screen.dart';
import 'notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'create_thread_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../state/monetization_controller.dart';
import '../services/presence_service.dart';
import '../services/general_settings_provider.dart';
import 'messenger/messenger_home_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/main/main_drawer.dart';
import '../widgets/main/main_bottom_nav.dart';
import '../widgets/main/trending_topics_desktop.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  StreamSubscription? _notificationSubscription;
  bool _showBars = true;
  Timer? _scrollStopTimer;
  bool _isOffline = false;
  Timer? _connectivityTimer;

  void _startScrollStopTimer() {
    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_showBars) {
        setState(() {
          _showBars = true;
        });
      }
    });
  }

  void _cancelScrollStopTimer() {
    _scrollStopTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        PresenceService().initialize(currentUser.id);
        PresenceService().updatePage('/home');
        Provider.of<MonetizationController>(context, listen: false).fetchMySubscriptions(currentUser.id);
        Provider.of<MonetizationController>(context, listen: false).fetchGlobalStatus();
        Provider.of<GeneralSettingsProvider>(context, listen: false).fetchSettings();
      }

      dbService.fetchVerificationPlans();

      _notificationSubscription = dbService.incomingNotificationStream.listen((event) {
        if (mounted) {
          if (event['type'] == 'message') {
            final currentActiveChatId = dbService.currentActiveChatUserId;
            final senderId = event['sender_id'];
            if (currentActiveChatId != null && currentActiveChatId == senderId) {
              return; // Do not show banner, because we are inside this exact chat!
            }
          }
          _showInAppNotificationBanner(event);
          dbService.fetchMyProfile();
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _scrollStopTimer?.cancel();
    _connectivityTimer?.cancel();
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted && _isOffline != !hasConnection) {
        setState(() {
          _isOffline = !hasConnection;
        });
      }
    } on SocketException catch (_) {
      if (mounted && !_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  Widget _buildOfflineBanner() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _isOffline ? 0 : -50,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "You are offline. Showing cached content.",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInAppNotificationBanner(Map<String, dynamic> event) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: -100.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: (1 - (value / -100)).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.cardBg.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border.withValues(alpha: 0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.primaryAccent,
                              context.primaryAccent.withValues(alpha: 0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(
                          event['type'] == 'message' ? Icons.forum_rounded : Icons.notifications_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event['title'] as String,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              event['body'] as String,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => overlayEntry.remove(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.scaffoldBg.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, size: 16, color: context.textSecondary),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);

    const pages = ['/home', '/explore', '/messages', '/notifications', '/profile'];
    if (index >= 0 && index < pages.length) {
      PresenceService().updatePage(pages[index]);
    }
  }

  Widget _buildRightSidebar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border.withValues(alpha: 0.5), width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search, size: 20, color: context.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setTab(1), // Go to search screen
                      child: Text(
                        "Search Pigeon...",
                        style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Trending Topics",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: TrendingTopicsListDesktop(onTabChanged: setTab)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (!authService.isUserSignedIn) {
      return Scaffold(backgroundColor: context.scaffoldBg);
    }
    
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    final List<Widget> screens = [
      FeedScreen(
        onNavigateToChaStation: () => setTab(2),
        onNavigateToCreate: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
          );
        },
      ),
      const SearchExploreScreen(),
      const MessengerHomeScreen(),
      NotificationsScreen(isActive: _currentIndex == 3),
      const ProfileScreen(),
    ];

    Widget mainBody = SafeArea(
      bottom: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.metrics.axis == Axis.vertical) {
              final double scrollDelta = notification.scrollDelta ?? 0;
              if (scrollDelta > 2.0) {
                if (_showBars) setState(() { _showBars = false; });
                _startScrollStopTimer();
              } else if (scrollDelta < -2.0) {
                if (!_showBars) setState(() { _showBars = true; });
                _cancelScrollStopTimer();
              }
              if (notification.metrics.pixels <= 0) {
                if (!_showBars) setState(() { _showBars = true; });
                _cancelScrollStopTimer();
              }
            }
          } else if (notification is ScrollEndNotification) {
            if (!_showBars) _startScrollStopTimer();
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            if (index != _currentIndex) {
              setState(() {
                _currentIndex = index;
                _showBars = true;
              });
            }
          },
          children: screens,
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: context.scaffoldBg,
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Sidebar
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: context.border, width: 0.5)),
                  ),
                  child: Consumer<DatabaseService>(
                    builder: (context, dbService, _) {
                      return MainDrawer(
                        currentIndex: _currentIndex,
                        myProfile: dbService.myProfile,
                        isDesktop: true,
                        unreadMessagesCount: dbService.unreadMessagesCount,
                        unreadNotificationsCount: dbService.unreadNotificationsCount,
                        onTabChanged: setTab,
                      );
                    },
                  ),
                ),

                // Center Feed
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: mainBody,
                    ),
                  ),
                ),

                // Right Sidebar
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: context.border, width: 0.5)),
                  ),
                  child: _buildRightSidebar(context),
                ),
              ],
            ),
            _buildOfflineBanner(),
          ],
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: context.scaffoldBg,
      extendBody: true,
      drawer: Drawer(
        backgroundColor: context.scaffoldBg,
        child: Consumer<DatabaseService>(
          builder: (context, dbService, _) {
            return MainDrawer(
              currentIndex: _currentIndex,
              myProfile: dbService.myProfile,
              isDesktop: false,
              unreadMessagesCount: dbService.unreadMessagesCount,
              unreadNotificationsCount: dbService.unreadNotificationsCount,
              onTabChanged: setTab,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          mainBody,
          _buildOfflineBanner(),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 4)
          ? AnimatedScale(
              scale: _showBars ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: ScaleTransition(
                scale: TweenSequence<double>([
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 25),
                  TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.12), weight: 45),
                  TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
                ]).animate(_fabAnimationController),
                child: FloatingActionButton(
                  heroTag: 'main_fab',
                  tooltip: 'Create post',
                  backgroundColor: const Color(0xFF1E824C),
                  shape: const CircleBorder(),
                  elevation: 3,
                  mini: false,
                  onPressed: () {
                    _fabAnimationController.forward(from: 0.0);
                    Future.delayed(const Duration(milliseconds: 180), () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateThreadScreen()),
                        );
                      }
                    });
                  },
                  child: const Icon(CupertinoIcons.create, color: Colors.white, size: 24),
                ),
              ),
            )
          : null,
      bottomNavigationBar: AnimatedSlide(
        offset: _showBars ? Offset.zero : const Offset(0, 1.3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: MainBottomNav(
          currentIndex: _currentIndex,
          onTabChanged: setTab,
        ),
      ),
    );
  }
}
