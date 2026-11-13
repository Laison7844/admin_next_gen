import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../content/models/cms_content_item.dart';
import '../../../content/models/content_type.dart';
import '../../../content/models/publish_status.dart';
import '../../../content/providers/content_provider.dart';
import '../../constants/home_default_data.dart';
import '../../models/home_section_definition.dart';
import 'item_editor_dialog.dart';
import 'publish_status_badge.dart';
import 'section_preview_dialog.dart';

class CollectionSectionView extends ConsumerStatefulWidget {
  final HomeSectionDefinition section;

  const CollectionSectionView({
    super.key,
    required this.section,
  });

  @override
  ConsumerState<CollectionSectionView> createState() =>
      _CollectionSectionViewState();
}

class _CollectionSectionViewState extends ConsumerState<CollectionSectionView> {
  String _searchQuery = '';

  List<Map<String, dynamic>> _getDefaultItemsForSection() {
    switch (widget.section.contentType) {
      case ContentType.courses:
        return HomeDefaultData.defaultCourses;
      case ContentType.programs:
        return HomeDefaultData.defaultPrograms;
      case ContentType.gallery:
        return HomeDefaultData.defaultGallery;
      case ContentType.faqs:
        return HomeDefaultData.defaultFaqs;
      default:
        return [];
    }
  }

  Future<void> _seedDefaultItems() async {
    final defaults = _getDefaultItemsForSection();
    if (defaults.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Load Default ${widget.section.title}?'),
        content: Text(
          'This will populate default ${widget.section.title.toLowerCase()} items into your CMS drafts. '
          'Any items that already exist in drafts will be skipped safely without being overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.primaryNavy,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load Defaults'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final service = ref.read(contentServiceProvider);
    final controller = ref.read(contentOperationControllerProvider.notifier);

    // Cost-conscious: 1 single read to fetch existing draft IDs for this content type
    final existingDrafts = await service.getDrafts(
      contentType: widget.section.contentType.key,
    );
    final existingIds = existingDrafts.map((d) => d.id).toSet();

    int created = 0;
    int skipped = 0;

    for (final item in defaults) {
      final id = item['id'] as String;
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }

      final title = (item['title'] ?? item['question'] ?? id) as String;
      final success = await controller.createDraft(
        id: id,
        contentType: widget.section.contentType.key,
        title: title,
        data: item,
      );
      if (success) {
        created++;
        existingIds.add(id);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default data loading complete: $created added, $skipped existing item(s) skipped.',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ItemEditorDialog(
        contentType: widget.section.contentType,
        onSave: (newItem) async {
          final controller =
              ref.read(contentOperationControllerProvider.notifier);
          final success = await controller.createDraft(
            id: newItem.id,
            contentType: widget.section.contentType.key,
            title: newItem.title,
            data: newItem.data,
          );
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Draft "${newItem.title}" created successfully.'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
        },
      ),
    );
  }

  void _openEditDialog(CmsContentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ItemEditorDialog(
        contentType: widget.section.contentType,
        existingItem: item,
        onSave: (updatedItem) async {
          final controller =
              ref.read(contentOperationControllerProvider.notifier);
          final success = await controller.updateDraft(
            id: updatedItem.id,
            title: updatedItem.title,
            data: updatedItem.data,
            contentType: widget.section.contentType.key,
          );
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Draft "${updatedItem.title}" updated successfully.'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _handlePublish(CmsContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Item to Live Website?'),
        content: Text(
          'This will publish "${item.title}" to the live website collection "${widget.section.contentType.publicCollection}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.primaryNavy,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish Live'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = ref.read(contentOperationControllerProvider.notifier);
    final success = await controller.publish(
      draftId: item.id,
      contentType: widget.section.contentType.key,
      expectedUpdatedAt: item.updatedAt,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.title}" is now published and live.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handleUnpublish(CmsContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish Item?'),
        content: Text(
          'This will remove "${item.title}" from the public website while keeping the CMS draft intact.',
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
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = ref.read(contentOperationControllerProvider.notifier);
    final success = await controller.unpublish(
      draftId: item.id,
      contentType: widget.section.contentType.key,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.title}" unpublished from live website.'),
          backgroundColor: AppColors.mediumNavy,
        ),
      );
    }
  }

  Future<void> _handleDelete(CmsContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Item?'),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This permanently removes the draft and any published version.',
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

    if (confirmed != true) return;

    final controller = ref.read(contentOperationControllerProvider.notifier);
    final success = await controller.delete(
      draftId: item.id,
      contentType: widget.section.contentType.key,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.title}" deleted.'),
          backgroundColor: AppColors.mediumNavy,
        ),
      );
    }
  }

  void _handlePreview(CmsContentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => SectionPreviewDialog(
        section: widget.section,
        data: item.data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync =
        ref.watch(contentListProvider(widget.section.contentType.key));
    final opState = ref.watch(contentOperationControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action and Search Bar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080B1B3D),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search ${widget.section.title.toLowerCase()} by title, category, or keywords...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textSecondary),
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
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add New ${widget.section.title} Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: AppColors.surfaceWhite,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: opState.isLoading ? null : _openCreateDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Items List or Empty View
        itemsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(color: AppColors.primaryNavy),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error loading items: $err',
                  style: const TextStyle(color: AppColors.errorRed)),
            ),
          ),
          data: (items) {
            final filteredItems = items.where((it) {
              if (_searchQuery.isEmpty) return true;
              final title = it.title.toLowerCase();
              final desc = (it.data['description'] ?? it.data['answer'] ?? '')
                  .toString()
                  .toLowerCase();
              final tag = (it.data['tag'] ?? it.data['category'] ?? '')
                  .toString()
                  .toLowerCase();
              return title.contains(_searchQuery) ||
                  desc.contains(_searchQuery) ||
                  tag.contains(_searchQuery);
            }).toList();

            // Sort by order ascending
            filteredItems.sort((a, b) {
              final orderA = (a.data['order'] as num?)?.toInt() ?? 999;
              final orderB = (b.data['order'] as num?)?.toInt() ?? 999;
              return orderA.compareTo(orderB);
            });

            if (items.isEmpty) {
              return _buildEmptyState();
            }

            if (filteredItems.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    'No items match your search "$_searchQuery"',
                    style: AppTypography.bodyMedium(),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final item = filteredItems[index];
                return _buildItemCard(item, opState);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.section.icon, size: 54, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No ${widget.section.title} items found in drafts',
            style: AppTypography.headingSmall(),
          ),
          const SizedBox(height: 8),
          Text(
            'You can load the initial website items or create a new one from scratch.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Load Default Website Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.primaryNavy),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: _seedDefaultItems,
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create New Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.primaryNavy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: _openCreateDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(CmsContentItem item, ContentOperationState opState) {
    final order = (item.data['order'] as num?)?.toInt() ?? 1;
    final isVisible = item.data['isVisible'] != false;
    final tag = (item.data['tag'] ?? item.data['category'])?.toString();
    final subtitle = item.data['subtitle']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060B1B3D),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Order chip
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.backgroundLight,
            child: Text(
              '$order',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Main details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        style:
                            AppTypography.headingSmall().copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (tag != null && tag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(
                        color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    PublishStatusBadge(
                      status: item.publishStatus,
                      hasUnpublishedChanges: item.hasUnpublishedChanges,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 14,
                      color: isVisible
                          ? AppColors.successGreen
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVisible ? 'Visible' : 'Hidden',
                      style: TextStyle(
                        fontSize: 12,
                        color: isVisible
                            ? AppColors.successGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          IconButton(
            tooltip: 'Preview',
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: AppColors.primaryNavy,
            onPressed: () => _handlePreview(item),
          ),
          IconButton(
            tooltip: 'Edit Draft',
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.primaryNavy,
            onPressed: () => _openEditDialog(item),
          ),
          IconButton(
            tooltip: 'Publish Live',
            icon: const Icon(Icons.cloud_upload_outlined, size: 20),
            color: AppColors.primaryGold,
            onPressed:
                opState.isLoading ? null : () => _handlePublish(item),
          ),
          if (item.publishStatus == PublishStatus.published)
            IconButton(
              tooltip: 'Unpublish',
              icon: const Icon(Icons.cloud_off_outlined, size: 20),
              color: AppColors.errorRed,
              onPressed:
                  opState.isLoading ? null : () => _handleUnpublish(item),
            ),
          IconButton(
            tooltip: 'Delete Permanently',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.errorRed,
            onPressed:
                opState.isLoading ? null : () => _handleDelete(item),
          ),
        ],
      ),
    );
  }
}
