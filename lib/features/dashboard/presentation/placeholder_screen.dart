import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softBlueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryNavy, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.headingMedium()),
                  const SizedBox(height: 2),
                  Text(
                    'Content Management Module',
                    style: AppTypography.bodySmall(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const Duration(milliseconds: 0) == Duration.zero
                      ? const BoxConstraints(maxWidth: 540)
                      : const BoxConstraints(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.softGoldBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 34,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$title Management',
                        style: AppTypography.headingSmall(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: AppTypography.bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGrayBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Navigation Placeholder • Scheduled for Phase 2',
                                style: AppTypography.bodySmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
