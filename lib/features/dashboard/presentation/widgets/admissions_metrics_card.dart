import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/dashboard_analytics.dart';

class AdmissionsMetricsCard extends StatelessWidget {
  final EnquiryAnalytics analytics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AdmissionsMetricsCard({
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
                  Text('Admissions Enquiries Overview',
                      style: AppTypography.headingSmall()),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softBlueBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.infoBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Latest Loaded Sample • Max 100 Records',
                          style: AppTypography.bodySmall(
                            color: AppColors.infoBlue,
                          ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (errorMessage != null)
          _buildErrorBanner(context)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1100
                  ? 4
                  : width > 650
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width > 1100 ? 1.8 : 2.2,
                children: [
                  _buildStatTile(
                    title: 'Total Loaded Enquiries',
                    value: isLoading ? '...' : '${analytics.totalLoaded}',
                    subtitle: 'Latest admissions records',
                    icon: Icons.all_inbox_outlined,
                    iconColor: AppColors.primaryNavy,
                    bgColor: AppColors.softBlueBg,
                  ),
                  _buildStatTile(
                    title: 'Active / Received',
                    value: isLoading ? '...' : '${analytics.activeCount}',
                    subtitle: 'Pending follow-up or in process',
                    icon: Icons.mark_email_unread_outlined,
                    iconColor: AppColors.successGreen,
                    bgColor: const Color(0xFFECFDF5),
                  ),
                  _buildStatTile(
                    title: 'Archived Enquiries',
                    value: isLoading ? '...' : '${analytics.archivedCount}',
                    subtitle: 'Completed or closed leads',
                    icon: Icons.archive_outlined,
                    iconColor: AppColors.textSecondary,
                    bgColor: AppColors.softGrayBg,
                  ),
                  _buildStatTile(
                    title: 'Received Last 7 Days',
                    value: isLoading ? '...' : '${analytics.last7DaysCount}',
                    subtitle: 'Recent admissions interest',
                    icon: Icons.date_range_outlined,
                    iconColor: AppColors.primaryGold,
                    bgColor: AppColors.softGoldBg,
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.headingMedium(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
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
              'Unable to load admissions enquiries: $errorMessage',
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

