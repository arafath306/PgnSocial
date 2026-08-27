import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/verification_dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/routes.dart';
import '../../utils/app_theme.dart';
import '../profile/edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'security_settings_screen.dart';
import '../saved_posts_screen.dart';
import 'blocked_accounts_screen.dart';
import 'muted_accounts_screen.dart';
import 'help_center_screen.dart';
import 'about_settings_screen.dart';
import 'system_log_screen.dart';
import 'verification/verification_intro_screen.dart';
import 'verification/pending_screen.dart';
import '../../state/verification_controller.dart';
import '../../models/verification_request.dart';
import '../../state/monetization_controller.dart';
import '../profile/subscription_dashboard_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dak/l10n/generated/app_localizations.dart';
import 'account_status_screen.dart';
import '../../widgets/verification_badge.dart';
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSwitchToProfile;
  const SettingsScreen({super.key, this.onSwitchToProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Map<String, String> _languageNames = {
    'af': 'Afrikaans', 'sq': 'Albanian', 'am': 'Amharic', 'ar': 'Arabic', 'hy': 'Armenian',
    'az': 'Azerbaijani', 'eu': 'Basque', 'be': 'Belarusian', 'bn': 'Bengali', 'bs': 'Bosnian',
    'bg': 'Bulgarian', 'my': 'Burmese', 'ca': 'Catalan', 'zh': 'Chinese', 'hr': 'Croatian',
    'cs': 'Czech', 'da': 'Danish', 'nl': 'Dutch', 'en': 'English', 'et': 'Estonian',
    'fi': 'Finnish', 'fr': 'French', 'gl': 'Galician', 'ka': 'Georgian', 'de': 'German',
    'el': 'Modern Greek (1453-)', 'gu': 'Gujarati', 'he': 'Hebrew', 'hi': 'Hindi', 'hu': 'Hungarian',
    'is': 'Icelandic', 'id': 'Indonesian', 'it': 'Italian', 'ja': 'Japanese', 'kn': 'Kannada',
    'kk': 'Kazakh', 'km': 'Khmer', 'ko': 'Korean', 'ky': 'Kirghiz', 'lo': 'Lao',
    'lv': 'Latvian', 'lt': 'Lithuanian', 'mk': 'Macedonian', 'ms': 'Malay (macrolanguage)', 'ml': 'Malayalam',
    'mr': 'Marathi', 'mn': 'Mongolian', 'ne': 'Nepali (macrolanguage)', 'no': 'Norwegian', 'fa': 'Persian',
    'pl': 'Polish', 'pt': 'Portuguese', 'pa': 'Panjabi', 'ro': 'Romanian', 'ru': 'Russian',
    'sr': 'Serbian', 'si': 'Sinhala', 'sk': 'Slovak', 'sl': 'Slovenian', 'es': 'Spanish',
    'sw': 'Swahili (macrolanguage)', 'sv': 'Swedish', 'ta': 'Tamil', 'te': 'Telugu', 'th': 'Thai',
    'tr': 'Turkish', 'uk': 'Ukrainian', 'ur': 'Urdu', 'uz': 'Uzbek', 'vi': 'Vietnamese',
    'zu': 'Zulu', 'cy': 'Welsh', 'ha': 'Hausa', 'ig': 'Igbo', 'yo': 'Yoruba',
    'xh': 'Xhosa', 'om': 'Oromo', 'ti': 'Tigrinya', 'so': 'Somali', 'rw': 'Kinyarwanda',
    'ny': 'Chichewa', 'mg': 'Malagasy', 'sn': 'Shona', 'st': 'Southern Sotho', 'tn': 'Tswana',
    'ts': 'Tsonga', 've': 'Venda', 'nr': 'South Ndebele', 'ss': 'Swati', 'tk': 'Turkmen',
    'tg': 'Tajik', 'ps': 'Pushto', 'ku': 'Kurdish', 'sd': 'Sindhi', 'ug': 'Uighur'
  };


  void _handleLanguageTap(BuildContext context, GeneralSettingsProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenNotice = prefs.getBool('has_seen_lang_notice') ?? false;

    if (!hasSeenNotice && context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Notice',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          content: Text(
            'Language translation is a work in progress. Currently, only a few languages are fully translated. Please stay with us.',
            style: GoogleFonts.inter(color: context.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: GoogleFonts.inter(color: context.primaryAccent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      await prefs.setBool('has_seen_lang_notice', true);
    }
    
    if (context.mounted) {
      _showLanguageSelector(context, provider);
    }
  }

  void _showLanguageSelector(BuildContext context, GeneralSettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.selectLanguageTitle, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: AppLocalizations.supportedLocales.length,
                itemBuilder: (context, index) {
                  final locale = AppLocalizations.supportedLocales[index];
                  final langCode = locale.languageCode;
                  final isSelected = provider.appLocale?.languageCode == langCode || (provider.appLocale == null && langCode == 'en');
                  
                  return ListTile(
                    title: Text(
                      _languageNames[langCode] ?? langCode,
                      style: GoogleFonts.inter(
                        color: isSelected ? context.primaryAccent : context.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check_circle_rounded, color: context.primaryAccent) : null,
                    onTap: () {
                      provider.changeLanguage(locale);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MonetizationController>(context, listen: false).fetchGlobalStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (!authService.isUserSignedIn) {
      return Scaffold(backgroundColor: context.scaffoldBg);
    }
    
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = context.select((DatabaseService db) => db.myProfile);
    final monetization = Provider.of<MonetizationController>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _isSearching
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
                onPressed: _stopSearch,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                ),
                style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16),
                cursorColor: context.primaryAccent,
              )
            : Text(
                AppLocalizations.of(context)!.settingsTabTitle,
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search_rounded, color: context.textPrimary),
              onPressed: _startSearch,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: _isSearching ? _buildSearchResults(context, myProfile, monetization, dbService) : ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // --- Profile Header Card ---
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              if (widget.onSwitchToProfile != null) {
                widget.onSwitchToProfile!();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    backgroundImage: myProfile?.avatarUrl != null && myProfile!.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(myProfile.avatarUrl!)
                        : null,
                    child: (myProfile?.avatarUrl == null || myProfile!.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, color: context.textPrimary)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                myProfile?.fullName ?? 'User',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (myProfile?.isVerified == true) ...[
                              const SizedBox(width: 4),
                              VerificationBadge(
                                isVerified: true,
                                badgeType: myProfile?.badgeType,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          myProfile?.username != null ? '@${myProfile!.username}' : '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Account Group ---
          _buildSectionHeader(context, AppLocalizations.of(context)!.account),
          _buildSettingsGroup(context, [
            _SettingsTileItem(
              icon: Icons.person_outline_rounded,
              title: AppLocalizations.of(context)!.editProfile,
              onTap: () {
                final profileMap = myProfile?.toJson() ?? {
                  'full_name': '',
                  'username': '',
                  'bio': '',
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profileMap)),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.verified_user_outlined,
              title: AppLocalizations.of(context)!.profileVerification,
              trailingText: myProfile?.isVerified == true ? AppLocalizations.of(context)!.verified : (myProfile?.verificationRequested == true ? AppLocalizations.of(context)!.pending : AppLocalizations.of(context)!.apply),
              trailingColor: myProfile?.isVerified == true
                  ? context.greenAccent
                  : (myProfile?.verificationRequested == true ? Colors.orange[700] : null),
              onTap: () {
                final controller = Provider.of<VerificationController>(context, listen: false);
                controller.checkStatus(dbService).then((status) {
                  if (!context.mounted) return;
                  if (myProfile?.isVerified == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VerificationDashboardScreen()),
                    );
                  } else if (myProfile?.verificationRequested == true || status == VerificationStatus.pendingReview || status == VerificationStatus.rejected) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VerificationIntroScreen()),
                    );
                  }
                });
              },
            ),
            if (monetization.isEnabledGlobally || myProfile?.canMonetize == true)
              _SettingsTileItem(
                icon: Icons.monetization_on_outlined,
                title: AppLocalizations.of(context)!.creatorMonetization,
                trailingText: AppLocalizations.of(context)!.dashboard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionDashboardScreen()),
                  );
                },
              ),
            _SettingsTileItem(
              icon: Icons.lock_outline_rounded,
              title: AppLocalizations.of(context)!.privacyMenu,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.notifications_outlined,
              title: AppLocalizations.of(context)!.notifications,
              onTap: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(child: const NotificationSettingsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.security_rounded,
              title: AppLocalizations.of(context)!.security,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.person_off_outlined,
              title: 'Account Status',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountStatusScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // --- Theme / Display Section ---
          _buildSectionHeader(context, AppLocalizations.of(context)!.displayAndTheme),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: Consumer<GeneralSettingsProvider>(
              builder: (context, settingsProvider, _) {
                return Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      secondary: Icon(
                        settingsProvider.isDarkTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: context.textPrimary,
                        size: 22,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.darkTheme,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                          fontSize: 14.5,
                        ),
                      ),
                      activeThumbColor: context.primaryAccent,
                      activeTrackColor: context.primaryAccent.withValues(alpha: 0.38),
                      value: settingsProvider.isDarkTheme,
                      onChanged: (val) {
                        settingsProvider.toggleTheme(val);
                      },
                    ),
                    Divider(height: 1, color: context.border),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      secondary: Icon(
                        Icons.data_usage_rounded,
                        color: context.textPrimary,
                        size: 22,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.lowDataMode,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.lowDataModeSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                      activeThumbColor: context.primaryAccent,
                      activeTrackColor: context.primaryAccent.withValues(alpha: 0.38),
                      value: settingsProvider.lowDataMode,
                      onChanged: (val) {
                        settingsProvider.toggleLowDataMode(val);
                      },
                    ),
                    Divider(height: 1, color: context.border),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Icon(Icons.language_rounded, color: context.textPrimary, size: 22),
                      title: Text(
                        AppLocalizations.of(context)!.language,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.textPrimary, fontSize: 14.5),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _languageNames[settingsProvider.appLocale?.languageCode ?? 'en'] ?? 'English',
                            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textMuted),
                        ],
                      ),
                      onTap: () => _handleLanguageTap(context, settingsProvider),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // --- Content & Activity Group ---
          _buildSectionHeader(context, AppLocalizations.of(context)!.contentAndActivity),
          _buildSettingsGroup(context, [
            _SettingsTileItem(
              icon: Icons.bookmark_border_rounded,
              title: AppLocalizations.of(context)!.savedPosts,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.block_rounded,
              title: AppLocalizations.of(context)!.blockedAccounts,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.volume_off_rounded,
              title: AppLocalizations.of(context)!.mutedAccounts,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MutedAccountsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // --- Support Group ---
          _buildSectionHeader(context, AppLocalizations.of(context)!.supportAndInfo),
          _buildSettingsGroup(context, [
            _SettingsTileItem(
              icon: Icons.help_outline_rounded,
              title: AppLocalizations.of(context)!.helpCenter,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.terminal_rounded,
              title: "System Log",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SystemLogScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.info_outline_rounded,
              title: AppLocalizations.of(context)!.about,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutSettingsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- Logout ---
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.isDarkMode
                      ? const Color(0x33EF4444)
                      : const Color(0xFFFDEDEC),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.logOut,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<_SettingsTileItem> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Icon(tile.icon, color: context.textPrimary, size: 22),
            title: Text(
              tile.title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
                fontSize: 14.5,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tile.trailingText != null)
                  Text(
                    tile.trailingText!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: tile.trailingColor ?? context.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: context.textMuted, size: 18),
              ],
            ),
            onTap: tile.onTap,
          );
        },
      ),
    );
  }

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocus.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.logOutButton,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.areYouSureLogout, // We could add a localized string for this too, but leaving as is since we didn't add it to ARB yet
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthService>(context, listen: false).handleSignout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              AppLocalizations.of(context)!.logOutButton,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, dynamic myProfile, dynamic monetization, dynamic dbService) {
    final query = _searchQuery.toLowerCase().trim();
    
    // Build all searchable items
    List<_SettingsTileItem> allItems = [
      _SettingsTileItem(
        icon: Icons.person_outline_rounded,
        title: AppLocalizations.of(context)!.editProfile,
        onTap: () {
          final profileMap = myProfile?.toJson() ?? {'full_name': '', 'username': '', 'bio': ''};
          Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profileMap)));
        },
      ),
      _SettingsTileItem(
        icon: Icons.verified_user_outlined,
        title: AppLocalizations.of(context)!.profileVerification,
        onTap: () {
          final controller = Provider.of<VerificationController>(context, listen: false);
          controller.checkStatus(dbService).then((status) {
            if (!context.mounted) return;
            if (myProfile?.isVerified == true) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationDashboardScreen()));
            } else if (myProfile?.verificationRequested == true || status == VerificationStatus.pendingReview || status == VerificationStatus.rejected) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationIntroScreen()));
            }
          });
        },
      ),
      if (monetization.isEnabledGlobally || myProfile?.canMonetize == true)
        _SettingsTileItem(
          icon: Icons.monetization_on_outlined,
          title: AppLocalizations.of(context)!.creatorMonetization,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionDashboardScreen()));
          },
        ),
      _SettingsTileItem(
        icon: Icons.lock_outline_rounded,
        title: AppLocalizations.of(context)!.privacyMenu,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.notifications_outlined,
        title: AppLocalizations.of(context)!.notifications,
        onTap: () {
          Navigator.push(context, NoTransitionPageRoute(child: const NotificationSettingsScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.security_rounded,
        title: AppLocalizations.of(context)!.security,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.person_off_outlined,
        title: 'Account Status',
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountStatusScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.bookmark_border_rounded,
        title: AppLocalizations.of(context)!.savedPosts,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPostsScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.block_rounded,
        title: AppLocalizations.of(context)!.blockedAccounts,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.volume_off_rounded,
        title: AppLocalizations.of(context)!.mutedAccounts,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MutedAccountsScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.help_outline_rounded,
        title: AppLocalizations.of(context)!.helpCenter,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.terminal_rounded,
        title: "System Log",
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemLogScreen()));
        },
      ),
      _SettingsTileItem(
        icon: Icons.info_outline_rounded,
        title: AppLocalizations.of(context)!.about,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutSettingsScreen()));
        },
      ),
    ];

    final filtered = allItems.where((item) => item.title.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No settings found',
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
      );
    }

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
      itemBuilder: (context, index) {
        final tile = filtered[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(tile.icon, color: context.textPrimary, size: 22),
          title: Text(
            tile.title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
              fontSize: 14.5,
            ),
          ),
          onTap: tile.onTap,
        );
      },
    );
  }
}

class _SettingsTileItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;
  final Color? trailingColor;

  const _SettingsTileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.trailingColor,
  });
}
