import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../models/dashboard_analytics.dart';

class MediaOverviewCard extends StatelessWidget {
  final MediaAnalytics analytics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const MediaOverviewCard({
    super.key,
    required this.analytics,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
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
                        'Media Library Overview',
                        style: AppTypography.headingSmall(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Assets stored in Firebase Storage buckets',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(RoutePaths.mediaLibrary),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Open Library'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              _buildErrorBanner()
            else ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.perm_media_outlined,
                      color: AppColors.primaryNavy,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading ? '...' : '${analytics.totalImages}',
                        style: AppTypography.headingMedium(color: AppColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total Uploaded Assets',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 12),
              Text(
                'Assets by Folder Category:',
                style: AppTypography.bodySmall(color: AppColors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (analytics.folderCounts.isEmpty && !isLoading)
                Text(
                  'No media assets uploaded yet.',
                  style: AppTypography.bodySmall(color: AppColors.textMuted),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildFolderChip(
                      'Homepage',
                      analytics.folderCounts['homepage'] ?? 0,
                      Icons.home_outlined,
                    ),
                    _buildFolderChip(
                      'Courses',
                      analytics.folderCounts['courses'] ?? 0,
                      Icons.menu_book_outlined,
                    ),
                    _buildFolderChip(
                      'Programs',
                      analytics.folderCounts['programs'] ?? 0,
                      Icons.school_outlined,
                    ),
                    _buildFolderChip(
                      'Gallery',
                      analytics.folderCounts['gallery'] ?? 0,
                      Icons.photo_library_outlined,
                    ),
                    _buildFolderChip(
                      'General',
                      analytics.folderCounts['general'] ?? 0,
                      Icons.folder_outlined,
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFolderChip(String folder, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softGrayBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            folder,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to read media library: $errorMessage',
              style: AppTypography.bodySmall(color: AppColors.errorRed),
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

