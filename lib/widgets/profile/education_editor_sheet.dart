import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_education.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class EducationEditorSheet extends StatefulWidget {
  final UserEducation? education; // null if adding new
  final VoidCallback? onSaved;

  const EducationEditorSheet({
    super.key,
    this.education,
    this.onSaved,
  });

  static Future<void> show(BuildContext context, {UserEducation? education, VoidCallback? onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EducationEditorSheet(education: education, onSaved: onSaved),
    );
  }

  @override
  State<EducationEditorSheet> createState() => _EducationEditorSheetState();
}

class _EducationEditorSheetState extends State<EducationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _schoolCtrl;
  late TextEditingController _degreeCtrl;
  late TextEditingController _fieldCtrl;
  late TextEditingController _gradeCtrl;
  late TextEditingController _activitiesCtrl;
  late TextEditingController _descriptionCtrl;

  bool _isCurrent = false;
  String _startDate = '';
  String _endDate = '';
  bool _isSaving = false;

  final List<String> _popularDegrees = [
    'Bachelor of Science (BSc)',
    'Bachelor of Arts (BA)',
    'Bachelor of Business Admin (BBA)',
    'Master of Science (MSc)',
    'Master of Business Admin (MBA)',
    'Doctor of Philosophy (PhD)',
    'Higher Secondary Certificate (HSC)',
    'Secondary School Certificate (SSC)',
    'Diploma',
  ];

  @override
  void initState() {
    super.initState();
    final edu = widget.education;
    _schoolCtrl = TextEditingController(text: edu?.school ?? '');
    _degreeCtrl = TextEditingController(text: edu?.degree ?? '');
    _fieldCtrl = TextEditingController(text: edu?.fieldOfStudy ?? '');
    _gradeCtrl = TextEditingController(text: edu?.grade ?? '');
    _activitiesCtrl = TextEditingController(text: edu?.activities ?? '');
    _descriptionCtrl = TextEditingController(text: edu?.description ?? '');

    if (edu != null) {
      _isCurrent = edu.isCurrent;
      _startDate = edu.startDate;
      _endDate = edu.endDate ?? '';
    } else {
      final now = DateTime.now();
      _startDate = '${now.year - 4}';
      _endDate = '${now.year}';
    }
  }

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _degreeCtrl.dispose();
    _fieldCtrl.dispose();
    _gradeCtrl.dispose();
    _activitiesCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickYear({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime(int.tryParse(_startDate) ?? now.year) : DateTime(int.tryParse(_endDate) ?? now.year),
      firstDate: DateTime(1960),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      helpText: isStart ? 'SELECT START YEAR' : 'SELECT END YEAR',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = '${picked.year}';
        } else {
          _endDate = '${picked.year}';
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start year')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = Provider.of<DatabaseService>(context, listen: false);

    final updatedEdu = UserEducation(
      id: widget.education?.id ?? '',
      userId: db.currentUid,
      school: _schoolCtrl.text.trim(),
      degree: _degreeCtrl.text.trim().isNotEmpty ? _degreeCtrl.text.trim() : null,
      fieldOfStudy: _fieldCtrl.text.trim().isNotEmpty ? _fieldCtrl.text.trim() : null,
      startDate: _startDate,
      endDate: _isCurrent ? null : (_endDate.isNotEmpty ? _endDate : null),
      isCurrent: _isCurrent,
      grade: _gradeCtrl.text.trim().isNotEmpty ? _gradeCtrl.text.trim() : null,
      activities: _activitiesCtrl.text.trim().isNotEmpty ? _activitiesCtrl.text.trim() : null,
      description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
    );

    final success = await db.saveUserEducation(
      updatedEdu,
      shareAsMilestone: false,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Education saved successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save education. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.education == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Education?'),
        content: Text('Are you sure you want to delete "${widget.education!.school}"?'),
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
      final success = await db.deleteUserEducation(widget.education!.id);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          widget.onSaved?.call();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Education deleted')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isEditing = widget.education != null;
    final fieldBg = isDark ? const Color(0xFF0C101D) : const Color(0xFFF8FAFC);

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
                        color: context.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.school_outlined, color: context.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Education' : 'Add Education',
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

                // School / University
                _inputField(
                  controller: _schoolCtrl,
                  label: 'School / College / University *',
                  hint: 'e.g. University of Dhaka, BUET',
                  bg: fieldBg,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter institution name' : null,
                ),
                const SizedBox(height: 14),

                // Degree
                _inputField(
                  controller: _degreeCtrl,
                  label: 'Degree',
                  hint: 'e.g. Bachelor of Science',
                  bg: fieldBg,
                ),
                const SizedBox(height: 8),

                // Quick degree pills
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularDegrees.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final deg = _popularDegrees[i];
                      return ActionChip(
                        label: Text(deg, style: GoogleFonts.inter(fontSize: 11)),
                        backgroundColor: fieldBg,
                        side: BorderSide(color: context.border),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () => setState(() => _degreeCtrl.text = deg),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Field of Study
                _inputField(
                  controller: _fieldCtrl,
                  label: 'Field of Study',
                  hint: 'e.g. Computer Science, Economics',
                  bg: fieldBg,
                ),
                const SizedBox(height: 14),

                // Currently Studying Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isCurrent,
                      activeColor: context.primaryAccent,
                      onChanged: (val) {
                        setState(() => _isCurrent = val ?? false);
                      },
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isCurrent = !_isCurrent),
                      child: Text(
                        'I am currently studying here',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Start & End Year
                Row(
                  children: [
                    Expanded(
                      child: _datePickerTile(
                        label: 'Start Year *',
                        value: _startDate,
                        onTap: () => _pickYear(isStart: true),
                        bg: fieldBg,
                      ),
                    ),
                    if (!_isCurrent) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _datePickerTile(
                          label: 'End Year (or Expected)',
                          value: _endDate.isNotEmpty ? _endDate : 'Select',
                          onTap: () => _pickYear(isStart: false),
                          bg: fieldBg,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Grade / CGPA & Activities
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _inputField(
                        controller: _gradeCtrl,
                        label: 'Grade / CGPA',
                        hint: 'e.g. 3.85 / 4.00',
                        bg: fieldBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _inputField(
                        controller: _activitiesCtrl,
                        label: 'Activities & Clubs',
                        hint: 'e.g. Debate Club, IEEE',
                        bg: fieldBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                _inputField(
                  controller: _descriptionCtrl,
                  label: 'Description',
                  hint: 'Academic focus, thesis, notable projects...',
                  bg: fieldBg,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    if (isEditing) ...[
                      IconButton(
                        tooltip: 'Delete Education',
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: _isSaving ? null : _handleDelete,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryAccent,
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
              borderSide: BorderSide(color: context.primaryAccent, width: 1.5),
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
