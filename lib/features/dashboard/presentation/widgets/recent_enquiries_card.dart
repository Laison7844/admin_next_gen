import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../enquiries/models/enquiry_item.dart';

class RecentEnquiriesCard extends StatelessWidget {
  final List<EnquiryItem> recentEnquiries;
  final bool isLoading;

  const RecentEnquiriesCard({
    super.key,
    required this.recentEnquiries,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
                        'Recent Admissions Enquiries',
                        style: AppTypography.headingSmall(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latest submissions received from prospective parents and students',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => context.go(RoutePaths.enquiries),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Enquiries'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (recentEnquiries.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentEnquiries.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: AppColors.borderLight, height: 1),
                itemBuilder: (context, index) {
                  final item = recentEnquiries[index];
                  return _buildEnquiryRow(context, item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryRow(BuildContext context, EnquiryItem item) {
    final displayName = item.name.trim().isNotEmpty ? item.name : item.phone;
    final programText = item.program.trim().isNotEmpty
        ? item.program
        : 'General Admissions';

    return InkWell(
      onTap: () => context.go(RoutePaths.enquiries),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.softBlueBg,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                  fontSize: 14,
                ),
              ),
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
                          displayName,
                          style: AppTypography.titleMedium(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildWorkflowBadge(item.workflowStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        item.phone,
                        style: AppTypography.bodySmall(
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.school_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          programText,
                          style: AppTypography.bodySmall(
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(item.createdAt),
                  style: AppTypography.bodySmall(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.status
                        ? const Color(0xFFECFDF5)
                        : AppColors.softGrayBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status ? 'ACTIVE' : 'ARCHIVED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: item.status
                          ? AppColors.successGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowBadge(String workflowStatus) {
    final status = EnquiryWorkflowStatus.normalize(workflowStatus);
    Color bgColor;
    Color textColor;
    switch (status) {
      case EnquiryWorkflowStatus.contacted:
        bgColor = AppColors.softBlueBg;
        textColor = AppColors.infoBlue;
        break;
      case EnquiryWorkflowStatus.enrolled:
        bgColor = const Color(0xFFECFDF5);
        textColor = AppColors.successGreen;
        break;
      case EnquiryWorkflowStatus.closed:
        bgColor = AppColors.softGrayBg;
        textColor = AppColors.textSecondary;
        break;
      case EnquiryWorkflowStatus.newStatus:
      default:
        bgColor = AppColors.softGoldBg;
        textColor = const Color(0xFFB45309);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        EnquiryWorkflowStatus.displayName(status).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return '$m min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} d ago';
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.softBlueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Admissions Enquiries Received Yet',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Text(
            'When prospective students submit the admissions form on the public website, their records will appear here.',
            style: AppTypography.bodySmall(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
