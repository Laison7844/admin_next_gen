import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/media_reference_repository.dart';
import '../../models/media_item.dart';
import '../../models/media_reference.dart';
import '../../providers/media_provider.dart';

/// Modal dialog providing safe media deletion protection.
/// Verifies whether a media asset is referenced by published content or CMS drafts
/// and permanently blocks deletion if references are detected or if checking fails.
class MediaDeleteDialog extends ConsumerStatefulWidget {
  final MediaItem item;

  const MediaDeleteDialog({
    super.key,
    required this.item,
  });

  /// Static helper to display the dialog and return whether the asset was deleted.
  static Future<bool> show(BuildContext context, MediaItem item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MediaDeleteDialog(item: item),
    );
    return result == true;
  }

  @override
  ConsumerState<MediaDeleteDialog> createState() => _MediaDeleteDialogState();
}

class _MediaDeleteDialogState extends ConsumerState<MediaDeleteDialog> {
  bool _isChecking = true;
  bool _isDeleting = false;
  String? _statusMessage;
  String? _errorMessage;
  MediaReferenceCheckResult? _checkResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialCheck();
    });
  }

  Future<void> _runInitialCheck() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _statusMessage = 'Checking references across published content and CMS drafts...';
    });

    try {
      final repository = ref.read(mediaReferenceRepositoryProvider);
      final result = await repository.checkReferences(widget.item);

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _checkResult = result;
        if (result.hasError) {
          _errorMessage = result.errorMessage;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _errorMessage = 'Failed to inspect references: $e';
      });
    }
  }

  Future<void> _handleConfirmDelete() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
      _statusMessage = 'Running pre-deletion safety recheck...';
    });

    try {
      final repository = ref.read(mediaReferenceRepositoryProvider);

      // Step 8: Recheck references immediately before deletion to eliminate race conditions
      final recheck = await repository.checkReferences(widget.item);

      if (!mounted) return;

      if (recheck.hasError) {
        setState(() {
          _isDeleting = false;
          _errorMessage =
              'Pre-deletion verification failed: ${recheck.errorMessage}. Deletion aborted.';
        });
        return;
      }

      if (recheck.isReferenced) {
        setState(() {
          _isDeleting = false;
          _checkResult = recheck;
          _errorMessage =
              'A reference was added during verification! Deletion has been blocked.';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Deleting image...';
      });

      final controller = ref.read(mediaOperationControllerProvider.notifier);
      final success = await controller.deleteMedia(
        widget.item,
        skipReferenceCheck: true, // Already verified twice above
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        final opState = ref.read(mediaOperationControllerProvider);
        setState(() {
          _isDeleting = false;
          _errorMessage = opState.errorMessage ?? 'Failed to delete image.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = 'Unexpected deletion error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final check = _checkResult;
    final isReferenced = check != null && check.isReferenced;
    final hasError = _errorMessage != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isReferenced ? AppColors.errorRed : AppColors.primaryNavy,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    isReferenced
                        ? Icons.warning_rounded
                        : Icons.delete_outline_rounded,
                    color: isReferenced
                        ? AppColors.surfaceWhite
                        : AppColors.primaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Permanently Delete Image?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surfaceWhite,
                      ),
                    ),
                  ),
                  if (!_isDeleting)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                ],
              ),
            ),

            // Modal Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Loading State
                    if (_isChecking || _isDeleting) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      Text(
                        _statusMessage ?? 'Processing...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Error Banner
                    if (hasError && !_isChecking && !_isDeleting) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withAlpha(20),
                          border: Border.all(color: AppColors.errorRed.withAlpha(80)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.errorRed, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // In-Use / Referenced Banner
                    if (isReferenced && !_isChecking && !_isDeleting) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'IN USE (${check.referenceCount} ${check.referenceCount == 1 ? "reference" : "references"})',
                                    style: const TextStyle(
                                      color: AppColors.surfaceWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Permanent Deletion Blocked',
                                    style: TextStyle(
                                      color: AppColors.errorRed,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'This image cannot be deleted because it is currently referenced by published website content or CMS drafts. '
                              'Deleting this file would cause broken images on the live website.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF991B1B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Please remove or replace this image in the content items below before deleting the asset:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7F1D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Affected Content List
                      const Text(
                        'Referenced in Content:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.backgroundLight,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: check.references.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 8),
                          itemBuilder: (ctx, index) {
                            final refItem = check.references[index];
                            return _buildReferenceTile(refItem);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Unreferenced / Safe Banner
                    if (!isReferenced && !_isChecking && !_isDeleting && !hasError) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: AppColors.successGreen, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No references found. This image is safe to delete.',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Are you sure you want to permanently delete "${widget.item.originalName}"?\n\n'
                        'Path: ${widget.item.fullPath}\n\n'
                        'This action cannot be undone. Any published website sections pointing to this image will no longer be able to load it.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Modal Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(isReferenced ? 'Close' : 'Cancel'),
                  ),
                  if (hasError && !isReferenced) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Check'),
                      onPressed: _isChecking || _isDeleting ? null : _runInitialCheck,
                    ),
                  ],
                  if (!isReferenced && !hasError) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: AppColors.surfaceWhite,
                      ),
                      onPressed:
                          _isChecking || _isDeleting ? null : _handleConfirmDelete,
                      child: const Text('Delete Permanently'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceTile(MediaReference refItem) {
    final isDraft = refItem.isDraft;
    final badgeColor = isDraft ? AppColors.primaryGold : AppColors.primaryNavy;
    final badgeText = isDraft ? 'CMS DRAFT' : 'PUBLISHED';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDraft ? AppColors.primaryNavy : AppColors.surfaceWhite,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${refItem.contentType.toUpperCase()}: ${refItem.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Document: ${refItem.documentId} • Field: ${refItem.fieldPaths.join(', ')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
