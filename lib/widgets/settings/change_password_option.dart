import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';

class ChangePasswordOption extends StatelessWidget {
  const ChangePasswordOption({super.key});

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.inter(color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: context.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.primaryAccent),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Change Password',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(context, 'Old Password', oldPasswordController),
                    const SizedBox(height: 12),
                    _buildPasswordField(context, 'New Password', newPasswordController),
                    const SizedBox(height: 12),
                    _buildPasswordField(context, 'Confirm New Password', confirmPasswordController),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          final oldPass = oldPasswordController.text.trim();
                          final newPass = newPasswordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                            _showToast(ctx, 'All fields are required.');
                            return;
                          }
                          if (newPass.length < 6) {
                            _showToast(ctx, 'Password must be at least 6 characters.');
                            return;
                          }
                          if (newPass != confirmPass) {
                            _showToast(ctx, 'New passwords do not match.');
                            return;
                          }

                          setModalState(() => isLoading = true);

                          final authService = Provider.of<AuthService>(ctx, listen: false);
                          final email = authService.currentUser?.email;

                          if (email != null && authService.currentUid != 'mock_uid') {
                            // Try to verify old password by logging in
                            final oldPassCorrect = await authService.handleLogin(email, oldPass);
                            if (!ctx.mounted) return;
                            if (oldPassCorrect != LoginResult.success) {
                              setModalState(() => isLoading = false);
                              _showToast(ctx, authService.errorMessage ?? 'Incorrect old password.');
                              return;
                            }

                            // Correct! Now update the password
                            final success = await authService.updatePassword(newPass);
                            if (!ctx.mounted) return;
                            if (success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: const Text('Password updated successfully! Please log in again.'),
                                  backgroundColor: ctx.primaryAccent,
                                ),
                              );
                            } else {
                              setModalState(() => isLoading = false);
                              _showToast(ctx, authService.errorMessage ?? 'Failed to update password.');
                            }
                          } else {
                            // Mock success (e.g. bypassed login or testing)
                            if (!ctx.mounted) return;
                            setModalState(() => isLoading = false);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Password updated (Mock Success).'),
                                backgroundColor: ctx.primaryAccent,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Text(
            'Change Password',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            'Update your login credentials regularly.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: context.textMuted,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
          onTap: () => _showChangePasswordSheet(context),
        ),
        Divider(height: 1, thickness: 0.5, color: context.border),
      ],
    );
  }
}
