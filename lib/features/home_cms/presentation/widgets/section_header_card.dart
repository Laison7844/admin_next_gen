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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 540;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isNarrow ? 20 : 26,
                backgroundColor: AppColors.primaryNavy,
                child: Icon(
                  section.icon,
                  color: AppColors.primaryGold,
                  size: isNarrow ? 20 : 26,
                ),
              ),
              SizedBox(width: isNarrow ? 12 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          section.title,
                          style: AppTypography.headingMedium().copyWith(
                            fontSize: isNarrow ? 18 : 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            section.isSingleton
                                ? 'Website Section'
                                : 'Multiple Items',
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
                      section.isSingleton
                          ? 'Website Section: ${section.title}'
                          : 'Website Content: ${section.title}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
