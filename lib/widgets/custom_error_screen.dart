import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class CustomErrorScreen extends StatefulWidget {
  final FlutterErrorDetails details;
  const CustomErrorScreen({super.key, required this.details});

  @override
  State<CustomErrorScreen> createState() => _CustomErrorScreenState();
}

class _CustomErrorScreenState extends State<CustomErrorScreen> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = context.greenAccent;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon Container with gradient background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 72,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 24),
                // Heading
                Text(
                  "Oops! Something went wrong",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  "An unexpected error occurred in the application. Don't worry, our team has been notified.",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Primary actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Attempt to recover by popping or navigating to root
                        // Since error widget builds on top of MaterialApp, we can exit or trigger a full rebuild.
                        // For a pure Flutter recovery, we can restart the app runner or return to AuthGate.
                        // Here, we trigger a rebuild by replacing the root view.
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        "Reload App",
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showDetails = !_showDetails;
                        });
                      },
                      icon: Icon(
                        _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _showDetails ? "Hide Details" : "Show Details",
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Technical details panel
                if (_showDetails)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Text(
                          "${widget.details.exception}\n\n${widget.details.stack}",
                          style: GoogleFonts.firaCode(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
