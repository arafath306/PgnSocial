import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Account', 'icon': Icons.person_rounded},
    {'name': 'Privacy', 'icon': Icons.lock_rounded},
    {'name': 'Security', 'icon': Icons.security_rounded},
    {'name': 'Messaging', 'icon': Icons.chat_bubble_rounded},
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Account',
      'question': 'What is Pigeon?',
      'answer': 'Pigeon is a next-generation decentralized social network built to prioritize user privacy, modern real-time interactions, and premium aesthetics. It is designed to offer a smoother, more secure experience than platforms like Twitter and Bluesky.'
    },
    {
      'category': 'Messaging',
      'question': 'How do I control who can send me Direct Messages?',
      'answer': 'Navigate to your Chats list page and tap the Gear icon in the top-right corner. There you can set your direct message permissions to "Everyone", "Users I follow", or "No one".'
    },
    {
      'category': 'Messaging',
      'question': 'What are Follow Requests?',
      'answer': 'When someone whose DM setting is restricted attempts to chat with you, you will see a "Follow Request" button. Once sent, the recipient receives a notification to approve or deny the request before you can chat.'
    },
    {
      'category': 'Security',
      'question': 'How do I activate Two-Factor Authentication (2FA)?',
      'answer': 'Go to Settings -> Security and toggle on the "Two-Factor Authentication" option. This adds an extra layer of security to prevent unauthorized access. Note: This option is coming soon.'
    },
    {
      'category': 'Security',
      'question': 'Can I audit my active login sessions?',
      'answer': 'Yes. Under Settings -> Security, you will see a list of "Active Sessions" showing devices and locations where you are logged in. You can instantly log out or revoke access to any other device by tapping the "Revoke" button.'
    },
    {
      'category': 'Privacy',
      'question': 'How do I report spam or abusive accounts?',
      'answer': 'You can block or mute any account by visiting Settings -> Blocked Accounts or Settings -> Muted Accounts and entering their display name or username.'
    },
    {
      'category': 'Account',
      'question': 'How do I request a Profile Verification?',
      'answer': 'Go to Settings -> Profile Verification to request your verification status badge. Once your application is reviewed by our administration team, you will receive a verification mark.'
    },
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Account':
        return Icons.person_outline_rounded;
      case 'Privacy':
        return Icons.lock_outline_rounded;
      case 'Security':
        return Icons.verified_user_outlined;
      case 'Messaging':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final cat = faq['category']!;

      final matchesQuery = q.contains(query) || a.contains(query);
      final matchesCategory = _selectedCategory == 'All' || cat == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

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
          'Help Center',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Header search banner
          Container(
            color: context.cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                    hintText: 'Search articles, questions...',
                    hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: context.isDarkMode ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: context.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                ),
              ],
            ),
          ),

          // Categories horizontal list
          Container(
            color: context.cardBg,
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['name'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? context.primaryAccent
                          : (context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? context.primaryAccent : context.border,
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: context.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData, 
                          size: 14, 
                          color: isSelected ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: context.border),

          // FAQ List
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_center_outlined, size: 60, color: context.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No articles match your search',
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try different keywords or select another category.',
                            style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: context.primaryAccent,
                            collapsedIconColor: context.textMuted,
                            leading: Icon(
                              _getCategoryIcon(faq['category']!),
                              color: context.primaryAccent.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            title: Text(
                              faq['question']!,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: context.textPrimary,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            expandedAlignment: Alignment.topLeft,
                            children: [
                              Text(
                                faq['answer']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: context.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Contact support footer
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(top: BorderSide(color: context.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Still need help?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Submit a live ticket to Pigeon administrators.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showContactForm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    'Contact Us',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactForm(BuildContext context) {
    final emailCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final supabaseClient = Supabase.instance.client;

    // Prefill user email if logged in
    final currentUserEmail = supabaseClient.auth.currentUser?.email;
    if (currentUserEmail != null) {
      emailCtrl.text = currentUserEmail;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Contact Administration',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Describe your issue and an admin will review it.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Field
                  Text(
                    'Your Email Address',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.isDarkMode ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Enter your email...',
                      hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13.5),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Message Field
                  Text(
                    'Describe your issue',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.isDarkMode ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      hintText: 'What do you need help with?',
                      hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13.5),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        final email = emailCtrl.text.trim();
                        final message = messageCtrl.text.trim();

                        if (email.isEmpty || message.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('All fields are required.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);

                        try {
                          await supabaseClient.from('support_tickets').insert({
                            'user_id': supabaseClient.auth.currentUser?.id,
                            'email': email,
                            'message': message,
                            'status': 'pending',
                          });

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text('Your query has been submitted directly to the Admin Dashboard!'),
                              backgroundColor: ctx.primaryAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit ticket: ${e.toString()}'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Query',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
