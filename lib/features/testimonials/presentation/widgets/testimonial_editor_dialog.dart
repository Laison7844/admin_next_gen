import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../media/presentation/widgets/media_picker_dialog.dart';
import '../../models/testimonial_item.dart';
import '../../providers/testimonial_provider.dart';

class TestimonialEditorDialog extends ConsumerStatefulWidget {
  final TestimonialItem? item;
  final void Function(TestimonialItem item)? onSave;

  const TestimonialEditorDialog({
    super.key,
    this.item,
    this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    TestimonialItem? item,
    void Function(TestimonialItem item)? onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TestimonialEditorDialog(
        item: item,
        onSave: onSave,
      ),
    );
  }

  @override
  ConsumerState<TestimonialEditorDialog> createState() =>
      _TestimonialEditorDialogState();
}

class _TestimonialEditorDialogState
    extends ConsumerState<TestimonialEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _programController;
  late TextEditingController _textController;
  late TextEditingController _imageController;
  late TextEditingController _orderController;

  static const List<String> _commonRoles = [
    'Student',
    'Parent',
    'Alumni',
    'Educator',
    'Mentor',
  ];

  late String _selectedRole;
  int _rating = 5;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    final t = widget.item;

    _idController = TextEditingController(
      text: t?.id ?? 'testimonial_${DateTime.now().millisecondsSinceEpoch}',
    );
    _nameController = TextEditingController(text: t?.personName ?? '');
    _selectedRole = t?.role ?? 'Student';
    _roleController = TextEditingController(text: _selectedRole);
    _programController = TextEditingController(text: t?.program ?? '');
    _textController = TextEditingController(text: t?.testimonialText ?? '');
    _imageController = TextEditingController(text: t?.profileImage ?? '');
    _orderController =
        TextEditingController(text: (t?.displayOrder ?? 1).toString());

    _rating = t?.rating ?? 5;
    _isFeatured = t?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _programController.dispose();
    _textController.dispose();
    _imageController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool publishLive}) async {
    if (!_formKey.currentState!.validate()) return;

    final order = int.tryParse(_orderController.text.trim()) ?? 1;
    final now = DateTime.now();

    final testimonial = TestimonialItem(
      id: _idController.text.trim(),
      personName: _nameController.text.trim(),
      role: _roleController.text.trim().isNotEmpty
          ? _roleController.text.trim()
          : 'Student',
      program: _programController.text.trim().isNotEmpty
          ? _programController.text.trim()
          : null,
      testimonialText: _textController.text.trim(),
      profileImage: _imageController.text.trim().isNotEmpty
          ? _imageController.text.trim()
          : null,
      rating: _rating,
      isFeatured: _isFeatured,
      displayOrder: order,
      isPublished: publishLive,
      hasUnpublishedChanges: true,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
      publishedAt: publishLive ? now : widget.item?.publishedAt,
    );

    if (widget.onSave != null) {
      widget.onSave!(testimonial);
      Navigator.of(context).pop();
      return;
    }

    final controller =
        ref.read(testimonialOperationControllerProvider.notifier);
    final saved = await controller.saveTestimonial(testimonial);

    if (saved && publishLive) {
      await controller.publish(testimonial.id);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_comment_outlined,
                    color: AppColors.primaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Testimonial' : 'New Testimonial',
                    style:
                        AppTypography.titleMedium(color: AppColors.primaryNavy),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document ID (read-only if editing)
                      Text('Testimonial ID',
                          style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _idController,
                        readOnly: isEditing,
                        decoration: InputDecoration(
                          hintText: 'e.g. testimonial_aarav_sharma',
                          filled: isEditing,
                          fillColor: isEditing
                              ? AppColors.softGrayBg.withValues(alpha: 0.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Person Name (Required)
                      Text('Person Name *',
                          style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Priya Nair / Dr. Rajesh Verma',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role (Required)
                      Text('Role *', style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _commonRoles.contains(_selectedRole)
                                  ? _selectedRole
                                  : null,
                              decoration: const InputDecoration(),
                              hint: const Text('Select Role'),
                              items: _commonRoles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRole = val;
                                    _roleController.text = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _roleController,
                              decoration: const InputDecoration(
                                hintText: 'Or enter custom role',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Program (Optional)
                      Text('Program / Class (Optional)',
                          style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _programController,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Class 10 Board Excellence / JEE Foundation',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Testimonial Quote / Review (Required)
                      Text('Testimonial Quote / Review *',
                          style: AppTypography.titleMedium()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _textController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Share the student or parent experience, academic improvements, confidence gains, etc...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Testimonial text is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Rating Selector (1–5)
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rating',
                                  style: AppTypography.titleMedium()),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (index) {
                                  final starValue = index + 1;
                                  final isSelected = _rating >= starValue;
                                  return IconButton(
                                    iconSize: 26,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isSelected
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: isSelected
                                          ? AppColors.primaryGold
                                          : AppColors.borderLight,
                                    ),
                                    onPressed: () {
                                      setState(() => _rating = starValue);
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Profile Image with Media Library picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Profile Image URL (Optional)',
                              style: AppTypography.titleMedium(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 15),
                            label: const Text('Media Library',
                                style: TextStyle(fontSize: 13)),
                            onPressed: () async {
                              final selected = await MediaPickerDialog.show(
                                context,
                                initialSelectedUrl: _imageController.text,
                                preferredFolder: 'testimonials',
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
                              'https://firebasestorage.googleapis.com/... or assets/...',
                          suffixIcon: _imageController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() => _imageController.clear());
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Order & Featured Row
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
                          const SizedBox(width: 24),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text(
                                'Featured',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                'Highlight prominently on site',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _isFeatured,
                              onChanged: (v) => setState(() => _isFeatured = v),
                              contentPadding: EdgeInsets.zero,
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
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton(
                    onPressed: () => _submit(publishLive: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                    ),
                    child: const Text('Save Changes'),
                  ),
                  ElevatedButton(
                    onPressed: () => _submit(publishLive: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.surfaceWhite,
                    ),
                    child: const Text('Save & Publish to Website'),
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
