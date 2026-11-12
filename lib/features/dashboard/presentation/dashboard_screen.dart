import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'Administrator';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryNavy, AppColors.mediumNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryGold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: AppColors.lightGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Phase 1 • Secure Foundation',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.lightGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome back, $userEmail',
                            style: AppTypography.headingMedium(
                              color: AppColors.surfaceWhite,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage academy content, courses, programs, and student enquiries from this centralized portal.',
                            style: AppTypography.bodyMedium(
                              color: const Color(0xFFD0D7E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_outlined,
                          size: 48,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Overview Stats Grid
          Text('System Status & Overview', style: AppTypography.headingSmall()),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1100
                  ? 4
                  : width > 700
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width > 1100 ? 1.6 : 2.2,
                children: [
                  _buildStatCard(
                    title: 'Live Website',
                    value: 'Online',
                    subtitle: 'next-gen-excellence.web.app',
                    icon: Icons.public,
                    iconColor: AppColors.successGreen,
                    bgColor: AppColors.softBlueBg,
                  ),
                  _buildStatCard(
                    title: 'Firebase Project',
                    value: 'Connected',
                    subtitle: 'next-gen-excellence (Blaze)',
                    icon: Icons.cloud_done_outlined,
                    iconColor: AppColors.infoBlue,
                    bgColor: AppColors.softBlueBg,
                  ),
                  _buildStatCard(
                    title: 'Authentication',
                    value: 'Active',
                    subtitle: 'Single Admin Protected',
                    icon: Icons.lock_outline,
                    iconColor: AppColors.primaryGold,
                    bgColor: AppColors.softGoldBg,
                  ),
                  _buildStatCard(
                    title: 'CMS Modules',
                    value: '10 Sections',
                    subtitle: 'Phase 1 Placeholders Ready',
                    icon: Icons.auto_stories_outlined,
                    iconColor: AppColors.accentCyan,
                    bgColor: AppColors.softGrayBg,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Quick Navigation Shortcuts
          Text('Content Modules Quick Access', style: AppTypography.headingSmall()),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1000
                  ? 3
                  : width > 600
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.3,
                children: [
                  _buildModuleTile(
                    context: context,
                    title: 'Courses',
                    subtitle: 'Curriculum, schedules & levels',
                    icon: Icons.menu_book_outlined,
                    route: RoutePaths.courses,
                  ),
                  _buildModuleTile(
                    context: context,
                    title: 'Programs',
                    subtitle: 'Academic tracks & training',
                    icon: Icons.school_outlined,
                    route: RoutePaths.programs,
                  ),
                  _buildModuleTile(
                    context: context,
                    title: 'Enquiries',
                    subtitle: 'Student and parent submissions',
                    icon: Icons.mail_outline,
                    route: RoutePaths.enquiries,
                  ),
                  _buildModuleTile(
                    context: context,
                    title: 'Media Library',
                    subtitle: 'Academy photos, documents & assets',
                    icon: Icons.perm_media_outlined,
                    route: RoutePaths.mediaLibrary,
                  ),
                  _buildModuleTile(
                    context: context,
                    title: 'Testimonials',
                    subtitle: 'Student reviews & success stories',
                    icon: Icons.reviews_outlined,
                    route: RoutePaths.testimonials,
                  ),
                  _buildModuleTile(
                    context: context,
                    title: 'Settings',
                    subtitle: 'Site meta, contact & configuration',
                    icon: Icons.settings_outlined,
                    route: RoutePaths.settings,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTypography.bodySmall()),
                  const SizedBox(height: 4),
                  Text(value, style: AppTypography.titleMedium()),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return Card(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
                    Text(title, style: AppTypography.titleMedium()),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall(),
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

