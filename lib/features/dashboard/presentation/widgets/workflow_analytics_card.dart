import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../models/dashboard_analytics.dart';

class WorkflowAnalyticsCard extends StatelessWidget {
  final EnquiryAnalytics analytics;
  final bool isLoading;

  const WorkflowAnalyticsCard({
    super.key,
    required this.analytics,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = analytics.totalLoaded;
    final newPct = analytics.percentage(analytics.newCount);
    final contactedPct = analytics.percentage(analytics.contactedCount);
    final enrolledPct = analytics.percentage(analytics.enrolledCount);
    final closedPct = analytics.percentage(analytics.closedCount);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enquiry Workflow Progress',
                        style: AppTypography.headingSmall(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distribution across admissions stages (Sample: up to 100 loaded records)',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(RoutePaths.enquiries),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Manage Workflow'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Segmented Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 16,
                child: total == 0 || isLoading
                    ? Container(
                        color: AppColors.softGrayBg,
                        alignment: Alignment.center,
                        child: Text(
                          isLoading ? 'Loading workflow data...' : 'No enquiries recorded',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          if (analytics.newCount > 0)
                            Expanded(
                              flex: analytics.newCount,
                              child: Container(color: AppColors.primaryGold),
                            ),
                          if (analytics.contactedCount > 0)
                            Expanded(
                              flex: analytics.contactedCount,
                              child: Container(color: AppColors.infoBlue),
                            ),
                          if (analytics.enrolledCount > 0)
                            Expanded(
                              flex: analytics.enrolledCount,
                              child: Container(color: AppColors.successGreen),
                            ),
                          if (analytics.closedCount > 0)
                            Expanded(
                              flex: analytics.closedCount,
                              child: Container(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Workflow Stage Legend
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final crossAxisCount = isNarrow ? 2 : 4;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isNarrow ? 2.2 : 2.6,
                  children: [
                    _buildLegendItem(
                      label: 'New',
                      count: analytics.newCount,
                      percentage: newPct,
                      color: AppColors.primaryGold,
                      bgColor: AppColors.softGoldBg,
                      icon: Icons.fiber_new_outlined,
                    ),
                    _buildLegendItem(
                      label: 'Contacted',
                      count: analytics.contactedCount,
                      percentage: contactedPct,
                      color: AppColors.infoBlue,
                      bgColor: AppColors.softBlueBg,
                      icon: Icons.phone_callback_outlined,
                    ),
                    _buildLegendItem(
                      label: 'Enrolled',
                      count: analytics.enrolledCount,
                      percentage: enrolledPct,
                      color: AppColors.successGreen,
                      bgColor: const Color(0xFFECFDF5),
                      icon: Icons.how_to_reg_outlined,
                    ),
                    _buildLegendItem(
                      label: 'Closed',
                      count: analytics.closedCount,
                      percentage: closedPct,
                      color: AppColors.textSecondary,
                      bgColor: AppColors.softGrayBg,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 12),

            // Summary Pills
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildSummaryBadge(
                  label: 'Active Leads',
                  value: '${analytics.activeCount}',
                  color: AppColors.successGreen,
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildSummaryBadge(
                  label: 'Archived Leads',
                  value: '${analytics.archivedCount}',
                  color: AppColors.textSecondary,
                  bgColor: AppColors.softGrayBg,
                ),
                _buildSummaryBadge(
                  label: 'Last 7 Days',
                  value: '${analytics.last7DaysCount}',
                  color: AppColors.primaryGold,
                  bgColor: AppColors.softGoldBg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int count,
    required double percentage,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count (${percentage.toStringAsFixed(0)}%)',
                  style: AppTypography.bodySmall(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
