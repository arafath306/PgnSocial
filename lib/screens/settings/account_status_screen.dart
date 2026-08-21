import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/auth_screen.dart';

class AccountStatusScreen extends StatefulWidget {
  const AccountStatusScreen({super.key});

  @override
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen> {
  bool _isDeactivating = false;
  Duration _selectedDuration = const Duration(days: 7);
  final List<Duration> _durationOptions = [
    const Duration(days: 1),
    const Duration(days: 7),
    const Duration(days: 30),
    const Duration(days: 365),
  ];

  String _formatDuration(Duration d) {
    if (d.inDays == 1) return '1 Day';
    if (d.inDays == 7) return '7 Days';
    if (d.inDays == 30) return '30 Days';
    return '1 Year';
  }

  void _handleDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Deactivate Account', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Your account will be deactivated and hidden for ${_formatDuration(_selectedDuration)}. If you log back in during this time, your account will be reactivated automatically. Proceed?',
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Deactivate', style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeactivating = true);
      final db = Provider.of<DatabaseService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      
      final success = await db.deactivateAccount(_selectedDuration);
      if (success && mounted) {
        await auth.handleSignout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthScreen(onLoginSuccess: () {})),
            (route) => false,
          );
        }
      } else if (mounted) {
        setState(() => _isDeactivating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to deactivate account. Try again.')),
        );
      }
    }
  }

  void _handleDelete() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Permanently Delete Account', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is irreversible. All your data will be wiped out. To confirm, type "DELETE" and enter your password below.',
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'Type DELETE',
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                filled: true,
                fillColor: context.scaffoldBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: GoogleFonts.inter(color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter Password',
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                filled: true,
                fillColor: context.scaffoldBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: GoogleFonts.inter(color: context.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (confirmController.text.trim() == 'DELETE' && passwordController.text.isNotEmpty) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please type DELETE and enter your password.')));
              }
            },
            child: Text('Delete Permanently', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeactivating = true);
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await auth.deleteAccountPermanently(passwordController.text.trim());
      
      if (mounted) {
        setState(() => _isDeactivating = false);
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthScreen(onLoginSuccess: () {})),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.errorMessage ?? 'Failed to delete account. Incorrect password?')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account Status',
          style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Deactivation Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deactivate Account', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'Temporarily hide your profile, posts, and messages. You can reactivate simply by logging back in before the duration expires.',
                    style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Duration: ', style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<Duration>(
                          initialValue: _selectedDuration,
                          dropdownColor: context.cardBg,
                          style: GoogleFonts.inter(color: context.textPrimary),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: context.scaffoldBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: _durationOptions.map((d) {
                            return DropdownMenuItem(value: d, child: Text(_formatDuration(d)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDuration = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        foregroundColor: Colors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isDeactivating ? null : _handleDeactivate,
                      child: _isDeactivating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                          : Text('Deactivate', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Permanent Deletion Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Permanent Deletion', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once deleted, your account and data cannot be recovered. You will have to create a new account if you want to join again.',
                    style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isDeactivating ? null : _handleDelete,
                      child: Text('Delete Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
