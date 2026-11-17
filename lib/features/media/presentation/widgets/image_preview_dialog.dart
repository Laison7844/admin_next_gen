import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/media_item.dart';

/// Modal dialog providing enlarged preview and detailed metadata for a [MediaItem].
class ImagePreviewDialog extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onDelete;

  const ImagePreviewDialog({
    super.key,
    required this.item,
    this.onDelete,
  });

  void _handleCopyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: item.downloadUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image download URL copied to clipboard!'),
        backgroundColor: AppColors.primaryNavy,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined,
                      color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.originalName.isNotEmpty
                          ? item.originalName
                          : item.name,
                      style: AppTypography.headingSmall(
                        color: AppColors.surfaceWhite,
                      ).copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // High-res Image Preview
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            item.downloadUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (ctx, err, stack) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Failed to load image preview',
                                    style: AppTypography.bodySmall(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.folder.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metadata Section
                    Text(
                      'Asset Information',
                      style: AppTypography.headingSmall().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    _buildMetaTile('Original Filename', item.originalName),
                    _buildMetaTile('Storage Filename', item.name),
                    _buildMetaTile('Storage Path', item.fullPath),
                    _buildMetaTile('File Size', item.formattedSize),
                    _buildMetaTile('Content Type', item.contentType),
                    _buildMetaTile('Uploaded Date', item.formattedDate),
                    _buildMetaTile(
                      'Uploaded By (Admin UID)',
                      item.uploadedBy ?? 'Verified Administrator',
                    ),
                    const SizedBox(height: 12),

                    // Direct Download URL Field
                    Text(
                      'Download URL',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.downloadUrl,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy URL',
                            color: AppColors.primaryNavy,
                            onPressed: () => _handleCopyUrl(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
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
                  if (onDelete != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      onPressed: onDelete,
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy URL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.primaryNavy,
                    ),
                    onPressed: () => _handleCopyUrl(context),
                  ),
                  const SizedBox(width: 10),
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

  Widget _buildMetaTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
