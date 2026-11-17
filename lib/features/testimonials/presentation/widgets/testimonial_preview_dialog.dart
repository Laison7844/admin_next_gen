import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/testimonial_item.dart';

/// Modal dialog that presents an exact preview of how the testimonial
/// will render on the public website.
class TestimonialPreviewDialog extends StatelessWidget {
  final TestimonialItem testimonial;

  const TestimonialPreviewDialog({
    super.key,
    required this.testimonial,
  });

  static Future<void> show(BuildContext context, TestimonialItem testimonial) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => TestimonialPreviewDialog(testimonial: testimonial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(testimonial.personName);
    final subtitle = testimonial.program != null &&
            testimonial.program!.trim().isNotEmpty
        ? '${testimonial.role} • ${testimonial.program!.trim()}'
        : testimonial.role;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined,
                      color: AppColors.primaryGold, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Live Website Card Preview',
                    style: AppTypography.titleMedium(color: AppColors.primaryNavy),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Card Preview Content
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: testimonial.isFeatured
                        ? AppColors.primaryGold
                        : AppColors.borderLight,
                    width: testimonial.isFeatured ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: testimonial.isFeatured
                          ? AppColors.primaryGold.withValues(alpha: 0.12)
                          : AppColors.shadowColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Quote icon + Featured badge + Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.primaryGold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (testimonial.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Featured',
                              style: TextStyle(
                                color: AppColors.primaryNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (testimonial.rating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) {
                              final filled = index < testimonial.rating;
                              return Icon(
                                filled ? Icons.star : Icons.star_border,
                                size: 18,
                                color: filled
                                    ? AppColors.primaryGold
                                    : AppColors.borderLight,
                              );
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Testimonial Text
                    Text(
                      '"${testimonial.testimonialText}"',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 22),

                    const Divider(color: AppColors.borderLight, height: 1),
                    const SizedBox(height: 18),

                    // Author Profile Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppColors.primaryNavy.withValues(alpha: 0.08),
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
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testimonial.personName,
                                style: const TextStyle(
                                  color: AppColors.primaryNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.surfaceWhite,
                    ),
                    child: const Text('Close Preview'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
