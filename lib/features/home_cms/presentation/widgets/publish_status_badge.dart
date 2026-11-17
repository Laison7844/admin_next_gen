import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../content/models/publish_status.dart';

class PublishStatusBadge extends StatelessWidget {
  final PublishStatus status;
  final bool hasUnpublishedChanges;

  const PublishStatusBadge({
    super.key,
    required this.status,
    this.hasUnpublishedChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isPublished && !hasUnpublishedChanges) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Published',
              style: AppTypography.bodySmall(
                color: AppColors.successGreen,
              ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (status.isPublished && hasUnpublishedChanges) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warningOrange.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.warningOrange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Changes Not Saved',
              style: AppTypography.bodySmall(
                color: AppColors.warningOrange,
              ).copyWith(fontWeight: FontWeight.bold, fontSize: 10.5),
            ),
          ],
        ),
      );
    }

    // Pure draft
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softGrayBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Unpublished',
            style: AppTypography.bodySmall(
              color: AppColors.textSecondary,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
