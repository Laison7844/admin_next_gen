import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/media_item.dart';
import '../../providers/media_provider.dart';

/// Reusable dialog allowing administrators to select an existing image from the Media Library
/// or upload a new one directly while editing content across the CMS.
class MediaPickerDialog extends ConsumerStatefulWidget {
  final String? initialSelectedUrl;
  final String preferredFolder;

  const MediaPickerDialog({
    super.key,
    this.initialSelectedUrl,
    this.preferredFolder = 'general',
  });

  /// Static helper to show the dialog and return the selected [MediaItem].
  static Future<MediaItem?> show(
    BuildContext context, {
    String? initialSelectedUrl,
    String preferredFolder = 'general',
  }) {
    return showDialog<MediaItem>(
      context: context,
      builder: (ctx) => MediaPickerDialog(
        initialSelectedUrl: initialSelectedUrl,
        preferredFolder: preferredFolder,
      ),
    );
  }

  @override
  ConsumerState<MediaPickerDialog> createState() => _MediaPickerDialogState();
}

class _MediaPickerDialogState extends ConsumerState<MediaPickerDialog> {
  String _selectedFolder = 'all';
  String _searchQuery = '';
  MediaItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    if (widget.preferredFolder != 'general' &&
        MediaValidation.folders.contains(widget.preferredFolder)) {
      _selectedFolder = widget.preferredFolder;
    }
  }

  Future<void> _handleUpload() async {
    final controller = ref.read(mediaOperationControllerProvider.notifier);
    final targetFolder =
        _selectedFolder == 'all' ? widget.preferredFolder : _selectedFolder;
    final uploaded = await controller.uploadImage(folder: targetFolder);

    if (uploaded != null && mounted) {
      setState(() {
        _selectedItem = uploaded;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded "${uploaded.originalName}" successfully!'),
          backgroundColor: AppColors.primaryNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaListProvider);
    final opState = ref.watch(mediaOperationControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 720),
        child: Column(
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
                  const Icon(Icons.photo_library_outlined,
                      color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Image from Media Library',
                          style: AppTypography.headingSmall(
                            color: AppColors.surfaceWhite,
                          ).copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose an existing asset or upload a new image to reuse.',
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

            // Toolbar: Search + Folder Chips + Upload Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: LayoutBuilder(
                builder: (context, toolbarConstraints) {
                  final isMobile = toolbarConstraints.maxWidth < 540;

                  final searchField = TextField(
                    decoration: InputDecoration(
                      hintText: 'Search images by filename...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  );

                  final uploadButton = ElevatedButton.icon(
                    icon: opState.isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryNavy,
                            ),
                          )
                        : const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      opState.isUploading
                          ? 'Uploading ${(opState.uploadProgress * 100).toInt()}%'
                          : 'Upload New',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: opState.isUploading ? null : _handleUpload,
                  );

                  return Column(
                    children: [
                      if (isMobile) ...[
                        searchField,
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: uploadButton,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 12),
                            uploadButton,
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Folder Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                      children: [
                        const Text(
                          'Folder:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (final f in [
                          'all',
                          ...MediaValidation.folders,
                        ]) ...[
                          ChoiceChip(
                            label: Text(f.toUpperCase()),
                            selected: _selectedFolder == f,
                            onSelected: (_) =>
                                setState(() => _selectedFolder = f),
                            selectedColor: AppColors.primaryNavy,
                            labelStyle: TextStyle(
                              color: _selectedFolder == f
                                  ? AppColors.surfaceWhite
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

            // Content Area
            Expanded(
              child: mediaAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Failed to load media: $err'),
                ),
                data: (items) {
                  final query = _searchQuery.trim().toLowerCase();
                  final filtered = items.where((item) {
                    if (_selectedFolder != 'all' &&
                        item.folder.toLowerCase() != _selectedFolder) {
                      return false;
                    }
                    if (query.isNotEmpty) {
                      final m1 = item.name.toLowerCase().contains(query);
                      final m2 =
                          item.originalName.toLowerCase().contains(query);
                      if (!m1 && !m2) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            items.isEmpty
                                ? 'No images uploaded yet'
                                : 'No images match the selected filter',
                            style: AppTypography.headingSmall().copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            items.isEmpty
                                ? 'Click "Upload New" above to add an image.'
                                : 'Try changing folder or clearing search query.',
                            style: AppTypography.bodySmall(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = _selectedItem?.fullPath == item.fullPath ||
                          (widget.initialSelectedUrl != null &&
                              widget.initialSelectedUrl == item.downloadUrl);

                      return InkWell(
                        onTap: () => setState(() => _selectedItem = item),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : AppColors.borderLight,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryGold
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      item.downloadUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Center(
                                        child: Icon(Icons.broken_image,
                                            color: AppColors.textSecondary),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryGold,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.originalName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.formattedSize} • ${item.folder}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  if (_selectedItem != null)
                    Expanded(
                      child: Text(
                        'Selected: ${_selectedItem!.originalName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Text(
                        'Click an image above to select it.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.surfaceWhite,
                    ),
                    onPressed: _selectedItem == null
                        ? null
                        : () => Navigator.of(context).pop(_selectedItem),
                    child: const Text('Select Image'),
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
