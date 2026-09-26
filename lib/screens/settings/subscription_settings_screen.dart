// NOTE: [UNUSED / REFERENCE ONLY]
// This dummy placeholder screen is currently not active in the app.
// The active Creator Studio & Monetization dashboard is [SubscriptionDashboardScreen] in 'screens/profile/subscription_dashboard_screen.dart'.
// Kept for future reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class SubscriptionSettingsScreen extends StatelessWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscription',
          style: GoogleFonts.hindSiliguri(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Subscription Plans\n(Coming Soon)',
          style: GoogleFonts.hindSiliguri(fontSize: 16, color: context.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
