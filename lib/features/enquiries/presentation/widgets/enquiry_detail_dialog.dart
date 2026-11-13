import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/phone_dialer.dart';
import '../../models/enquiry_item.dart';
import '../../providers/enquiry_provider.dart';

class EnquiryDetailDialog extends ConsumerWidget {
  final EnquiryItem enquiry;

  const EnquiryDetailDialog({
    super.key,
    required this.enquiry,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Not available';
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today at $timeStr';
    return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
  }

  Future<void> _handleCall(BuildContext context) async {
    final success = await launchPhoneDialer(enquiry.phone);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Dialing ${enquiry.phone} (number copied to clipboard)'
                : 'Phone number ${enquiry.phone} copied to clipboard',
          ),
          backgroundColor: AppColors.primaryNavy,
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Enquiry?'),
        content: Text(
          'Are you sure you want to delete the enquiry from "${enquiry.name.isEmpty ? enquiry.phone : enquiry.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.surfaceWhite,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final controller =
          ref.read(enquiryOperationControllerProvider.notifier);
      final success = await controller.deleteEnquiry(enquiry.phone);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close detail dialog
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enquiry deleted successfully.'),
              backgroundColor: AppColors.mediumNavy,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleToggleStatus(BuildContext context, WidgetRef ref) async {
    final newStatus = !enquiry.status;
    final controller =
        ref.read(enquiryOperationControllerProvider.notifier);
    final success = await controller.toggleStatus(enquiry.phone, newStatus);
    if (context.mounted) {
      Navigator.of(context).pop();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Enquiry marked as Active / Received.'
                  : 'Enquiry archived.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opState = ref.watch(enquiryOperationControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.mediumNavy,
                    child: Text(
                      enquiry.name.isNotEmpty
                          ? enquiry.name[0].toUpperCase()
                          : '#',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enquiry.name.isNotEmpty
                              ? enquiry.name
                              : 'Prospective Student',
                          style: AppTypography.headingSmall(
                            color: AppColors.surfaceWhite,
                          ).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admissions Enquiry Details',
                          style: AppTypography.bodySmall(
                            color: const Color(0xFFD0D7E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Dialog Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Program Banner
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: enquiry.status
                                ? const Color(0xFFECFDF5)
                                : AppColors.softGrayBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: enquiry.status
                                  ? AppColors.successGreen
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                enquiry.status
                                    ? Icons.check_circle_outline
                                    : Icons.archive_outlined,
                                size: 14,
                                color: enquiry.status
                                    ? AppColors.successGreen
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                enquiry.status ? 'ACTIVE / RECEIVED' : 'ARCHIVED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: enquiry.status
                                      ? AppColors.successGreen
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (enquiry.program.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softGoldBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.borderGold.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 14,
                                  color: AppColors.primaryGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  enquiry.program,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Phone Contact Row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              enquiry.phone,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Contact / Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: AppColors.primaryNavy,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onPressed: () => _handleCall(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message Block
                    Text(
                      'Enquiry Message / Remarks',
                      style: AppTypography.headingSmall().copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        enquiry.message.isNotEmpty
                            ? enquiry.message
                            : 'No additional message was included in this enquiry.',
                        style: AppTypography.bodyMedium(
                          color: enquiry.message.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Timestamps & Meta
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Received At',
                                style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateTime(enquiry.createdAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (enquiry.updatedAt != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Updated',
                                  style: AppTypography.bodySmall(
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDateTime(enquiry.updatedAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

            // Dialog Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                    onPressed: opState.isLoading
                        ? null
                        : () => _handleDelete(context, ref),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: Icon(
                      enquiry.status
                          ? Icons.archive_outlined
                          : Icons.unarchive_outlined,
                      size: 16,
                    ),
                    label: Text(
                      enquiry.status ? 'Archive' : 'Restore Active',
                    ),
                    onPressed: opState.isLoading
                        ? null
                        : () => _handleToggleStatus(context, ref),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.surfaceWhite,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
