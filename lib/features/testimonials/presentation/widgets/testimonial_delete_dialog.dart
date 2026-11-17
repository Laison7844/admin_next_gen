import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/testimonial_item.dart';

enum TestimonialDeleteAction {
  unpublishOnly,
  permanentDelete,
}

/// Confirmation dialog that clearly distinguishes between removing a
/// published testimonial from the live public site (unpublishing, preserving
/// the working draft) versus permanently deleting the record entirely.
class TestimonialDeleteDialog extends StatelessWidget {
  final TestimonialItem testimonial;

  const TestimonialDeleteDialog({
    super.key,
    required this.testimonial,
  });

  static Future<TestimonialDeleteAction?> show(
    BuildContext context,
    TestimonialItem testimonial,
  ) {
    return showDialog<TestimonialDeleteAction>(
      context: context,
      builder: (ctx) => TestimonialDeleteDialog(testimonial: testimonial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPublished = testimonial.isPublished;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.errorRed, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isPublished ? 'Manage Testimonial' : 'Delete Testimonial Draft',
            style: AppTypography.titleMedium(color: AppColors.primaryNavy),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'You selected the testimonial from '),
                  TextSpan(
                    text: '"${testimonial.personName}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isPublished) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softBlueBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Option A: Unpublish from Public Website',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Removes the testimonial from the live public website immediately, while safely retaining the draft in your CMS for future editing or re-publishing.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPublished
                        ? 'Option B: Permanent Deletion'
                        : 'Permanent Deletion',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.errorRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPublished
                        ? 'Permanently destroys the draft and deletes the testimonial from the live public website. This action cannot be undone.'
                        : 'Permanently destroys this draft from the CMS. This action cannot be undone.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (isPublished)
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility_off_outlined, size: 16),
            label: const Text('Unpublish Only'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryNavy,
              side: const BorderSide(color: AppColors.primaryNavy),
            ),
            onPressed: () =>
                Navigator.of(context).pop(TestimonialDeleteAction.unpublishOnly),
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, size: 16),
          label: const Text('Permanently Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context)
              .pop(TestimonialDeleteAction.permanentDelete),
        ),
      ],
    );
  }
}
