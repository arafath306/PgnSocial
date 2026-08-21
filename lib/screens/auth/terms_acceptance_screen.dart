import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/app_legal_terms.dart';
import '../../utils/app_theme.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  final VoidCallback? onAccepted;

  const TermsAcceptanceScreen({super.key, this.onAccepted});

  static Future<bool> hasUserAcceptedTerms(String uid) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('terms_accepted_$uid') ?? false;
  }

  static Future<void> saveUserTermsAcceptance(String uid) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted_$uid', true);
  }

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  int _selectedTab = 0; // 0 for Terms of Service, 1 for Privacy Policy
  bool _hasAgreed = false;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();

  void _handleAccept() async {
    if (!_hasAgreed || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUid;

    await TermsAcceptanceScreen.saveUserTermsAcceptance(uid);
    await authService.markTermsAccepted();

    if (!mounted) return;

    if (widget.onAccepted != null) {
      widget.onAccepted!();
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E824C).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFF1E824C),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms & Policies',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Please review and accept to enter Pigeon',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Selector
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF121422)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 0;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? context.cardBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedTab == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Terms of Service',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedTab == 0
                                      ? context.primaryAccent
                                      : context.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? context.cardBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedTab == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Privacy Policy',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedTab == 1
                                      ? context.primaryAccent
                                      : context.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Legal Content Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    _selectedTab == 0
                        ? AppLegalTerms.termsOfService
                        : AppLegalTerms.privacyPolicy,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.55,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(top: BorderSide(color: context.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox Agreement
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasAgreed = !_hasAgreed;
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _hasAgreed,
                            activeColor: const Color(0xFF1E824C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _hasAgreed = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'I have read and agree to Pigeon\'s Terms of Service and Privacy Policy.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Accept & Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hasAgreed && !_isSaving ? _handleAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E824C),
                        disabledBackgroundColor: context.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Accept & Continue',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _hasAgreed
                                    ? Colors.white
                                    : (context.isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600]),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
