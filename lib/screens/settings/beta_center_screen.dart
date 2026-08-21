import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class BetaCenterScreen extends StatefulWidget {
  const BetaCenterScreen({super.key});

  @override
  State<BetaCenterScreen> createState() => _BetaCenterScreenState();
}

class _BetaCenterScreenState extends State<BetaCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {'text': 'Bug', 'icon': Icons.bug_report_rounded},
    {'text': 'Feature', 'icon': Icons.lightbulb_outline_rounded},
    {'text': 'Feedback', 'icon': Icons.star_outline_rounded},
    {'text': 'Issues', 'icon': Icons.build_circle_outlined},
    {'text': 'Changelog', 'icon': Icons.article_outlined},
    {'text': 'Reports', 'icon': Icons.list_alt_rounded},
  ];

  // Bug Report Form controllers
  final _bugTitleCtrl = TextEditingController();
  final _bugDescCtrl = TextEditingController();
  String _selectedSeverity = 'Medium';
  String _selectedScreen = 'Home Feed';
  final _bugScreenshotCtrl = TextEditingController();
  bool _bugSubmitting = false;

  // Feature Request Form controllers
  final _featTitleCtrl = TextEditingController();
  final _featDescCtrl = TextEditingController();
  final _featBenefitCtrl = TextEditingController();
  bool _featSubmitting = false;

  // Beta Feedback Form controllers
  int _feedbackRating = 5;
  final _feedLikedCtrl = TextEditingController();
  final _feedImprovedCtrl = TextEditingController();
  bool _feedSubmitting = false;

  // Known Issues / Changelog / Reports Lists
  List<Map<String, dynamic>> _knownIssues = [];
  List<Map<String, dynamic>> _changelogs = [];
  List<Map<String, dynamic>> _myReports = [];
  bool _loadingLists = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadAllLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bugTitleCtrl.dispose();
    _bugDescCtrl.dispose();
    _bugScreenshotCtrl.dispose();
    _featTitleCtrl.dispose();
    _featDescCtrl.dispose();
    _featBenefitCtrl.dispose();
    _feedLikedCtrl.dispose();
    _feedImprovedCtrl.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index >= 3) {
        _loadAllLists();
      }
    }
  }

  Future<void> _loadAllLists() async {
    if (mounted) setState(() => _loadingLists = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final issues = await db.fetchBetaKnownIssues();
    final changelogs = await db.fetchBetaChangelogs();
    final reports = await db.fetchMyBetaReports();

    if (mounted) {
      setState(() {
        _knownIssues = issues;
        _changelogs = changelogs;
        _myReports = reports;
        _loadingLists = false;
      });
    }
  }

  // --- Actions ---

  Future<void> _submitBug() async {
    final title = _bugTitleCtrl.text.trim();
    final desc = _bugDescCtrl.text.trim();
    final screen = _selectedScreen;
    final screenshot = _bugScreenshotCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _showSnackbar('Title and Description are required', isError: true);
      return;
    }

    setState(() => _bugSubmitting = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final ok = await db.submitBetaBug(
      title: title,
      desc: desc,
      severity: _selectedSeverity,
      screen: screen,
      screenshotUrl: screenshot.isNotEmpty ? screenshot : null,
    );

    if (mounted) {
      setState(() => _bugSubmitting = false);
      if (ok) {
        _showSnackbar('Bug report submitted successfully! Thank you.');
        _bugTitleCtrl.clear();
        _bugDescCtrl.clear();
        _bugScreenshotCtrl.clear();
        _loadAllLists();
      } else {
        _showSnackbar('Failed to submit bug report. Try again.', isError: true);
      }
    }
  }

  Future<void> _submitFeature() async {
    final title = _featTitleCtrl.text.trim();
    final desc = _featDescCtrl.text.trim();
    final benefit = _featBenefitCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty || benefit.isEmpty) {
      _showSnackbar('All fields are required', isError: true);
      return;
    }

    setState(() => _featSubmitting = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final ok = await db.submitBetaFeature(
      title: title,
      desc: desc,
      expectedBenefit: benefit,
    );

    if (mounted) {
      setState(() => _featSubmitting = false);
      if (ok) {
        _showSnackbar('Feature request submitted successfully!');
        _featTitleCtrl.clear();
        _featDescCtrl.clear();
        _featBenefitCtrl.clear();
        _loadAllLists();
      } else {
        _showSnackbar('Failed to submit feature request. Try again.', isError: true);
      }
    }
  }

  Future<void> _submitFeedback() async {
    final liked = _feedLikedCtrl.text.trim();
    final improved = _feedImprovedCtrl.text.trim();

    if (liked.isEmpty || improved.isEmpty) {
      _showSnackbar('Both fields are required', isError: true);
      return;
    }

    setState(() => _feedSubmitting = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final ok = await db.submitBetaFeedback(
      rating: _feedbackRating,
      liked: liked,
      improved: improved,
    );

    if (mounted) {
      setState(() => _feedSubmitting = false);
      if (ok) {
        _showSnackbar('Feedback submitted! Thank you for helping us grow.');
        _feedLikedCtrl.clear();
        _feedImprovedCtrl.clear();
        setState(() => _feedbackRating = 5);
        _loadAllLists();
      } else {
        _showSnackbar('Failed to submit feedback. Try again.', isError: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF1E824C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // --- Rendering Helpers ---

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
  }) {
    final bg = context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF9FAFB);
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14.5, color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.border.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E824C), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // --- Star Selector ---
  Widget _buildStarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _feedbackRating;
        return GestureDetector(
          onTap: () => setState(() => _feedbackRating = starIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_border_rounded,
              color: isSelected ? Colors.amber[500] : context.textMuted,
              size: isSelected ? 44 : 38,
            ),
          ),
        );
      }),
    );
  }

  // --- Tab View Builders ---

  Widget _buildBugTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const ClampingScrollPhysics(),
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: context.border.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.bug_report_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Report a Bug",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Found something broken? Send us the details so we can squash it immediately.",
                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                _sectionTitle("Bug Title"),
                _inputField(_bugTitleCtrl, hint: "e.g., App crashes when uploading a profile cover photo"),
                const SizedBox(height: 16),
                _sectionTitle("Bug Description"),
                _inputField(_bugDescCtrl, hint: "Describe what happened, steps to reproduce, and actual behaviour...", maxLines: 4),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Severity"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.border.withValues(alpha: 0.5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSeverity,
                                dropdownColor: context.cardBg,
                                items: ['Low', 'Medium', 'High', 'Critical'].map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: GoogleFonts.inter(
                                        color: s == 'Critical' ? Colors.red : context.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedSeverity = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Screen/Page"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.border.withValues(alpha: 0.5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedScreen,
                                dropdownColor: context.cardBg,
                                isExpanded: true,
                                items: ['Home Feed', 'Explore', 'Messages', 'Profile', 'Settings', 'Other'].map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: GoogleFonts.inter(
                                        color: context.textPrimary,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedScreen = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle("Screenshot Link (Optional)"),
                _inputField(_bugScreenshotCtrl, hint: "Paste image url or storage upload link"),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _bugSubmitting ? null : _submitBug,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 2,
                      shadowColor: const Color(0xFF1E824C).withValues(alpha: 0.4),
                    ),
                    child: _bugSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text("Submit Bug Report", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const ClampingScrollPhysics(),
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: context.border.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.lightbulb_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Feature Request",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Have ideas to make Pigeon better? Suggest new features and changes you want to see.",
                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                _sectionTitle("Feature Title"),
                _inputField(_featTitleCtrl, hint: "e.g., Direct Voice Messaging in chats"),
                const SizedBox(height: 16),
                _sectionTitle("Feature Description"),
                _inputField(_featDescCtrl, hint: "Explain the feature in detail and how it should work...", maxLines: 4),
                const SizedBox(height: 16),
                _sectionTitle("Expected Benefit"),
                _inputField(_featBenefitCtrl, hint: "Why is this feature important and who will benefit from it?", maxLines: 3),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _featSubmitting ? null : _submitFeature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 2,
                      shadowColor: const Color(0xFF1E824C).withValues(alpha: 0.4),
                    ),
                    child: _featSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text("Submit Feature Request", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const ClampingScrollPhysics(),
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: context.border.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Beta Tester Feedback",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Your general feedback helps us align our designs before launching to production.",
                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 32),
                Center(child: Text("Rate your overall experience", style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: context.textPrimary))),
                const SizedBox(height: 16),
                _buildStarSelector(),
                const SizedBox(height: 32),
                _sectionTitle("What did you like about the current beta build?"),
                _inputField(_feedLikedCtrl, hint: "Share what worked beautifully and what you enjoyed...", maxLines: 3),
                const SizedBox(height: 16),
                _sectionTitle("What should be improved / changed?"),
                _inputField(_feedImprovedCtrl, hint: "Point out elements that feel slow, look weird, or are difficult to use...", maxLines: 3),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _feedSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 2,
                      shadowColor: const Color(0xFF1E824C).withValues(alpha: 0.4),
                    ),
                    child: _feedSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text("Submit Review", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKnownIssuesTab() {
    if (_loadingLists) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)));
    }
    if (_knownIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text("No known issues found", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 6),
            Text("All systems are operational!", style: GoogleFonts.inter(fontSize: 13.5, color: context.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: _knownIssues.length,
      itemBuilder: (context, i) {
        final issue = _knownIssues[i];
        final String status = issue['status'] ?? 'Investigating';
        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case 'Resolved':
            statusColor = Colors.green[600]!;
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'Fixing':
            statusColor = Colors.orange[700]!;
            statusIcon = Icons.build_rounded;
            break;
          default:
            statusColor = Colors.blue[600]!;
            statusIcon = Icons.search_rounded;
        }

        DateTime? parsedTime;
        if (issue['updated_at'] != null) {
          parsedTime = DateTime.tryParse(issue['updated_at']);
        }
        final String dateStr = parsedTime != null
            ? "${parsedTime.day}/${parsedTime.month}/${parsedTime.year} ${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}"
            : "Recently";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: context.border.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        issue['title'] ?? 'Title',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  issue['description'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.5),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(Icons.update_rounded, size: 14, color: context.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      "Updated: $dateStr",
                      style: GoogleFonts.inter(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangelogTab() {
    if (_loadingLists) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)));
    }
    if (_changelogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 56, color: context.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text("No changelogs uploaded yet", style: GoogleFonts.inter(color: context.textMuted, fontSize: 14.5)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: _changelogs.length,
      itemBuilder: (context, i) {
        final change = _changelogs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: context.border.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF1E824C).withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF1E824C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Build: ${change['version']}",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (change['new_features'] != null && change['new_features'].toString().isNotEmpty) ...[
                  _bulletSection("New Features", Icons.auto_awesome_rounded, Colors.purple, change['new_features'].toString()),
                  const SizedBox(height: 16),
                ],
                if (change['improvements'] != null && change['improvements'].toString().isNotEmpty) ...[
                  _bulletSection("Improvements", Icons.trending_up_rounded, Colors.blue, change['improvements'].toString()),
                  const SizedBox(height: 16),
                ],
                if (change['bug_fixes'] != null && change['bug_fixes'].toString().isNotEmpty) ...[
                  _bulletSection("Bug Fixes", Icons.healing_rounded, Colors.green, change['bug_fixes'].toString()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bulletSection(String title, IconData icon, Color iconColor, String items) {
    final parsedItems = items.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...parsedItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: context.textMuted, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      item.replaceFirst(RegExp(r'^[-*•\s]+'), ''),
                      style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildReportsTab() {
    if (_loadingLists) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)));
    }
    if (_myReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.folder_open_rounded, size: 48, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            Text("No reports submitted yet", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: _myReports.length,
      itemBuilder: (context, i) {
        final rep = _myReports[i];
        final type = rep['type'] ?? 'Bug';
        final status = rep['status'] ?? 'Received';

        // Choose status badge color
        Color badgeColor;
        switch (status) {
          case 'Closed':
            badgeColor = Colors.grey[600]!;
            break;
          case 'Fixed':
            badgeColor = Colors.green[600]!;
            break;
          case 'In Progress':
            badgeColor = Colors.orange[700]!;
            break;
          case 'Under Review':
            badgeColor = Colors.purple[600]!;
            break;
          default:
            badgeColor = Colors.blue[600]!;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: context.border.withValues(alpha: 0.2)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: type == 'Bug' ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type == 'Bug' ? Icons.bug_report_rounded : Icons.lightbulb_rounded, 
                             size: 14, color: type == 'Bug' ? Colors.red[700] : Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: type == 'Bug' ? Colors.red[700] : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rep['title'] ?? 'Request',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Text(
                      "Status: ",
                      style: GoogleFonts.inter(fontSize: 12.5, color: context.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 24),
                      Text(
                        "Description",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rep['description'] ?? '',
                        style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      if (type == 'Bug' && rep['severity'] != null) ...[
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: context.textMuted),
                            const SizedBox(width: 8),
                            Text("Severity: ", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                            Text(rep['severity'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: rep['severity'] == 'Critical' ? Colors.red : context.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone_iphone_rounded, size: 16, color: context.textMuted),
                            const SizedBox(width: 8),
                            Text("Screen: ", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                            Text(rep['screen_name'] ?? 'General', style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary)),
                          ],
                        ),
                      ] else if (type == 'Feature' && rep['expected_benefit'] != null) ...[
                        Text(
                          "Expected Benefit",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rep['expected_benefit'],
                          style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary, height: 1.5),
                        ),
                      ],
                      if (rep['screenshot_url'] != null && rep['screenshot_url'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.image_outlined, size: 16, color: context.textMuted),
                            const SizedBox(width: 8),
                            Text("Screenshot: ", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                            Expanded(
                              child: Text(
                                rep['screenshot_url'], 
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E824C), decoration: TextDecoration.underline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildReportProgressTimeline(status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportProgressTimeline(String status) {
    final stages = ['Received', 'Review', 'In Progress', 'Fixed', 'Closed'];
    int activeIndex = ['Received', 'Under Review', 'In Progress', 'Fixed', 'Closed'].indexOf(status);
    if (activeIndex == -1) activeIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progress Timeline",
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (idx) {
            final isDone = idx <= activeIndex;
            final isCurrent = idx == activeIndex;
            final isLast = idx == stages.length - 1;

            Color dotColor = context.border;
            if (isDone) {
              dotColor = const Color(0xFF1E824C);
            }
            if (isCurrent) {
              dotColor = Colors.orange[700]!;
            }

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isCurrent ? context.cardBg : dotColor,
                      shape: BoxShape.circle,
                      border: isCurrent ? Border.all(color: dotColor, width: 4) : null,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: dotColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: idx < activeIndex ? const Color(0xFF1E824C) : context.border.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.map((s) {
            final idx = stages.indexOf(s);
            final isCurrent = idx == activeIndex;
            return Expanded(
              child: Text(
                s,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? context.textPrimary : context.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Beta Center',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF1E824C),
                unselectedLabelColor: context.textSecondary,
                indicatorColor: const Color(0xFF1E824C),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerColor: Colors.transparent,
                tabs: _tabs.map((t) => Tab(
                  height: 56,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData, size: 18),
                      const SizedBox(width: 8),
                      Text(t['text'] as String),
                    ],
                  ),
                )).toList(),
              ),
              Container(height: 1, color: context.border.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const ClampingScrollPhysics(),
        children: [
          _buildBugTab(),
          _buildFeatureTab(),
          _buildFeedbackTab(),
          _buildKnownIssuesTab(),
          _buildChangelogTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }
}
