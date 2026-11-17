import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../models/dashboard_analytics.dart';

class ContentOverviewCard extends StatelessWidget {
  final ContentAnalytics analytics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ContentOverviewCard({
    super.key,
    required this.analytics,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Website Content Overview',
                      style: AppTypography.headingSmall()),
                  const SizedBox(height: 4),
                  Text(
                    'Live publication status across CMS modules',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                _buildStatusPill(
                  label: '${analytics.totalPublished} Live',
                  color: AppColors.successGreen,
                  bgColor: const Color(0xFFECFDF5),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  label: '${analytics.totalDrafts} Drafts',
                  color: AppColors.warningOrange,
                  bgColor: AppColors.softGoldBg,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (errorMessage != null)
          _buildErrorBanner()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1100
                  ? 3
                  : width > 650
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width > 1100 ? 2.1 : 2.5,
                children: [
                  _buildModuleContentCard(
                    title: 'Courses',
                    subtitle: 'Classes 1–10 curriculum',
                    icon: Icons.menu_book_outlined,
                    publishedCount: analytics.publishedCourses,
                    draftCount: analytics.draftCourses,
                    route: RoutePaths.courses,
                    context: context,
                  ),
                  _buildModuleContentCard(
                    title: 'Special Programs',
                    subtitle: 'Special care, Abacus & English',
                    icon: Icons.school_outlined,
                    publishedCount: analytics.publishedPrograms,
                    draftCount: analytics.draftPrograms,
                    route: RoutePaths.programs,
                    context: context,
                  ),
                  _buildModuleContentCard(
                    title: 'Testimonials',
                    subtitle: 'Student and parent reviews',
                    icon: Icons.reviews_outlined,
                    publishedCount: analytics.publishedTestimonials,
                    draftCount: analytics.draftTestimonials,
                    route: RoutePaths.testimonials,
                    context: context,
                  ),
                  _buildModuleContentCard(
                    title: 'Gallery Assets',
                    subtitle: 'Campus photos & student life',
                    icon: Icons.photo_library_outlined,
                    publishedCount: analytics.publishedGallery,
                    draftCount: analytics.draftGallery,
                    route: RoutePaths.gallery,
                    context: context,
                  ),
                  _buildModuleContentCard(
                    title: 'FAQs',
                    subtitle: 'Parent and admission queries',
                    icon: Icons.quiz_outlined,
                    publishedCount: analytics.publishedFaqs,
                    draftCount: analytics.draftFaqs,
                    route: RoutePaths.faqs,
                    context: context,
                  ),
                  _buildModuleContentCard(
                    title: 'Homepage Sections',
                    subtitle: 'Hero, Pillars, CTA & Footer',
                    icon: Icons.view_quilt_outlined,
                    publishedCount: analytics.publishedSections,
                    draftCount: analytics.draftSections,
                    route: RoutePaths.home,
                    context: context,
                    customTag: '${analytics.publishedSections} / 9 Live',
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildModuleContentCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int publishedCount,
    required int draftCount,
    required String route,
    String? customTag,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softBlueBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primaryNavy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (customTag != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.softBlueBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        customTag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildCountBadge(
                    label: 'Live',
                    count: publishedCount,
                    color: AppColors.successGreen,
                    bgColor: const Color(0xFFECFDF5),
                  ),
                  const SizedBox(width: 8),
                  _buildCountBadge(
                    label: 'Draft',
                    count: draftCount,
                    color: AppColors.warningOrange,
                    bgColor: AppColors.softGoldBg,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load website content metrics: $errorMessage',
              style: AppTypography.bodyMedium(color: AppColors.errorRed),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
