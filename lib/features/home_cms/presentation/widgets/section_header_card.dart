import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/home_section_definition.dart';

/// Reusable header card for both standalone section screens and Home CMS section pane.
class SectionHeaderCard extends StatelessWidget {
  final HomeSectionDefinition section;

  const SectionHeaderCard({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryNavy,
            child: Icon(section.icon, color: AppColors.primaryGold, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      section.title,
                      style: AppTypography.headingMedium().copyWith(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        section.isSingleton
                            ? 'Singleton Document'
                            : 'Multi-Item Collection',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  section.description,
                  style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Firestore Public Target: ${section.isSingleton ? 'site_sections/${section.id}' : '${section.contentType.publicCollection}/*'}  •  Draft Target: cms_drafts/*',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

