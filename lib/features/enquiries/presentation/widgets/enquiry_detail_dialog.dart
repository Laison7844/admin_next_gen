import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/phone_dialer.dart';
import '../../models/enquiry_item.dart';
import '../../providers/enquiry_provider.dart';

class EnquiryDetailDialog extends ConsumerStatefulWidget {
  final EnquiryItem enquiry;

  const EnquiryDetailDialog({
    super.key,
    required this.enquiry,
  });

  @override
  ConsumerState<EnquiryDetailDialog> createState() =>
      _EnquiryDetailDialogState();
}

class _EnquiryDetailDialogState extends ConsumerState<EnquiryDetailDialog> {
  late String _selectedWorkflowStatus;
  late final TextEditingController _notesController;
  bool _isNotesDirty = false;
  bool _isWorkflowDirty = false;

  @override
  void initState() {
    super.initState();
    _selectedWorkflowStatus = widget.enquiry.workflowStatus;
    _notesController =
        TextEditingController(text: widget.enquiry.adminNotes);
    _notesController.addListener(() {
      final dirty = _notesController.text.trim() !=
          widget.enquiry.adminNotes.trim();
      if (dirty != _isNotesDirty) {
        setState(() => _isNotesDirty = dirty);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Not available';
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today at $timeStr';
    return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
  }

  Future<void> _handleCall() async {
    final success = await launchPhoneDialer(widget.enquiry.phone);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Dialing ${widget.enquiry.phone} (number copied to clipboard)'
                : 'Phone number ${widget.enquiry.phone} copied to clipboard',
          ),
          backgroundColor: AppColors.primaryNavy,
        ),
      );
    }
  }

  Future<void> _handleSaveWorkflowStatus() async {
    final controller =
        ref.read(enquiryOperationControllerProvider.notifier);
    final success = await controller.updateWorkflowStatus(
      widget.enquiry.phone,
      _selectedWorkflowStatus,
    );
    if (mounted) {
      if (success) {
        setState(() => _isWorkflowDirty = false);
        final label =
            EnquiryWorkflowStatus.displayName(_selectedWorkflowStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow status updated to "$label".'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update workflow status. Please retry.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveNotes() async {
    final controller =
        ref.read(enquiryOperationControllerProvider.notifier);
    final text = _notesController.text.trim();
    final success =
        await controller.saveAdminNotes(widget.enquiry.phone, text);
    if (mounted) {
      if (success) {
        setState(() => _isNotesDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Administrative notes saved successfully.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save notes. Please retry.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleArchive() async {
    final newStatus = !widget.enquiry.status;
    final controller =
        ref.read(enquiryOperationControllerProvider.notifier);
    final success =
        await controller.toggleStatus(widget.enquiry.phone, newStatus);
    if (mounted) {
      Navigator.of(context).pop();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Enquiry restored to Active.'
                  : 'Enquiry archived.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Enquiry?'),
        content: Text(
          'Are you sure you want to delete the enquiry from "${widget.enquiry.name.isEmpty ? widget.enquiry.phone : widget.enquiry.name}"?\n\n'
          'This action cannot be undone.',
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

    if (confirmed == true && mounted) {
      final controller =
          ref.read(enquiryOperationControllerProvider.notifier);
      final success =
          await controller.deleteEnquiry(widget.enquiry.phone);
      if (mounted) {
        Navigator.of(context).pop(); // Close detail dialog
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enquiry deleted successfully.'),
              backgroundColor: AppColors.mediumNavy,
            ),
          );
        }
      }
    }
  }

  Color _workflowBg(String status) {
    switch (EnquiryWorkflowStatus.normalize(status)) {
      case EnquiryWorkflowStatus.contacted:
        return const Color(0xFFFEF3C7);
      case EnquiryWorkflowStatus.enrolled:
        return const Color(0xFFDCFCE7);
      case EnquiryWorkflowStatus.closed:
        return const Color(0xFFF1F5F9);
      case EnquiryWorkflowStatus.newStatus:
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  Color _workflowText(String status) {
    switch (EnquiryWorkflowStatus.normalize(status)) {
      case EnquiryWorkflowStatus.contacted:
        return const Color(0xFFB45309);
      case EnquiryWorkflowStatus.enrolled:
        return const Color(0xFF15803D);
      case EnquiryWorkflowStatus.closed:
        return const Color(0xFF475569);
      case EnquiryWorkflowStatus.newStatus:
      default:
        return const Color(0xFF0369A1);
    }
  }

  IconData _workflowIcon(String status) {
    switch (EnquiryWorkflowStatus.normalize(status)) {
      case EnquiryWorkflowStatus.contacted:
        return Icons.phone_in_talk_outlined;
      case EnquiryWorkflowStatus.enrolled:
        return Icons.how_to_reg_outlined;
      case EnquiryWorkflowStatus.closed:
        return Icons.check_circle_outline;
      case EnquiryWorkflowStatus.newStatus:
      default:
        return Icons.fiber_new_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opState = ref.watch(enquiryOperationControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.mediumNavy,
                    child: Text(
                      widget.enquiry.name.isNotEmpty
                          ? widget.enquiry.name[0].toUpperCase()
                          : '#',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.enquiry.name.isNotEmpty
                              ? widget.enquiry.name
                              : 'Prospective Student',
                          style: AppTypography.headingSmall(
                            color: AppColors.surfaceWhite,
                          ).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admissions Enquiry & Workflow Details',
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

            // Dialog Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banners Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Workflow Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _workflowBg(widget.enquiry.workflowStatus),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _workflowText(widget.enquiry.workflowStatus)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _workflowIcon(widget.enquiry.workflowStatus),
                                size: 14,
                                color: _workflowText(
                                    widget.enquiry.workflowStatus),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WORKFLOW: ${EnquiryWorkflowStatus.displayName(widget.enquiry.workflowStatus).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _workflowText(
                                      widget.enquiry.workflowStatus),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Archive Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.enquiry.status
                                ? const Color(0xFFECFDF5)
                                : AppColors.softGrayBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.enquiry.status
                                  ? AppColors.successGreen
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.enquiry.status
                                    ? Icons.check_circle_outline
                                    : Icons.archive_outlined,
                                size: 14,
                                color: widget.enquiry.status
                                    ? AppColors.successGreen
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.enquiry.status ? 'ACTIVE' : 'ARCHIVED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.enquiry.status
                                      ? AppColors.successGreen
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Program Badge
                        if (widget.enquiry.program.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softGoldBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.borderGold
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 14,
                                  color: AppColors.primaryGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.enquiry.program,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Phone Contact Row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.enquiry.phone,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Contact / Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: AppColors.primaryNavy,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onPressed: _handleCall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Workflow Status Selector
                    Text(
                      'Admissions Workflow Status',
                      style: AppTypography.headingSmall().copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedWorkflowStatus,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                labelText: 'Workflow Stage',
                              ),
                              items: EnquiryWorkflowStatus.all
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          EnquiryWorkflowStatus.displayName(
                                              status),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedWorkflowStatus = val;
                                    _isWorkflowDirty =
                                        _selectedWorkflowStatus !=
                                            widget.enquiry.workflowStatus;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: const Text('Save Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: AppColors.surfaceWhite,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            onPressed: (_isWorkflowDirty && !opState.isLoading)
                                ? _handleSaveWorkflowStatus
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Administrative Private Notes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Administrative Notes (Private)',
                            style: AppTypography.headingSmall()
                                .copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isNotesDirty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.softGoldBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primaryGold),
                            ),
                            child: const Text(
                              'Unsaved Changes',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Internal notes visible only to academy administrators; never displayed publicly.',
                      style: AppTypography.bodySmall(
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Enter administrative follow-up notes, call remarks, batch preferences...',
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bookmark_added_outlined,
                            size: 16),
                        label: const Text('Save Notes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: AppColors.surfaceWhite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onPressed: (_isNotesDirty && !opState.isLoading)
                            ? _handleSaveNotes
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Original Message Block
                    Text(
                      'Enquiry Message / Remarks',
                      style: AppTypography.headingSmall().copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        widget.enquiry.message.isNotEmpty
                            ? widget.enquiry.message
                            : 'No additional message was included in this enquiry.',
                        style: AppTypography.bodyMedium(
                          color: widget.enquiry.message.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Timestamps
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Received At',
                                style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateTime(widget.enquiry.createdAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.enquiry.updatedAt != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Updated',
                                  style: AppTypography.bodySmall(
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDateTime(widget.enquiry.updatedAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
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

            // Dialog Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                    onPressed: opState.isLoading ? null : _handleDelete,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          widget.enquiry.status
                              ? Icons.archive_outlined
                              : Icons.unarchive_outlined,
                          size: 16,
                        ),
                        label: Text(
                          widget.enquiry.status ? 'Archive' : 'Restore Active',
                        ),
                        onPressed: opState.isLoading ? null : _handleToggleArchive,
                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
