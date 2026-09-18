import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_experience.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class ExperienceEditorSheet extends StatefulWidget {
  final UserExperience? experience; // null if adding new
  final VoidCallback? onSaved;

  const ExperienceEditorSheet({
    super.key,
    this.experience,
    this.onSaved,
  });

  static Future<void> show(BuildContext context, {UserExperience? experience, VoidCallback? onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExperienceEditorSheet(experience: experience, onSaved: onSaved),
    );
  }

  @override
  State<ExperienceEditorSheet> createState() => _ExperienceEditorSheetState();
}

class _ExperienceEditorSheetState extends State<ExperienceEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _milestoneNoteCtrl;

  String _employmentType = 'Full-time';
  String _locationType = 'On-site';
  bool _isCurrent = true;
  String _startDate = '';
  String _endDate = '';
  bool _shareAsMilestone = false;
  bool _isSaving = false;

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Self-employed',
    'Freelance',
    'Contract',
    'Internship',
  ];

  final List<String> _locationTypes = ['On-site', 'Hybrid', 'Remote'];

  @override
  void initState() {
    super.initState();
    final exp = widget.experience;
    _titleCtrl = TextEditingController(text: exp?.title ?? '');
    _companyCtrl = TextEditingController(text: exp?.company ?? '');
    _locationCtrl = TextEditingController(text: exp?.location ?? '');
    _descriptionCtrl = TextEditingController(text: exp?.description ?? '');
    _milestoneNoteCtrl = TextEditingController();

    if (exp != null) {
      _employmentType = exp.employmentType;
      _locationType = exp.locationType;
      _isCurrent = exp.isCurrent;
      _startDate = exp.startDate;
      _endDate = exp.endDate ?? '';
    } else {
      final now = DateTime.now();
      _startDate = '${_monthName(now.month)} ${now.year}';
      _shareAsMilestone = true; // Default ON for brand new role
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _milestoneNoteCtrl.dispose();
    super.dispose();
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (DateTime.tryParse(_endDate) ?? now),
      firstDate: DateTime(1970),
      lastDate: DateTime(2035),
      helpText: isStart ? 'SELECT START DATE' : 'SELECT END DATE',
    );

    if (picked != null) {
      final str = '${_monthName(picked.month)} ${picked.year}';
      setState(() {
        if (isStart) {
          _startDate = str;
        } else {
          _endDate = str;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = Provider.of<DatabaseService>(context, listen: false);

    final updatedExp = UserExperience(
      id: widget.experience?.id ?? '',
      userId: db.currentUid,
      title: _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      employmentType: _employmentType,
      location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
      locationType: _locationType,
      isCurrent: _isCurrent,
      startDate: _startDate,
      endDate: _isCurrent ? null : (_endDate.isNotEmpty ? _endDate : null),
      description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
    );

    final success = await db.saveUserExperience(
      updatedExp,
      shareAsMilestone: _shareAsMilestone,
      milestoneNote: _milestoneNoteCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _shareAsMilestone
                  ? 'Experience saved and milestone post shared to feed! 🎉'
                  : 'Experience saved successfully!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save experience. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.experience == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Experience?'),
        content: Text('Are you sure you want to delete "${widget.experience!.title}" at ${widget.experience!.company}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      final db = Provider.of<DatabaseService>(context, listen: false);
      final success = await db.deleteUserExperience(widget.experience!.id);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          widget.onSaved?.call();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Experience deleted')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isEditing = widget.experience != null;
    final fieldBg = isDark ? const Color(0xFF1E2130) : const Color(0xFFF9FAFB);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
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

                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.work_outline_rounded, color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Experience' : 'Add Experience',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Job Title
                _inputField(
                  controller: _titleCtrl,
                  label: 'Job Title *',
                  hint: 'e.g. Senior Software Engineer',
                  bg: fieldBg,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
                ),
                const SizedBox(height: 14),

                // Company Name
                _inputField(
                  controller: _companyCtrl,
                  label: 'Company / Organization *',
                  hint: 'e.g. Google, TechCorp',
                  bg: fieldBg,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter company name' : null,
                ),
                const SizedBox(height: 14),

                // Employment Type Chips
                _label('Employment Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _employmentTypes.map((type) {
                    final isSel = _employmentType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _employmentType = type);
                      },
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : context.textPrimary,
                      ),
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: fieldBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF6366F1) : context.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Location & Location Type
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _inputField(
                        controller: _locationCtrl,
                        label: 'Location',
                        hint: 'e.g. Dhaka, Bangladesh',
                        bg: fieldBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Work Mode'),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.border, width: 1.2),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _locationType,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                items: _locationTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _locationType = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Currently Working Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isCurrent,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setState(() => _isCurrent = val ?? true);
                      },
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isCurrent = !_isCurrent),
                      child: Text(
                        'I am currently working in this role',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Start & End Dates
                Row(
                  children: [
                    Expanded(
                      child: _datePickerTile(
                        label: 'Start Date *',
                        value: _startDate,
                        onTap: () => _pickDate(isStart: true),
                        bg: fieldBg,
                      ),
                    ),
                    if (!_isCurrent) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _datePickerTile(
                          label: 'End Date',
                          value: _endDate.isNotEmpty ? _endDate : 'Select',
                          onTap: () => _pickDate(isStart: false),
                          bg: fieldBg,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                _inputField(
                  controller: _descriptionCtrl,
                  label: 'Description / Responsibilities',
                  hint: 'Summary of achievements, responsibilities, technologies used...',
                  bg: fieldBg,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),

                // ── Milestone Celebration Post Box (Facebook/LinkedIn Style) ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                          : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share milestone with followers',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Creates a celebratory post on your feed',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _shareAsMilestone,
                            activeTrackColor: const Color(0xFF6366F1),
                            onChanged: (val) => setState(() => _shareAsMilestone = val),
                          ),
                        ],
                      ),
                      if (_shareAsMilestone) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _milestoneNoteCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Add an optional note e.g. "Excited to embark on this new journey! 🚀"',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                            filled: true,
                            fillColor: isDark ? Colors.black26 : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: context.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: GoogleFonts.inter(fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    if (isEditing) ...[
                      IconButton(
                        tooltip: 'Delete Experience',
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: _isSaving ? null : _handleDelete,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0085FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Add to Profile',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: context.textSecondary,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color bg,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
            filled: true,
            fillColor: bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color bg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.border, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: value == 'Select' ? context.textMuted : context.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.calendar_month_outlined, size: 16, color: context.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
