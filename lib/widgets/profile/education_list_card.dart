// NOTE: [UNUSED / REFERENCE ONLY]
// This education list card widget is currently not active in ProfileScreen.
// Kept for future profile customization enhancements.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_education.dart';
import '../../utils/app_theme.dart';
import 'education_editor_sheet.dart';

class EducationListCard extends StatelessWidget {
  final List<UserEducation> educations;
  final bool isOwnProfile;
  final VoidCallback? onRefresh;

  const EducationListCard({
    super.key,
    required this.educations,
    required this.isOwnProfile,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardBg = isDark ? const Color(0xFF161922) : Colors.white;
    final borderCol = isDark ? const Color(0xFF24273F) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_outlined, size: 18, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              Text(
                'Education',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              if (educations.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${educations.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isOwnProfile)
                IconButton(
                  tooltip: 'Add Education',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF10B981)),
                  onPressed: () => EducationEditorSheet.show(context, onSaved: onRefresh),
                ),
            ],
          ),

          if (educations.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 36, color: context.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      isOwnProfile ? 'Showcase your educational background' : 'No education details shared yet',
                      style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
                    ),
                    if (isOwnProfile) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => EducationEditorSheet.show(context, onSaved: onRefresh),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Education'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: educations.length,
              separatorBuilder: (context, index) => Divider(height: 24, color: context.border, thickness: 0.7),
              itemBuilder: (ctx, i) {
                final edu = educations[i];
                return _buildEducationItem(context, edu, isDark);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(BuildContext context, UserEducation edu, bool isDark) {
    final schoolInitial = edu.school.isNotEmpty ? edu.school[0].toUpperCase() : 'E';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School logo avatar / badge
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              schoolInitial,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      edu.school,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  if (isOwnProfile)
                    GestureDetector(
                      onTap: () => EducationEditorSheet.show(context, education: edu, onSaved: onRefresh),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.edit_outlined, size: 16, color: context.textMuted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),

              // Degree and Field of study
              if (edu.degreeWithField.isNotEmpty) ...[
                Text(
                  edu.degreeWithField,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
              ],

              // Period
              Text(
                edu.periodString,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMuted,
                ),
              ),

              // Grade
              if (edu.grade != null && edu.grade!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Grade: ${edu.grade}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textMuted,
                  ),
                ),
              ],

              // Activities / Societies
              if (edu.activities != null && edu.activities!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Activities: ${edu.activities}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: context.textSecondary,
                  ),
                ),
              ],

              // Description
              if (edu.description != null && edu.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  edu.description!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
