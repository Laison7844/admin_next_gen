import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routing/route_paths.dart';

class DashboardShortcutsCard extends StatelessWidget {
  const DashboardShortcutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Navigation Shortcuts',
          style: AppTypography.headingSmall(),
        ),
        const SizedBox(height: 4),
        Text(
          'Jump directly into content management modules and administrative tools',
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
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
              childAspectRatio: width > 1100 ? 2.5 : 2.8,
              children: [
                _buildShortcutTile(
                  context: context,
                  title: 'Home CMS',
                  subtitle: 'Hero banner, learning pillars & footer',
                  icon: Icons.home_outlined,
                  route: RoutePaths.home,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Courses',
                  subtitle: 'Classes 1–10 syllabus and schedules',
                  icon: Icons.menu_book_outlined,
                  route: RoutePaths.courses,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Special Programs',
                  subtitle: 'Special care, Abacus & Spoken English',
                  icon: Icons.school_outlined,
                  route: RoutePaths.programs,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Gallery Assets',
                  subtitle: 'Campus photos, events & labs',
                  icon: Icons.photo_library_outlined,
                  route: RoutePaths.gallery,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Frequently Asked Questions',
                  subtitle: 'Parent and admission queries',
                  icon: Icons.quiz_outlined,
                  route: RoutePaths.faqs,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Admissions Enquiries',
                  subtitle: 'Review, contact and enroll leads',
                  icon: Icons.mail_outline,
                  route: RoutePaths.enquiries,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Media Library',
                  subtitle: 'Upload and manage storage assets',
                  icon: Icons.perm_media_outlined,
                  route: RoutePaths.mediaLibrary,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Student Testimonials',
                  subtitle: 'Student and parent success stories',
                  icon: Icons.reviews_outlined,
                  route: RoutePaths.testimonials,
                ),
                _buildShortcutTile(
                  context: context,
                  title: 'Academy Settings',
                  subtitle: 'Site meta, contact info & addresses',
                  icon: Icons.settings_outlined,
                  route: RoutePaths.settings,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildShortcutTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softBlueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryNavy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

