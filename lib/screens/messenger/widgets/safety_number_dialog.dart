import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/e2ee_service.dart';
import '../../../utils/app_theme.dart';

class SafetyNumberDialog extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerPublicKeyBase64;
  final String? myPublicKeyBase64;

  const SafetyNumberDialog({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerPublicKeyBase64,
    required this.myPublicKeyBase64,
  });

  @override
  State<SafetyNumberDialog> createState() => _SafetyNumberDialogState();
}

class _SafetyNumberDialogState extends State<SafetyNumberDialog> {
  bool _isVerified = false;
  String _safetyNumber = '';

  @override
  void initState() {
    super.initState();
    _computeSafetyNumber();
    _loadVerificationStatus();
  }

  void _computeSafetyNumber() {
    final myKey = widget.myPublicKeyBase64 ?? '';
    final peerKey = widget.peerPublicKeyBase64 ?? '';
    if (myKey.isNotEmpty && peerKey.isNotEmpty) {
      _safetyNumber = E2EEService.computeSafetyNumber(myKey, peerKey);
    } else {
      _safetyNumber = '';
    }
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isVerified = prefs.getBool('e2ee_verified_${widget.peerId}') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _toggleVerification(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('e2ee_verified_${widget.peerId}', value);
      setState(() {
        _isVerified = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Marked as verified with ${widget.peerName}'
                  : 'Verification removed',
              style: GoogleFonts.inter(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _copySafetyNumber() {
    if (_safetyNumber.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _safetyNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Safety number copied to clipboard',
          style: GoogleFonts.inter(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = context.textPrimary;
    final groups = _safetyNumber.split(' ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Security Shield Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isVerified
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF21262D) : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                  size: 30,
                  color: _isVerified ? const Color(0xFF10B981) : primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verify Safety Number',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To verify that end-to-end encryption is secure with ${widget.peerName}, compare these 60 digits or scan the QR code.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // QR Code
              if (_safetyNumber.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'dak-e2ee://verify?peer=${widget.peerId}&sn=${Uri.encodeComponent(_safetyNumber)}',
                    version: QrVersions.auto,
                    size: 160,
                  ),
                ),
                const SizedBox(height: 20),

                // 60-digit representation: 4 rows of 3 blocks (or 12 blocks total)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: groups.map((g) {
                      return Text(
                        g,
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: primaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Copy Button
                TextButton.icon(
                  onPressed: _copySafetyNumber,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    'Copy Safety Number',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Encryption keys are being synchronized. Exchange a message to complete initial handshake.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Verify Switch Row
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isVerified,
                onChanged: _safetyNumber.isNotEmpty ? _toggleVerification : null,
                activeTrackColor: const Color(0xFF10B981),
                title: Text(
                  'Mark as Verified',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                subtitle: Text(
                  _isVerified
                      ? 'Cryptographic identity verified'
                      : 'Toggle on once numbers match',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE5E7EB),
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
