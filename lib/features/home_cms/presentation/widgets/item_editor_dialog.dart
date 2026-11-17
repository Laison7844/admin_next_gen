import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../content/models/cms_content_item.dart';
import '../../../content/models/content_type.dart';
import '../../../content/models/publish_status.dart';
import '../../../media/presentation/widgets/media_picker_dialog.dart';

class ItemEditorDialog extends StatefulWidget {
  final ContentType contentType;
  final CmsContentItem? existingItem;
  final void Function(CmsContentItem item) onSave;

  const ItemEditorDialog({
    super.key,
    required this.contentType,
    this.existingItem,
    required this.onSave,
  });

  @override
  State<ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<ItemEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _tagController;
  late TextEditingController _descriptionController;
  late TextEditingController _highlightsController;
  late TextEditingController _imageController;
  late TextEditingController _orderController;

  bool _isVisible = true;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    final data = item?.data ?? {};

    _idController = TextEditingController(text: item?.id ?? '');
    _titleController = TextEditingController(text: item?.title ?? '');
    _subtitleController =
        TextEditingController(text: data['subtitle']?.toString() ?? '');
    _tagController = TextEditingController(
      text: (data['tag'] ?? data['category'])?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: (data['description'] ?? data['answer'])?.toString() ?? '',
    );

    final highlightsList = (data['highlights'] as List?)?.cast<String>() ?? [];
    _highlightsController =
        TextEditingController(text: highlightsList.join('\n'));

    _imageController =
        TextEditingController(text: data['image']?.toString() ?? '');
    _orderController =
        TextEditingController(text: (data['order'] ?? 1).toString());

    _isVisible = data['isVisible'] != false;
    _isFeatured = data['isFeatured'] == true;
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _tagController.dispose();
    _descriptionController.dispose();
    _highlightsController.dispose();
    _imageController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final highlights = _highlightsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final order = int.tryParse(_orderController.text.trim()) ?? 1;

    final updatedData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'order': order,
      'isVisible': _isVisible,
    };

    if (widget.contentType == ContentType.courses ||
        widget.contentType == ContentType.programs) {
      updatedData['subtitle'] = _subtitleController.text.trim();
      updatedData['tag'] = _tagController.text.trim();
      updatedData['description'] = _descriptionController.text.trim();
      updatedData['highlights'] = highlights;
      updatedData['isFeatured'] = _isFeatured;
      updatedData['icon'] = widget.existingItem?.data['icon'] ??
          (widget.contentType == ContentType.courses
              ? 'menu_book_rounded'
              : 'school_rounded');
      if (_imageController.text.trim().isNotEmpty) {
        updatedData['image'] = _imageController.text.trim();
      }
    } else if (widget.contentType == ContentType.gallery) {
      updatedData['category'] = _tagController.text.trim();
      updatedData['description'] = _descriptionController.text.trim();
      updatedData['image'] = _imageController.text.trim();
    } else if (widget.contentType == ContentType.faqs) {
      updatedData['category'] = _tagController.text.trim();
      updatedData['question'] = _titleController.text.trim();
      updatedData['answer'] = _descriptionController.text.trim();
    }

    final now = DateTime.now();
    final item = CmsContentItem(
      id: _idController.text.trim().toLowerCase().replaceAll(' ', '_'),
      contentType: widget.contentType.key,
      title: _titleController.text.trim(),
      data: updatedData,
      publishStatus: widget.existingItem?.publishStatus ?? PublishStatus.draft,
      hasUnpublishedChanges: true,
      createdAt: widget.existingItem?.createdAt ?? now,
      updatedAt: now,
      publishedAt: widget.existingItem?.publishedAt,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existingItem == null;
    final typeName = widget.contentType.displayName;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Text(
                    isNew ? 'New $typeName' : 'Edit $typeName',
                    style: AppTypography.headingSmall(
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.surfaceWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Identifier (Editable only for new items)
                      Text('Item Identifier (slug)', style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _idController,
                        enabled: isNew,
                        decoration: const InputDecoration(
                          hintText: 'e.g. course_robotics_101',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a unique item identifier';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.contentType == ContentType.faqs
                            ? 'Question / Title'
                            : 'Title',
                        style: AppTypography.titleMedium(),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter title...',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subtitle (for Courses / Programs)
                      if (widget.contentType == ContentType.courses ||
                          widget.contentType == ContentType.programs) ...[
                        Text('Subtitle / Tagline',
                            style: AppTypography.titleMedium()),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _subtitleController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. All Subjects Tuition',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tag / Category
                      Text('Tag / Category', style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Foundation, Secondary, General',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image URL / asset (for Gallery, Courses, Programs)
                      if (widget.contentType == ContentType.gallery ||
                          widget.contentType == ContentType.courses ||
                          widget.contentType == ContentType.programs) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.contentType == ContentType.gallery
                                    ? 'Image URL or Asset Path *'
                                    : 'Image URL or Asset Path (Optional)',
                                style: AppTypography.titleMedium(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.photo_library_outlined, size: 14),
                              label: const Text('Media Library', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                final folder = widget.contentType == ContentType.gallery
                                    ? 'gallery'
                                    : widget.contentType == ContentType.courses
                                        ? 'courses'
                                        : 'programs';
                                final selected = await MediaPickerDialog.show(
                                  context,
                                  initialSelectedUrl: _imageController.text,
                                  preferredFolder: folder,
                                );
                                if (selected != null) {
                                  setState(() {
                                    _imageController.text = selected.downloadUrl;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _imageController,
                          decoration: InputDecoration(
                            hintText:
                                'https://firebasestorage.googleapis.com/... or assets/images/...',
                            suffixIcon: _imageController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () =>
                                        setState(() => _imageController.clear()),
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description / Answer
                      Text(
                        widget.contentType == ContentType.faqs
                            ? 'Answer'
                            : 'Description',
                        style: AppTypography.titleMedium(),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Enter detailed content...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Highlights (for Courses / Programs)
                      if (widget.contentType == ContentType.courses ||
                          widget.contentType == ContentType.programs) ...[
                        Text(
                          'Key Highlights (One bullet point per line)',
                          style: AppTypography.titleMedium(),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _highlightsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Mathematics & Science\nWeekly review tests\nConcept building',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Order & Switches
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Display Order',
                                    style: AppTypography.titleMedium()),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _orderController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  title: const Text('Visible on Site'),
                                  value: _isVisible,
                                  onChanged: (v) =>
                                      setState(() => _isVisible = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (widget.contentType == ContentType.courses ||
                                    widget.contentType == ContentType.programs)
                                  SwitchListTile(
                                    title: const Text('Featured Card'),
                                    value: _isFeatured,
                                    onChanged: (v) =>
                                        setState(() => _isFeatured = v),
                                    contentPadding: EdgeInsets.zero,
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
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                    ),
                    child: const Text('Save Changes'),
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

