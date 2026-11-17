import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/admissions_metrics_card.dart';
import 'widgets/content_overview_card.dart';
import 'widgets/dashboard_shortcuts_card.dart';
import 'widgets/media_overview_card.dart';
import 'widgets/recent_content_card.dart';
import 'widgets/recent_enquiries_card.dart';
import 'widgets/workflow_analytics_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'Administrator';
    final dashboardData = ref.watch(dashboardAnalyticsProvider);
    final refreshController = ref.watch(dashboardRefreshControllerProvider);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 16 : 28,
          24,
          isCompact ? 16 : 28,
          36,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Banner & Manual Refresh Header
            _buildWelcomeBanner(
              context: context,
              userEmail: userEmail,
              isLoading: dashboardData.isAnyLoading,
              lastRefreshed: dashboardData.lastRefreshed,
              onRefresh: () => refreshController.refreshAll(),
            ),
            const SizedBox(height: 28),

            // 2. Key Admissions Metric Cards
            AdmissionsMetricsCard(
              analytics: dashboardData.enquiryAnalytics,
              isLoading: dashboardData.isEnquiriesLoading,
              errorMessage: dashboardData.enquiriesError,
              onRetry: () => refreshController.refreshAll(),
            ),
            const SizedBox(height: 28),

            // 3. Enquiry Workflow Progress Breakdown
            WorkflowAnalyticsCard(
              analytics: dashboardData.enquiryAnalytics,
              isLoading: dashboardData.isEnquiriesLoading,
            ),
            const SizedBox(height: 28),

            // 4. Website Content Overview (Live vs Draft)
            ContentOverviewCard(
              analytics: dashboardData.contentAnalytics,
              isLoading: dashboardData.isContentLoading,
              errorMessage: dashboardData.contentError,
              onRetry: () => refreshController.refreshAll(),
            ),
            const SizedBox(height: 28),

            // 5. Media Library Overview
            MediaOverviewCard(
              analytics: dashboardData.mediaAnalytics,
              isLoading: dashboardData.isMediaLoading,
              errorMessage: dashboardData.mediaError,
              onRetry: () => refreshController.refreshAll(),
            ),
            const SizedBox(height: 28),

            // 6. Recent Admissions Enquiries (Latest 5)
            RecentEnquiriesCard(
              recentEnquiries: dashboardData.enquiryAnalytics.recentEnquiries,
              isLoading: dashboardData.isEnquiriesLoading,
            ),
            const SizedBox(height: 28),

            // 7. Recent CMS Content Updates (Latest 6)
            RecentContentCard(
              recentUpdates: dashboardData.contentAnalytics.recentUpdates,
              isLoading: dashboardData.isContentLoading,
            ),
            const SizedBox(height: 32),

            // 8. Quick Navigation Shortcuts
            const DashboardShortcutsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner({
    required BuildContext context,
    required String userEmail,
    required bool isLoading,
    required DateTime lastRefreshed,
    required VoidCallback onRefresh,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.mediumNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
          final isNarrow = constraints.maxWidth < 850;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: AppColors.primaryGold.withValues(
                                alpha: 0.4,
                              ),
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
                              Flexible(
                                child: Text(
                                  'Administrator Portal • Authorized Session',
                                  style:
                                      AppTypography.bodySmall(
                                        color: AppColors.lightGold,
                                      ).copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                  overflow: TextOverflow.ellipsis,
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
                          'Real-time overview of academy admissions enquiries, website publication state, and media library assets.',
                          style: AppTypography.bodyMedium(
                            color: const Color(0xFFD0D7E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 20),
                    _buildRefreshAction(
                      isLoading: isLoading,
                      lastRefreshed: lastRefreshed,
                      onRefresh: onRefresh,
                    ),
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                _buildRefreshAction(
                  isLoading: isLoading,
                  lastRefreshed: lastRefreshed,
                  onRefresh: onRefresh,
                  fullWidth: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRefreshAction({
    required bool isLoading,
    required DateTime lastRefreshed,
    required VoidCallback onRefresh,
    bool fullWidth = false,
  }) {
    final timeStr =
        '${lastRefreshed.hour.toString().padLeft(2, '0')}:${lastRefreshed.minute.toString().padLeft(2, '0')}:${lastRefreshed.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fullWidth
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Updated: $timeStr',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryNavy,
                    ),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: Text(
              isLoading ? 'Refreshing...' : 'Refresh',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
