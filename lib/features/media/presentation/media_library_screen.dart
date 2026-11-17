import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'widgets/image_preview_dialog.dart';
import 'widgets/media_delete_dialog.dart';

/// Full-featured Media Library screen allowing administrators to upload, browse,
/// inspect, copy URLs, and manage assets in Firebase Storage.
class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  bool _isGridView = true;
  bool _sortNewestFirst = true;
  final String _uploadTargetFolder = 'general';

  void _openPreview(MediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ImagePreviewDialog(
        item: item,
        onDelete: () {
          Navigator.of(ctx).pop();
          _handleDelete(item);
        },
      ),
    );
  }

  void _copyUrl(MediaItem item) {
    Clipboard.setData(ClipboardData(text: item.downloadUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied URL for "${item.originalName}" to clipboard'),
        backgroundColor: AppColors.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleUpload() async {
    // Show folder selection sheet/dialog if needed, or upload directly to current active folder
    final currentFolder = ref.read(mediaFolderFilterProvider);
    final targetFolder = currentFolder == 'all' ? _uploadTargetFolder : currentFolder;

    final controller = ref.read(mediaOperationControllerProvider.notifier);
    final uploaded = await controller.uploadImage(folder: targetFolder);

    if (uploaded != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully uploaded "${uploaded.originalName}" to $targetFolder!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handleDelete(MediaItem item) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MediaDeleteDialog(item: item),
    );

    if (deleted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image permanently deleted from Storage.'),
          backgroundColor: AppColors.mediumNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaListProvider);
    final selectedFolder = ref.watch(mediaFolderFilterProvider);
    final searchQuery = ref.watch(mediaSearchQueryProvider);
    final opState = ref.watch(mediaOperationControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final padding = isDesktop ? 32.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: isDesktop ? 28.0 : 20.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isDesktop, opState),
                    const SizedBox(height: 16),
                    if (opState.isUploading) _buildUploadProgressBanner(opState),
                    if (opState.errorMessage != null)
                      _buildErrorBanner(opState.errorMessage!),
                    const SizedBox(height: 16),
                    mediaAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => _buildErrorCard(err),
                      data: (items) => _buildContent(
                        allItems: items,
                        selectedFolder: selectedFolder,
                        searchQuery: searchQuery,
                        isDesktop: isDesktop,
                        opState: opState,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, MediaOperationState opState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final uploadButton = ElevatedButton.icon(
          icon: opState.isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryNavy,
                  ),
                )
              : const Icon(Icons.cloud_upload_outlined, size: 20),
          label: Text(
            opState.isUploading
                ? 'Uploading ${(opState.uploadProgress * 100).toInt()}%'
                : 'Upload Image',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGold,
            foregroundColor: AppColors.primaryNavy,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: opState.isUploading ? null : _handleUpload,
        );

        final refreshButton = IconButton.filledTonal(
          tooltip: 'Refresh Media',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () {
            ref.read(mediaOperationControllerProvider.notifier).refresh();
          },
        );

        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.primaryGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Media Library',
                                style: AppTypography.headingSmall()
                                    .copyWith(fontSize: 18),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Asset Library',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload, browse, inspect, and reuse media assets.',
                            style: AppTypography.bodySmall(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    refreshButton,
                  ],
                ),
                const SizedBox(height: 14),
                uploadButton,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Media Library',
                          style: AppTypography.headingMedium()
                              .copyWith(fontSize: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Asset Library',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload, browse, inspect, and reuse media assets across all website CMS modules.',
                      style: AppTypography.bodyMedium(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              refreshButton,
              const SizedBox(width: 12),
              uploadButton,
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadProgressBanner(MediaOperationState opState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softBlueBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, color: AppColors.infoBlue, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Uploading image...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${(opState.uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.infoBlue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: opState.uploadProgress > 0 ? opState.uploadProgress : null,
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.infoBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.errorRed),
            onPressed: () {
              ref.read(mediaOperationControllerProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.errorRed, size: 40),
          const SizedBox(height: 14),
          Text('Failed to load media assets',
              style: AppTypography.headingSmall(color: AppColors.errorRed)),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Fetch'),
            onPressed: () {
              ref.read(mediaOperationControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required List<MediaItem> allItems,
    required String selectedFolder,
    required String searchQuery,
    required bool isDesktop,
    required MediaOperationState opState,
  }) {
    // Stats calculation
    final totalCount = allItems.length;
    final totalSizeBytes =
        allItems.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final totalSizeMb = (totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final distinctFolders =
        allItems.map((e) => e.folder.toLowerCase()).toSet().length;

    // Filter items
    final query = searchQuery.trim().toLowerCase();
    var filtered = allItems.where((item) {
      if (selectedFolder != 'all' &&
          item.folder.toLowerCase() != selectedFolder) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesOriginal =
            item.originalName.toLowerCase().contains(query);
        if (!matchesName && !matchesOriginal) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort items
    filtered.sort((a, b) {
      final dtA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sortNewestFirst ? dtB.compareTo(dtA) : dtA.compareTo(dtB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Metrics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isMobile = constraints.maxWidth < 500;
            return GridView.count(
              crossAxisCount: isWide ? 4 : (isMobile ? 1 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 2.2 : (isMobile ? 3.4 : 2.0),
              children: [
                _buildMetricCard(
                  title: 'Total Assets',
                  value: '$totalCount',
                  subtitle: 'Stored in library',
                  icon: Icons.image_outlined,
                  iconColor: AppColors.infoBlue,
                  bgColor: AppColors.softBlueBg,
                ),
                _buildMetricCard(
                  title: 'Storage Used',
                  value: '$totalSizeMb MB',
                  subtitle: 'Total compressed size',
                  icon: Icons.cloud_done_outlined,
                  iconColor: AppColors.successGreen,
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildMetricCard(
                  title: 'Folders',
                  value: '$distinctFolders',
                  subtitle: 'Categorized scopes',
                  icon: Icons.folder_outlined,
                  iconColor: AppColors.primaryGold,
                  bgColor: AppColors.softGoldBg,
                ),
                _buildMetricCard(
                  title: 'Max Limit',
                  value: '5 MB',
                  subtitle: 'Per uploaded image',
                  icon: Icons.security_outlined,
                  iconColor: AppColors.accentCyan,
                  bgColor: AppColors.softGrayBg,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Filter and Search Toolbar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060B1B3D),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search + View Toggle Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search images by filename...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      onChanged: (val) {
                        ref.read(mediaSearchQueryProvider.notifier).state = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort Order Button
                  IconButton.outlined(
                    tooltip: _sortNewestFirst
                        ? 'Sorted: Newest First'
                        : 'Sorted: Oldest First',
                    icon: Icon(
                      _sortNewestFirst
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _sortNewestFirst = !_sortNewestFirst);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Grid / List View Toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.grid_view, size: 18),
                        tooltip: 'Grid View',
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_list, size: 18),
                        tooltip: 'List View',
                      ),
                    ],
                    selected: {_isGridView},
                    onSelectionChanged: (set) {
                      setState(() => _isGridView = set.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Folder Filter Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Folder:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final f in [
                    'all',
                    ...MediaValidation.folders,
                  ])
                    ChoiceChip(
                      label: Text(f.toUpperCase()),
                      selected: selectedFolder == f,
                      onSelected: (_) {
                        ref.read(mediaFolderFilterProvider.notifier).state = f;
                      },
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: TextStyle(
                        color: selectedFolder == f
                            ? AppColors.surfaceWhite
                            : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // List / Grid Body
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  allItems.isEmpty
                      ? 'No images uploaded yet'
                      : 'No images match your filter criteria',
                  style: AppTypography.headingSmall(),
                ),
                const SizedBox(height: 6),
                Text(
                  allItems.isEmpty
                      ? 'Click the "Upload Image" button above to add media assets.'
                      : 'Try clearing your search query or selecting "ALL" folders.',
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.bodySmall(color: AppColors.textSecondary),
                ),
                if (allItems.isEmpty) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('Upload Your First Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.primaryNavy,
                    ),
                    onPressed: opState.isUploading ? null : _handleUpload,
                  ),
                ],
              ],
            ),
          )
        else if (_isGridView)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildGridCard(item);
            },
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildListRow(item);
            },
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildGridCard(MediaItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060B1B3D),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: () => _openPreview(item),
                  child: Image.network(
                    item.downloadUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 36, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                // Folder Tag
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.folder.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.originalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedSize,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      item.extension.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                // Card Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Copy Download URL',
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: AppColors.primaryNavy,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _copyUrl(item),
                    ),
                    IconButton(
                      tooltip: 'Inspect Image',
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      color: AppColors.infoBlue,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _openPreview(item),
                    ),
                    IconButton(
                      tooltip: 'Delete Image',
                      icon: const Icon(Icons.delete_outline, size: 16),
                      color: AppColors.errorRed,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _handleDelete(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(MediaItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Thumbnail
          InkWell(
            onTap: () => _openPreview(item),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                item.downloadUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.originalName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softBlueBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.folder.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.infoBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.formattedSize} • ${item.contentType} • ${item.formattedDate}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            tooltip: 'Copy Download URL',
            icon: const Icon(Icons.copy, size: 18),
            color: AppColors.primaryNavy,
            onPressed: () => _copyUrl(item),
          ),
          IconButton(
            tooltip: 'Inspect Image',
            icon: const Icon(Icons.visibility_outlined, size: 18),
            color: AppColors.infoBlue,
            onPressed: () => _openPreview(item),
          ),
          IconButton(
            tooltip: 'Delete Image',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.errorRed,
            onPressed: () => _handleDelete(item),
          ),
        ],
      ),
    );
  }
}
