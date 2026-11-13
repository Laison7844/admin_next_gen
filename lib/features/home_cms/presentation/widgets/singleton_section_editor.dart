import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../content/models/cms_content_item.dart';
import '../../../content/models/publish_status.dart';
import '../../../content/providers/content_provider.dart';
import '../../models/home_section_definition.dart';
import 'publish_status_badge.dart';
import 'section_preview_dialog.dart';

class SingletonSectionEditor extends ConsumerStatefulWidget {
  final HomeSectionDefinition section;

  const SingletonSectionEditor({
    super.key,
    required this.section,
  });

  @override
  ConsumerState<SingletonSectionEditor> createState() =>
      _SingletonSectionEditorState();
}

class _SingletonSectionEditorState
    extends ConsumerState<SingletonSectionEditor> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  bool _isDirty = false;
  String? _loadedDraftId;

  @override
  void didUpdateWidget(covariant SingletonSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) {
      _loadedDraftId = null;
      _isDirty = false;
    }
  }

  void _initializeFormData(CmsContentItem? draft) {
    if (_loadedDraftId == widget.section.id && _isDirty) return;
    _loadedDraftId = widget.section.id;
    _formData = Map<String, dynamic>.from(
      draft?.data ?? widget.section.defaultSingletonData,
    );
    _isDirty = false;
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _handleSaveDraft(CmsContentItem? draft) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final controller = ref.read(contentOperationControllerProvider.notifier);
    final success = await controller.saveDraft(
      id: widget.section.id,
      contentType: widget.section.contentType.key,
      title: widget.section.title,
      data: _formData,
    );

    if (mounted && success) {
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.section.title} draft saved successfully.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handlePublish(CmsContentItem? draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Section to Live Website?'),
        content: Text(
          'This will update the public "${widget.section.title}" on next-gen-excellence.web.app immediately.',
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
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_isDirty || draft == null) {
      await _handleSaveDraft(draft);
    }

    final controller = ref.read(contentOperationControllerProvider.notifier);
    final success = await controller.publish(
      draftId: widget.section.id,
      contentType: widget.section.contentType.key,
      expectedUpdatedAt: draft?.updatedAt,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.section.title} is now live on the website!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handleUnpublish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish Section?'),
        content: Text(
          'This will remove "${widget.section.title}" from the public website while retaining your CMS draft.',
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
      draftId: widget.section.id,
      contentType: widget.section.contentType.key,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.section.title} has been unpublished.'),
          backgroundColor: AppColors.mediumNavy,
        ),
      );
    }
  }

  void _handlePreview() {
    _formKey.currentState?.save();
    showDialog(
      context: context,
      builder: (ctx) => SectionPreviewDialog(
        section: widget.section,
        data: _formData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(contentItemProvider(widget.section.id));
    final opState = ref.watch(contentOperationControllerProvider);

    return draftAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(color: AppColors.primaryNavy),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error loading draft: $err',
              style: const TextStyle(color: AppColors.errorRed)),
        ),
      ),
      data: (draft) {
        _initializeFormData(draft);
        final status = draft?.publishStatus ?? PublishStatus.draft;
        final hasUnpublished = draft?.hasUnpublishedChanges ?? true;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action / Status Bar
              _buildTopStatusBar(status, hasUnpublished, draft, opState),
              const SizedBox(height: 20),

              // Section Editor Fields
              _buildEditorFields(),
              const SizedBox(height: 28),

              // Bottom Action Controls
              _buildBottomActionButtons(draft, opState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatusBar(
    PublishStatus status,
    bool hasUnpublished,
    CmsContentItem? draft,
    ContentOperationState opState,
  ) {
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
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PublishStatusBadge(
                status: status,
                hasUnpublishedChanges: _isDirty || hasUnpublished,
              ),
              if (_isDirty) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: const Text(
                    'Unsaved edits in form',
                    style: TextStyle(
                      color: Color(0xFF856404),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.preview_outlined, size: 18),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                onPressed: _handlePreview,
              ),
              ElevatedButton.icon(
                icon: opState.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surfaceWhite,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: AppColors.surfaceWhite,
                ),
                onPressed:
                    opState.isLoading ? null : () => _handleSaveDraft(draft),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Publish Live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.primaryNavy,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed:
                    opState.isLoading ? null : () => _handlePublish(draft),
              ),
              if (status == PublishStatus.published)
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_off_outlined,
                      size: 18, color: AppColors.errorRed),
                  label: const Text('Unpublish',
                      style: TextStyle(color: AppColors.errorRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorRed),
                  ),
                  onPressed: opState.isLoading ? null : _handleUnpublish,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(
    CmsContentItem? draft,
    ContentOperationState opState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _handlePreview,
            child: const Text('Preview Changes'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: AppColors.surfaceWhite,
            ),
            onPressed: opState.isLoading ? null : () => _handleSaveDraft(draft),
            child: const Text('Save Draft'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.primaryNavy,
            ),
            onPressed: opState.isLoading ? null : () => _handlePublish(draft),
            child: const Text('Publish to Website'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorFields() {
    switch (widget.section.id) {
      case 'home_hero':
        return _buildHeroEditor();
      case 'feature_highlights':
        return _buildFeatureHighlightsEditor();
      case 'about_us':
        return _buildAboutEditor();
      case 'why_nextgen':
        return _buildWhyNextGenEditor();
      case 'learning_modes':
        return _buildLearningModesEditor();
      case 'pledge':
        return _buildPledgeEditor();
      case 'assessments':
        return _buildAssessmentsEditor();
      case 'banner_cta':
        return _buildBannerCtaEditor();
      case 'contact_footer':
        return _buildContactFooterEditor();
      default:
        return _buildGenericEditor();
    }
  }

  // 1. HERO EDITOR
  Widget _buildHeroEditor() {
    return _cardContainer(
      title: 'Hero Section Settings',
      children: [
        _textInput(
          label: 'Subtitle / Badge Text',
          initialValue: _formData['subtitle']?.toString() ?? '',
          onSaved: (val) => _formData['subtitle'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Main Heading',
          initialValue: _formData['mainTitle']?.toString() ?? '',
          onSaved: (val) => _formData['mainTitle'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Highlighted Heading (Gold Accent)',
          initialValue: _formData['highlightedTitle']?.toString() ?? '',
          onSaved: (val) => _formData['highlightedTitle'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Hero Description',
          initialValue: _formData['description']?.toString() ?? '',
          maxLines: 3,
          onSaved: (val) => _formData['description'] = val,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _textInput(
                label: 'Primary Button Label',
                initialValue: _formData['primaryButtonLabel']?.toString() ?? '',
                onSaved: (val) => _formData['primaryButtonLabel'] = val,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textInput(
                label: 'Secondary Button Label',
                initialValue:
                    _formData['secondaryButtonLabel']?.toString() ?? '',
                onSaved: (val) => _formData['secondaryButtonLabel'] = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Feature Chips (Comma-separated)',
          initialValue:
              ((_formData['featureChips'] as List?)?.join(', ')) ?? '',
          onSaved: (val) {
            _formData['featureChips'] = (val ?? '')
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          },
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Hero Illustration / Image URL',
          initialValue: _formData['heroImage']?.toString() ?? '',
          onSaved: (val) => _formData['heroImage'] = val,
        ),
      ],
    );
  }

  // 2. FEATURE HIGHLIGHTS EDITOR
  Widget _buildFeatureHighlightsEditor() {
    final features = List<Map<String, dynamic>>.from(
      (_formData['features'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ??
          [],
    );

    return _cardContainer(
      title: 'Feature Highlights (6 Pillars)',
      children: [
        for (int i = 0; i < features.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryNavy,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: features[i]['title']?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Highlight Title',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          features[i]['title'] = val;
                          _formData['features'] = features;
                          _markDirty();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: features[i]['isVisible'] != false,
                      activeThumbColor: AppColors.primaryGold,
                      onChanged: (val) {
                        setState(() {
                          features[i]['isVisible'] = val;
                          _formData['features'] = features;
                          _markDirty();
                        });
                      },
                    ),
                    const Text('Visible', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: features[i]['description']?.toString() ?? '',
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    features[i]['description'] = val;
                    _formData['features'] = features;
                    _markDirty();
                  },
                ),
              ],
            ),
          ),
        ],
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Feature Highlight'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: AppColors.surfaceWhite,
          ),
          onPressed: () {
            setState(() {
              features.add({
                'title': 'New Feature Highlight',
                'description': 'Description of feature highlight.',
                'icon': 'verified_outlined',
                'order': features.length + 1,
                'isVisible': true,
              });
              _formData['features'] = features;
              _markDirty();
            });
          },
        ),
      ],
    );
  }

  // 3. ABOUT EDITOR
  Widget _buildAboutEditor() {
    final pillars = List<Map<String, dynamic>>.from(
      (_formData['pillars'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ??
          [],
    );

    return _cardContainer(
      title: 'About Us Section Settings',
      children: [
        _textInput(
          label: 'Category Tag',
          initialValue: _formData['category']?.toString() ?? '',
          onSaved: (val) => _formData['category'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Section Heading',
          initialValue: _formData['title']?.toString() ?? '',
          onSaved: (val) => _formData['title'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Academy Story / Description',
          initialValue: _formData['description']?.toString() ?? '',
          maxLines: 4,
          onSaved: (val) => _formData['description'] = val,
        ),
        const SizedBox(height: 24),
        Text('The Four Pillars', style: AppTypography.headingSmall()),
        const SizedBox(height: 12),
        for (int i = 0; i < pillars.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryGold,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: pillars[i]['title']?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Pillar Title',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          pillars[i]['title'] = val;
                          _formData['pillars'] = pillars;
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            pillars[i]['description']?.toString() ?? '',
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Pillar Description',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          pillars[i]['description'] = val;
                          _formData['pillars'] = pillars;
                          _markDirty();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 4. WHY NEXTGEN EDITOR
  Widget _buildWhyNextGenEditor() {
    final reasons = List<Map<String, dynamic>>.from(
      (_formData['reasons'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ??
          [],
    );

    return _cardContainer(
      title: 'Why NextGen Section Settings',
      children: [
        _textInput(
          label: 'Section Heading',
          initialValue: _formData['title']?.toString() ?? '',
          onSaved: (val) => _formData['title'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Subtitle',
          initialValue: _formData['subtitle']?.toString() ?? '',
          onSaved: (val) => _formData['subtitle'] = val,
        ),
        const SizedBox(height: 24),
        Text('Core Differentiators', style: AppTypography.headingSmall()),
        const SizedBox(height: 12),
        for (int i = 0; i < reasons.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: reasons[i]['title']?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: 'Reason #${i + 1} Title',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          reasons[i]['title'] = val;
                          _formData['reasons'] = reasons;
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            reasons[i]['description']?.toString() ?? '',
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          reasons[i]['description'] = val;
                          _formData['reasons'] = reasons;
                          _markDirty();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 5. LEARNING MODES EDITOR
  Widget _buildLearningModesEditor() {
    final modes = List<Map<String, dynamic>>.from(
      (_formData['modes'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ??
          [],
    );

    return _cardContainer(
      title: 'Learning Modes Settings',
      children: [
        _textInput(
          label: 'Section Heading',
          initialValue: _formData['title']?.toString() ?? '',
          onSaved: (val) => _formData['title'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Section Subtitle',
          initialValue: _formData['subtitle']?.toString() ?? '',
          onSaved: (val) => _formData['subtitle'] = val,
        ),
        const SizedBox(height: 24),
        Text('Available Learning Delivery Modes',
            style: AppTypography.headingSmall()),
        const SizedBox(height: 12),
        for (int i = 0; i < modes.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: modes[i]['title']?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Mode Title',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          modes[i]['title'] = val;
                          _formData['modes'] = modes;
                          _markDirty();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: modes[i]['badge']?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Badge Tag (e.g. In-Person / Interactive)',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          modes[i]['badge'] = val;
                          _formData['modes'] = modes;
                          _markDirty();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: modes[i]['description']?.toString() ?? '',
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mode Description',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    modes[i]['description'] = val;
                    _formData['modes'] = modes;
                    _markDirty();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: modes[i]['image']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Mode Asset / Image URL',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    modes[i]['image'] = val;
                    _formData['modes'] = modes;
                    _markDirty();
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 6. PLEDGE EDITOR
  Widget _buildPledgeEditor() {
    return _cardContainer(
      title: 'NextGen Academy Pledge',
      children: [
        _textInput(
          label: 'Category Tag',
          initialValue: _formData['category']?.toString() ?? '',
          onSaved: (val) => _formData['category'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Pledge Heading',
          initialValue: _formData['title']?.toString() ?? '',
          onSaved: (val) => _formData['title'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Pledge Subtitle / Mission Text',
          initialValue: _formData['subtitle']?.toString() ?? '',
          maxLines: 3,
          onSaved: (val) => _formData['subtitle'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Pledge Document / Certificate Image Asset URL',
          initialValue: _formData['pledgeDocumentImage']?.toString() ?? '',
          onSaved: (val) => _formData['pledgeDocumentImage'] = val,
        ),
      ],
    );
  }

  // 7. ASSESSMENTS EDITOR
  Widget _buildAssessmentsEditor() {
    final cards = List<Map<String, dynamic>>.from(
      (_formData['cards'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ??
          [],
    );

    return _cardContainer(
      title: 'Assessments & Evaluation Cards',
      children: [
        _textInput(
          label: 'Category Tag',
          initialValue: _formData['category']?.toString() ?? '',
          onSaved: (val) => _formData['category'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Section Heading',
          initialValue: _formData['title']?.toString() ?? '',
          onSaved: (val) => _formData['title'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Section Subtitle',
          initialValue: _formData['subtitle']?.toString() ?? '',
          onSaved: (val) => _formData['subtitle'] = val,
        ),
        const SizedBox(height: 24),
        Text('Evaluation System Steps', style: AppTypography.headingSmall()),
        const SizedBox(height: 12),
        for (int i = 0; i < cards.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryNavy,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.surfaceWhite, fontSize: 11)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: cards[i]['title']?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Card Title',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          cards[i]['title'] = val;
                          _formData['cards'] = cards;
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: cards[i]['description']?.toString() ?? '',
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          cards[i]['description'] = val;
                          _formData['cards'] = cards;
                          _markDirty();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 8. BANNER CTA EDITOR
  Widget _buildBannerCtaEditor() {
    return _cardContainer(
      title: 'Call to Action Banner',
      children: [
        _textInput(
          label: 'Main Heading',
          initialValue: _formData['mainHeading']?.toString() ?? '',
          onSaved: (val) => _formData['mainHeading'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Highlighted Heading (Gold Accent)',
          initialValue: _formData['highlightedHeading']?.toString() ?? '',
          onSaved: (val) => _formData['highlightedHeading'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Badges (Comma-separated)',
          initialValue: ((_formData['badges'] as List?)?.join(', ')) ?? '',
          onSaved: (val) {
            _formData['badges'] = (val ?? '')
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          },
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Button Label',
          initialValue: _formData['buttonLabel']?.toString() ?? '',
          onSaved: (val) => _formData['buttonLabel'] = val,
        ),
      ],
    );
  }

  // 9. CONTACT & FOOTER EDITOR
  Widget _buildContactFooterEditor() {
    return _cardContainer(
      title: 'Contact Information & Footer Details',
      children: [
        Row(
          children: [
            Expanded(
              child: _textInput(
                label: 'Official Phone Numbers (Comma-separated)',
                initialValue:
                    ((_formData['phoneNumbers'] as List?)?.join(', ')) ?? '',
                onSaved: (val) {
                  _formData['phoneNumbers'] = (val ?? '')
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textInput(
                label: 'Official Contact Email',
                initialValue: _formData['email']?.toString() ?? '',
                onSaved: (val) => _formData['email'] = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Campus Physical Address',
          initialValue: _formData['address']?.toString() ?? '',
          maxLines: 2,
          onSaved: (val) => _formData['address'] = val,
        ),
        const SizedBox(height: 16),
        _textInput(
          label: 'Brand Footer Description',
          initialValue: _formData['brandDescription']?.toString() ?? '',
          maxLines: 3,
          onSaved: (val) => _formData['brandDescription'] = val,
        ),
        const SizedBox(height: 24),
        Text('Social Media Links', style: AppTypography.headingSmall()),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _textInput(
                label: 'Facebook Link',
                initialValue:
                    _formData['socialLinks']?['facebook']?.toString() ?? '',
                onSaved: (val) {
                  _formData['socialLinks'] = {
                    ...(_formData['socialLinks'] as Map? ?? {}),
                    'facebook': val,
                  };
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textInput(
                label: 'Instagram Link',
                initialValue:
                    _formData['socialLinks']?['instagram']?.toString() ?? '',
                onSaved: (val) {
                  _formData['socialLinks'] = {
                    ...(_formData['socialLinks'] as Map? ?? {}),
                    'instagram': val,
                  };
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _textInput(
                label: 'YouTube Link',
                initialValue:
                    _formData['socialLinks']?['youtube']?.toString() ?? '',
                onSaved: (val) {
                  _formData['socialLinks'] = {
                    ...(_formData['socialLinks'] as Map? ?? {}),
                    'youtube': val,
                  };
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textInput(
                label: 'WhatsApp Number / Link',
                initialValue:
                    _formData['socialLinks']?['whatsapp']?.toString() ?? '',
                onSaved: (val) {
                  _formData['socialLinks'] = {
                    ...(_formData['socialLinks'] as Map? ?? {}),
                    'whatsapp': val,
                  };
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // GENERIC FALLBACK
  Widget _buildGenericEditor() {
    return _cardContainer(
      title: '${widget.section.title} Fields',
      children: [
        for (final entry in _formData.entries) ...[
          _textInput(
            label: entry.key,
            initialValue: entry.value.toString(),
            onSaved: (val) => _formData[entry.key] = val,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // REUSABLE FIELD WRAPPERS
  Widget _cardContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingSmall()),
          const Divider(height: 28),
          ...children,
        ],
      ),
    );
  }

  Widget _textInput({
    required String label,
    required String initialValue,
    required void Function(String?) onSaved,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      onChanged: (_) => _markDirty(),
      onSaved: onSaved,
    );
  }
}
