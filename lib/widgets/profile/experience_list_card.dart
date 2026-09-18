import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_experience.dart';
import '../../utils/app_theme.dart';
import 'experience_editor_sheet.dart';

class ExperienceListCard extends StatelessWidget {
  final List<UserExperience> experiences;
  final bool isOwnProfile;
  final VoidCallback? onRefresh;

  const ExperienceListCard({
    super.key,
    required this.experiences,
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Text(
                'Experience',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              if (experiences.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${experiences.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isOwnProfile)
                IconButton(
                  tooltip: 'Add Experience',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF6366F1)),
                  onPressed: () => ExperienceEditorSheet.show(context, onSaved: onRefresh),
                ),
            ],
          ),

          if (experiences.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.business_center_outlined, size: 36, color: context.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      isOwnProfile ? 'Highlight your career journey' : 'No work experience shared yet',
                      style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
                    ),
                    if (isOwnProfile) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => ExperienceEditorSheet.show(context, onSaved: onRefresh),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Experience'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
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
              itemCount: experiences.length,
              separatorBuilder: (context, index) => Divider(height: 24, color: context.border, thickness: 0.7),
              itemBuilder: (ctx, i) {
                final exp = experiences[i];
                return _buildExperienceItem(context, exp, isDark);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceItem(BuildContext context, UserExperience exp, bool isDark) {
    final companyInitial = exp.company.isNotEmpty ? exp.company[0].toUpperCase() : 'W';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company logo avatar / badge
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              companyInitial,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
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
                      exp.title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  if (isOwnProfile)
                    GestureDetector(
                      onTap: () => ExperienceEditorSheet.show(context, experience: exp, onSaved: onRefresh),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.edit_outlined, size: 16, color: context.textMuted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),

              // Company & Employment Type
              Text(
                '${exp.company} · ${exp.employmentType}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 3),

              // Period & Location
              Text(
                exp.periodString,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMuted,
                ),
              ),
              if (exp.location != null && exp.location!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${exp.location} · ${exp.locationType}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textMuted,
                  ),
                ),
              ],
              if (exp.description != null && exp.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  exp.description!,
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
