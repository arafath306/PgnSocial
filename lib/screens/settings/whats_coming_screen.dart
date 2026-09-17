import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';

enum RoadmapStage {
  completed,
  inProgress,
  comingSoon,
}

class RoadmapItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final RoadmapStage stage;
  final String eta;
  final String category;
  final String? authorName;
  final String? authorAvatar;
  int votes;
  bool isVoted;

  RoadmapItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.stage,
    required this.eta,
    required this.category,
    this.authorName,
    this.authorAvatar,
    this.votes = 0,
    this.isVoted = false,
  });
}

class WhatsComingScreen extends StatefulWidget {
  const WhatsComingScreen({super.key});

  @override
  State<WhatsComingScreen> createState() => _WhatsComingScreenState();
}

class _WhatsComingScreenState extends State<WhatsComingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStageFilter = 'all';

  static const String _currentAppVersion = '6.9.0';

  late List<RoadmapItem> _roadmapItems;
  final List<RoadmapItem> _communityRequests = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRoadmapData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initRoadmapData() {
    _roadmapItems = [
      // 1. In Progress (বর্তমানে কাজ চলছে)
      RoadmapItem(
        id: 'voice_comments',
        title: 'Voice Comments & Audio Notes',
        subtitle: 'কমেন্টে সরাসরি ভয়েস রেকর্ড করে পাঠানোর সুবিধা',
        description:
            'পোস্টের কমেন্টে সরাসরি ভয়েস নোট পাঠানো যাবে। সাথে অডিও ওয়েভফর্ম ও স্পিড কন্ট্রোল থাকবে।',
        icon: Icons.mic_none_outlined,
        stage: RoadmapStage.inProgress,
        eta: 'v6.9.5',
        category: 'Comments',
        votes: 0,
      ),
      RoadmapItem(
        id: 'comment_pdf_send',
        title: 'PDF & Document Sharing in Comments',
        subtitle: 'কমেন্টে পিডিএফ এবং ডক ফাইল শেয়ার করার সুবিধা',
        description:
            'কমেন্টে পড়াশোনার নোট, স্লাইড কিংবা দরকারি ডকুমেন্টস সরাসরি এটাচ করে শেয়ার করা যাবে।',
        icon: Icons.picture_as_pdf_outlined,
        stage: RoadmapStage.inProgress,
        eta: 'v6.9.5',
        category: 'Documents',
        votes: 0,
      ),
      RoadmapItem(
        id: 'audio_spaces',
        title: 'Pigeon Spaces (Live Audio Rooms)',
        subtitle: 'লাইভ গ্রুপ অডিও আড্ডা রুম',
        description:
            'রিয়েল-টাইম অডিও আড্ডা রুম যেখানে যে কেউ স্পিকার হয়ে আলোচনায় অংশ নিতে পারবে।',
        icon: Icons.podcasts_outlined,
        stage: RoadmapStage.inProgress,
        eta: 'v7.0.0',
        category: 'Live Audio',
        votes: 0,
      ),

      // 2. Coming Soon (পরবর্তীতে আসবে)
      RoadmapItem(
        id: 'account_deletion_system',
        title: 'Account Deletion System',
        subtitle: 'অ্যাকাউন্ট পার্মানেন্টলি ডিলিট করার সুবিধা',
        description:
            'ইউজাররা যেকোনো সময় নিজস্ব অ্যাকাউন্ট, প্রোফাইল ও সমস্ত ব্যক্তিগত ডেটা স্থায়ীভাবে মুছে ফেলার পূর্ণ সুবিধা পাবেন। খুব শীঘ্রই উন্মুক্ত করা হচ্ছে।',
        icon: Icons.delete_forever_outlined,
        stage: RoadmapStage.comingSoon,
        eta: 'Coming Soon',
        category: 'Security & Privacy',
        votes: 0,
      ),
      RoadmapItem(
        id: 'encrypted_calls',
        title: 'P2P Encrypted Voice & Video Calls',
        subtitle: 'এইচডি ভয়েস ও ভিডিও কলিং সুবিধা',
        description:
            'লো-লেসেন্সি এন্ড-টু-এন্ড এনক্রিপ্টেড ভয়েস ও ভিডিও কলিং সুবিধা যুক্ত করা হবে।',
        icon: Icons.phone_outlined,
        stage: RoadmapStage.comingSoon,
        eta: 'v7.0.0',
        category: 'Calling',
        votes: 0,
      ),
      RoadmapItem(
        id: 'badge_marketplace',
        title: 'Elite Badge P2P Marketplace',
        subtitle: 'ইউজাররা নিজেরাই ব্যাজ বাই/সেল ও ট্রেড করতে পারবে',
        description:
            'একটি সুরক্ষিত মার্কেটপ্লেস যেখানে ইউজাররা নিজেদের স্পেশাল ব্যাজ নিজেদের মধ্যে লেনদেন করতে পারবে।',
        icon: Icons.storefront_outlined,
        stage: RoadmapStage.comingSoon,
        eta: 'v7.1.0',
        category: 'Marketplace',
        votes: 0,
      ),
      RoadmapItem(
        id: 'black_elite_badge',
        title: 'Onyx Black Elite Badge',
        subtitle: 'অতি-এক্সক্লুসিভ স্ট্যাটাস ব্ল্যাক এলিট ব্যাজ',
        description:
            'পিজিয়নের সর্বোচ্চ প্রেস্টিজ টায়ার। ডার্ক মেটালিক লুক এবং স্পেশাল পোস্ট হাইলাইটিং সুবিধা।',
        icon: Icons.workspace_premium_outlined,
        stage: RoadmapStage.comingSoon,
        eta: 'v7.1.0',
        category: 'Badges',
        votes: 0,
      ),
      RoadmapItem(
        id: 'founding_member_badge',
        title: 'Founding Member Badge System',
        subtitle: 'আর্লি মেম্বারদের জন্য পার্মানেন্ট ব্যাজ',
        description:
            'শুরুর দিকের সাপোর্টারদের জন্য পার্মানেন্ট মেম্বারশিপ ব্যাজ ও স্পেশাল প্রিভিলেজ।',
        icon: Icons.military_tech_outlined,
        stage: RoadmapStage.comingSoon,
        eta: 'v7.1.0',
        category: 'Badges',
        votes: 0,
      ),
      RoadmapItem(
        id: 'ai_thread_summarizer',
        title: 'AI Thread & Post Summaries',
        subtitle: 'বড় থ্রেডের এক-ক্লিক এআই সারসংক্ষেপ',
        description:
            'দীর্ঘ আলোচনা বা বড় পোস্টগুলোর মূল পয়েন্ট কয়েক সেকেন্ডে সংক্ষেপে জেনে নেওয়ার সুবিধা।',
        icon: Icons.auto_awesome_outlined,
        stage: RoadmapStage.comingSoon,
        eta: 'v7.2.0',
        category: 'AI Tools',
        votes: 0,
      ),

      // 3. Completed (ইতিমধ্যে বর্তমান ভার্সনে যুক্ত হয়েছে)
      RoadmapItem(
        id: 'e2ee_messaging',
        title: 'End-to-End Encrypted Messaging',
        subtitle: 'সম্পূর্ণ সুরক্ষিত ও প্রাইভেট মেসেজিং',
        description:
            'সিগন্যাল প্রোটোকল ভিত্তিক চ্যাট যেখানে প্রেরক ও প্রাপক ছাড়া সার্ভারও মেসেজ পড়তে পারে না।',
        icon: Icons.lock_outline,
        stage: RoadmapStage.completed,
        eta: 'v6.7.0',
        category: 'Security',
        votes: 0,
      ),
      RoadmapItem(
        id: 'verified_tiers',
        title: 'Verified Badges & VIP Subscriptions',
        subtitle: 'ব্লু ও গোল্ড ভেরিফিকেশন সিস্টেম',
        description:
            'কনটেন্ট ক্রিয়েটর ও পাবলিক ফিগারদের জন্য অফিশিয়াল ব্লু টিক ও গোল্ড ভেরিফিকেশন।',
        icon: Icons.verified_outlined,
        stage: RoadmapStage.completed,
        eta: 'v6.8.0',
        category: 'Identity',
        votes: 0,
      ),
      RoadmapItem(
        id: 'anti_spam_engine',
        title: 'Smart Anti-Spam Notification Engine',
        subtitle: 'স্মার্ট নোটিফিকেশন ফিল্টারিং ও সাপ্রেশন',
        description:
            'একটানা লাইকের স্প্যাম বন্ধ এবং চ্যাট ওপেন থাকলে অপ্রয়োজনীয় পুশ নোটিফিকেশন ফিল্টার।',
        icon: Icons.shield_outlined,
        stage: RoadmapStage.completed,
        eta: 'v6.9.0',
        category: 'Notifications',
        votes: 0,
      ),
    ];

    _loadDataFromDatabase();
  }

  /// 100% Real Database Votes Fetching (ZERO mock votes)
  Future<void> _loadDataFromDatabase() async {
    try {
      final currentUid = _supabase.auth.currentUser?.id;

      // Real votes calculation from Supabase audit_logs
      final Map<String, int> netVoteCounts = {};
      final Set<String> userVotedItemIds = {};

      try {
        final votesLog = await _supabase
            .from('audit_logs')
            .select('admin_id, action, details, created_at')
            .like('action', 'vote:%')
            .order('created_at', ascending: true);

        for (final row in (votesLog as List)) {
          final action = row['action'] as String? ?? '';
          final itemId = action.replaceFirst('vote:', '');
          final userId = row['admin_id'] as String? ?? '';
          final details = row['details'] as String? ?? '';

          if (itemId.isNotEmpty) {
            final isUpvote = details == 'upvote';
            netVoteCounts[itemId] = (netVoteCounts[itemId] ?? 0) + (isUpvote ? 1 : -1);

            if (currentUid != null && userId == currentUid) {
              if (isUpvote) {
                userVotedItemIds.add(itemId);
              } else {
                userVotedItemIds.remove(itemId);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Votes audit logs fetch note: $e');
      }

      // Apply real votes to Core Roadmap Items (strictly user cast votes, zero base mock)
      for (final item in _roadmapItems) {
        final realVotes = netVoteCounts[item.id] ?? 0;
        item.votes = realVotes.clamp(0, 999999);
        item.isVoted = userVotedItemIds.contains(item.id);
      }

      // Fetch Community Feature Requests directly from Supabase beta_features
      _communityRequests.clear();
      try {
        final featRows = await _supabase
            .from('beta_features')
            .select('*, profiles(username, full_name, avatar_url)')
            .order('created_at', ascending: false);

        for (final row in (featRows as List)) {
          final id = row['id']?.toString() ?? '';
          final title = row['title']?.toString() ?? 'Feature Request';
          final desc = row['description']?.toString() ?? '';
          final category = row['expected_benefit']?.toString() ?? 'Community';
          final status = row['status']?.toString() ?? 'Pending';

          final profile = row['profiles'] as Map<String, dynamic>?;
          final authorName = profile?['full_name'] ?? profile?['username'] ?? 'Community Member';
          final authorAvatar = profile?['avatar_url'] as String?;

          final realVotes = netVoteCounts[id] ?? 0;

          final item = RoadmapItem(
            id: id,
            title: title,
            subtitle: 'Requested by @$authorName',
            description: desc,
            icon: Icons.lightbulb_outline_rounded,
            stage: RoadmapStage.comingSoon,
            eta: status,
            category: category,
            authorName: authorName,
            authorAvatar: authorAvatar,
            votes: realVotes.clamp(0, 999999),
            isVoted: userVotedItemIds.contains(id),
          );

          _communityRequests.add(item);
        }

        _communityRequests.sort((a, b) => b.votes.compareTo(a.votes));
      } catch (e) {
        debugPrint('DB Fetch beta_features failed: $e');
      }
    } catch (e) {
      debugPrint('Error loading data from Supabase: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Live voting connected directly to Supabase
  Future<void> _toggleVote(RoadmapItem item) async {
    final currentUid = _supabase.auth.currentUser?.id;
    final newVoted = !item.isVoted;

    setState(() {
      item.isVoted = newVoted;
      item.votes = (item.votes + (newVoted ? 1 : -1)).clamp(0, 999999);
    });

    try {
      final voteUserId = currentUid ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('audit_logs').insert({
        'admin_id': voteUserId,
        'action': 'vote:${item.id}',
        'details': newVoted ? 'upvote' : 'unvote',
        'ip_address': 'client_app',
      });
    } catch (e) {
      debugPrint('Error writing vote to Supabase: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: context.border),
          ),
          content: Text(
            newVoted ? 'Vote recorded for "${item.title}"' : 'Vote removed',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textPrimary,
            ),
          ),
        ),
      );
    }
  }

  void _openRequestFeatureModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Feature Request';

    final categories = [
      'Feature Request',
      'Badges & Perks',
      'Chat & Voice',
      'Feed & Comments',
      'Marketplace',
      'Privacy & Security',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
                      Text(
                        'নতুন ফিচারের প্রস্তাব দিন',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'আপনার প্রস্তাবিত ফিচার কমিউনিটির ভোটের ভিত্তিতে তৈরি করা হবে।',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'শিরোনাম',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'যেমন: স্টোরিতে লাইভ পোল',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
                          filled: true,
                          fillColor: context.scaffoldBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'ক্যাটাগরি',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: context.cardBg,
                            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'বিবরণ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ফিচারটি কীভাবে কাজ করবে তা সংক্ষেপে লিখুন...',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: context.textMuted),
                          filled: true,
                          fillColor: context.scaffoldBg,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final title = titleController.text.trim();
                                  final desc = descController.text.trim();
                                  if (title.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('শিরোনাম পূরণ করুন')),
                                    );
                                    return;
                                  }

                                  final currentUid = _supabase.auth.currentUser?.id;
                                  if (currentUid == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('লগইন করা আবশ্যক')),
                                    );
                                    return;
                                  }

                                  setModalState(() => _isSubmitting = true);

                                  try {
                                    final insertRes = await _supabase.from('beta_features').insert({
                                      'user_id': currentUid,
                                      'title': title,
                                      'description': desc.isNotEmpty ? desc : 'Requested by community member.',
                                      'expected_benefit': selectedCategory,
                                      'status': 'Received',
                                    }).select().single();

                                    final newFeatureId = insertRes['id']?.toString();

                                    if (newFeatureId != null && newFeatureId.isNotEmpty) {
                                      try {
                                        await _supabase.from('audit_logs').insert({
                                          'admin_id': currentUid,
                                          'action': 'vote:$newFeatureId',
                                          'details': 'upvote',
                                          'ip_address': 'client_app',
                                        });
                                      } catch (voteErr) {
                                        debugPrint('Vote audit log note: $voteErr');
                                      }
                                    }

                                    await _loadDataFromDatabase();

                                    if (modalCtx.mounted) {
                                      Navigator.pop(modalCtx);
                                    }
                                    if (mounted) {
                                      _tabController.animateTo(1);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('আপনার প্রস্তাবিত ফিচারটি যুক্ত হয়েছে!'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Error saving feature request: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('ত্রুটি হয়েছে: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setModalState(() => _isSubmitting = false);
                                    }
                                  }
                                },
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'প্রস্তাব পাঠান',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                        ),
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's Coming",
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16.5,
              ),
            ),
            Text(
              "Current Version: v$_currentAppVersion",
              style: GoogleFonts.inter(
                color: context.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.border, width: 1.0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.primaryAccent,
              indicatorWeight: 2,
              labelColor: context.primaryAccent,
              unselectedLabelColor: context.textSecondary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                const Tab(text: 'Roadmap'),
                Tab(text: 'Community (${_communityRequests.length})'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoadmapTab(),
                _buildCommunityTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 1,
        icon: const Icon(Icons.add, size: 18),
        label: Text(
          'Request Feature',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        onPressed: _openRequestFeatureModal,
      ),
    );
  }

  // ── Tab 1: Roadmap Pipeline ───────────────────────────────────────────────
  Widget _buildRoadmapTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        _buildFilterChips(),
        const SizedBox(height: 14),

        if (_selectedStageFilter == 'all' || _selectedStageFilter == 'in_progress') ...[
          _buildStageHeader(
            title: 'In Progress (কাজ চলছে)',
            count: _roadmapItems.where((e) => e.stage == RoadmapStage.inProgress).length,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          ..._roadmapItems
              .where((e) => e.stage == RoadmapStage.inProgress)
              .map((item) => _buildRoadmapCard(item)),
          const SizedBox(height: 16),
        ],

        if (_selectedStageFilter == 'all' || _selectedStageFilter == 'coming_soon') ...[
          _buildStageHeader(
            title: 'Coming Soon (পরবর্তীতে আসবে)',
            count: _roadmapItems.where((e) => e.stage == RoadmapStage.comingSoon).length,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          ..._roadmapItems
              .where((e) => e.stage == RoadmapStage.comingSoon)
              .map((item) => _buildRoadmapCard(item)),
          const SizedBox(height: 16),
        ],

        if (_selectedStageFilter == 'all' || _selectedStageFilter == 'completed') ...[
          _buildStageHeader(
            title: 'Shipped (যুক্ত হয়েছে)',
            count: _roadmapItems.where((e) => e.stage == RoadmapStage.completed).length,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 8),
          ..._roadmapItems
              .where((e) => e.stage == RoadmapStage.completed)
              .map((item) => _buildRoadmapCard(item)),
        ],
      ],
    );
  }

  // ── Tab 2: Community Feature Requests ─────────────────────────────────────
  Widget _buildCommunityTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'কমিউনিটি প্রস্তাবনা (${_communityRequests.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ভোট অনুযায়ী সাজানো',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: context.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_communityRequests.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_outlined, size: 30, color: context.textMuted),
                const SizedBox(height: 8),
                Text(
                  'এখনো কোনো প্রস্তাব নেই',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'পিজিয়নে কোন ফিচার দেখতে চান? প্রথম প্রস্তাবটি আপনি দিন!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryAccent,
                    side: BorderSide(color: context.primaryAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'প্রস্তাব দিন',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: _openRequestFeatureModal,
                ),
              ],
            ),
          )
        else
          ..._communityRequests.map((item) => _buildRoadmapCard(item)),
      ],
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'in_progress', 'label': 'In Progress'},
      {'id': 'coming_soon', 'label': 'Coming Soon'},
      {'id': 'completed', 'label': 'Shipped'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStageFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: context.cardBg,
              selectedColor: context.cardBg,
              side: BorderSide(
                color: isSelected ? context.primaryAccent : context.border,
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              label: Text(
                f['label']!,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? context.primaryAccent : context.textPrimary,
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedStageFilter = f['id']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildStageHeader({
    required String title,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Clean Card (Zero Gradients, Real Monochrome Icons, Zero Overflows) ─────
  Widget _buildRoadmapCard(RoadmapItem item) {
    Color stageColor;
    String stageText;
    switch (item.stage) {
      case RoadmapStage.completed:
        stageColor = const Color(0xFF10B981);
        stageText = 'Shipped';
        break;
      case RoadmapStage.inProgress:
        stageColor = const Color(0xFFF59E0B);
        stageText = 'In Progress';
        break;
      case RoadmapStage.comingSoon:
        stageColor = const Color(0xFF3B82F6);
        stageText = 'Planned';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isVoted ? context.primaryAccent.withValues(alpha: 0.5) : context.border,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + ETA + Stage Badge (Safe from overflow)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stageText,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: stageColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textMuted,
                    ),
                  ),
                ),
                if (item.eta.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.eta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Title Row with clean Real Icon (No colored box)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(item.icon, color: context.textPrimary, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Action Row (Zero overflow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 13, color: context.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${item.votes} ${item.votes == 1 ? "vote" : "votes"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _toggleVote(item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: item.isVoted ? context.primaryAccent : context.border,
                      width: 1.0,
                    ),
                    backgroundColor: item.isVoted ? context.primaryAccent.withValues(alpha: 0.1) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: Icon(
                    item.isVoted ? Icons.check : Icons.arrow_upward_rounded,
                    size: 13,
                    color: item.isVoted ? context.primaryAccent : context.textPrimary,
                  ),
                  label: Text(
                    item.isVoted ? 'Voted' : 'Vote',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: item.isVoted ? context.primaryAccent : context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
