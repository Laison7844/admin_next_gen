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
        title: const Text('Publish Item to Website?'),
        content: Text(
          'This will publish "${item.title}" to the live website.',
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
            child: const Text('Publish to Website'),
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
          content: Text('"${item.title}" is now published to the website!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handleUnpublish(CmsContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item from Website?'),
        content: Text(
          'This will remove "${item.title}" from the public website while keeping your unpublished changes intact.',
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
            child: const Text('Remove from Website'),
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
          content: Text('"${item.title}" removed from the website.'),
          backgroundColor: AppColors.mediumNavy,
        ),
      );
    }
  }

  Future<void> _handleDelete(CmsContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content?'),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This permanently removes the content from the website and CMS.',
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
            child: const Text('Delete Content'),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;

            final searchField = TextField(
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
            );

            final addButton = ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add New ${widget.section.title} Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: AppColors.surfaceWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: opState.isLoading ? null : _openCreateDialog,
            );

            return Container(
              padding: const EdgeInsets.all(16),
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
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        addButton,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 14),
                        addButton,
                      ],
                    ),
            );
          },
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
      padding: const EdgeInsets.all(40),
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
            'No ${widget.section.title.toLowerCase()} added yet',
            style: AppTypography.headingSmall(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first ${widget.section.title.toLowerCase()} or load the suggested starting content.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final orderAvatar = CircleAvatar(
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
        );

        final detailsColumn = Column(
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
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PublishStatusBadge(
                  status: item.publishStatus,
                  hasUnpublishedChanges: item.hasUnpublishedChanges,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
          ],
        );

        final actionButtons = Wrap(
          spacing: 2,
          runSpacing: 2,
          alignment: WrapAlignment.end,
          children: [
            IconButton(
              tooltip: 'Preview',
              icon: const Icon(Icons.visibility_outlined, size: 20),
              color: AppColors.primaryNavy,
              onPressed: () => _handlePreview(item),
            ),
            IconButton(
              tooltip: 'Edit Content',
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.primaryNavy,
              onPressed: () => _openEditDialog(item),
            ),
            IconButton(
              tooltip: 'Publish to Website',
              icon: const Icon(Icons.cloud_upload_outlined, size: 20),
              color: AppColors.primaryGold,
              onPressed:
                  opState.isLoading ? null : () => _handlePublish(item),
            ),
            if (item.publishStatus == PublishStatus.published)
              IconButton(
                tooltip: 'Remove from Website',
                icon: const Icon(Icons.cloud_off_outlined, size: 20),
                color: AppColors.errorRed,
                onPressed:
                    opState.isLoading ? null : () => _handleUnpublish(item),
              ),
            IconButton(
              tooltip: 'Delete Content',
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.errorRed,
              onPressed:
                  opState.isLoading ? null : () => _handleDelete(item),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        orderAvatar,
                        const SizedBox(width: 12),
                        Expanded(child: detailsColumn),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: actionButtons,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    orderAvatar,
                    const SizedBox(width: 14),
                    Expanded(child: detailsColumn),
                    const SizedBox(width: 8),
                    actionButtons,
                  ],
                ),
        );
      },
    );
  }
}
