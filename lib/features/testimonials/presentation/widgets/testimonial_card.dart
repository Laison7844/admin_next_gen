import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/testimonial_item.dart';

class TestimonialCard extends StatelessWidget {
  final TestimonialItem testimonial;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  const TestimonialCard({
    super.key,
    required this.testimonial,
    required this.onPreview,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(testimonial.personName);
    final isPublished = testimonial.isPublished;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: testimonial.isFeatured
              ? AppColors.primaryGold.withValues(alpha: 0.8)
              : AppColors.borderLight,
          width: testimonial.isFeatured ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: testimonial.isFeatured
                ? AppColors.primaryGold.withValues(alpha: 0.08)
                : AppColors.shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Status Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
                backgroundImage: (testimonial.profileImage != null &&
                        testimonial.profileImage!.isNotEmpty)
                    ? NetworkImage(testimonial.profileImage!)
                    : null,
                child: (testimonial.profileImage == null ||
                        testimonial.profileImage!.isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            testimonial.personName,
                            style: AppTypography.titleMedium(
                                color: AppColors.primaryNavy),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (testimonial.isFeatured) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.primaryGold, width: 0.8),
                            ),
                            child: const Text(
                              'Featured',
                              style: TextStyle(
                                color: AppColors.darkGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.softBlueBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            testimonial.role,
                            style: const TextStyle(
                              color: AppColors.primaryNavy,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (testimonial.program != null &&
                            testimonial.program!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.softGoldBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              testimonial.program!,
                              style: const TextStyle(
                                color: AppColors.darkGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? AppColors.successGreen.withValues(alpha: 0.15)
                          : AppColors.softGrayBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPublished
                            ? AppColors.successGreen
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Text(
                      isPublished ? 'LIVE' : 'DRAFT ONLY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPublished
                            ? AppColors.successGreen
                            : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.softGrayBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Order: ${testimonial.displayOrder}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Rating row (if provided)
          if (testimonial.rating > 0) ...[
            Row(
              children: List.generate(5, (index) {
                final filled = index < testimonial.rating;
                return Icon(
                  filled ? Icons.star : Icons.star_border,
                  size: 16,
                  color: filled ? AppColors.primaryGold : AppColors.borderLight,
                );
              }),
            ),
            const SizedBox(height: 8),
          ],

          // Testimonial Text Snippet
          Text(
            '"${testimonial.testimonialText}"',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),

          // Footer action buttons
          Row(
            children: [
              Text(
                'ID: ${testimonial.id}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              // Preview Button
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                tooltip: 'Preview Card',
                color: AppColors.textSecondary,
                onPressed: onPreview,
              ),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Draft',
                color: AppColors.textSecondary,
                onPressed: onEdit,
              ),
              const SizedBox(width: 4),
              // Publish / Unpublish Button
              ElevatedButton.icon(
                icon: Icon(
                  isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.publish_outlined,
                  size: 14,
                ),
                label: Text(isPublished ? 'Unpublish' : 'Publish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPublished
                      ? AppColors.softGrayBg
                      : AppColors.primaryGold,
                  foregroundColor: isPublished
                      ? AppColors.textPrimary
                      : AppColors.primaryNavy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0,
                ),
                onPressed: onTogglePublish,
              ),
              const SizedBox(width: 4),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Delete Testimonial',
                color: AppColors.errorRed,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NA';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
