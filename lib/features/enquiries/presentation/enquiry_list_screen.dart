import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_dialer.dart';
import '../models/enquiry_item.dart';
import '../providers/enquiry_provider.dart';
import 'widgets/enquiry_detail_dialog.dart';

class EnquiryListScreen extends ConsumerStatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  ConsumerState<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends ConsumerState<EnquiryListScreen> {
  String _searchQuery = '';
  String _selectedProgram = 'All';
  String _selectedStatus = 'All'; // 'All', 'Active', 'Archived'
  bool _sortNewestFirst = true;

  void _openDetails(EnquiryItem enquiry) {
    showDialog(
      context: context,
      builder: (ctx) => EnquiryDetailDialog(enquiry: enquiry),
    );
  }

  Future<void> _handleCall(EnquiryItem enquiry) async {
    final success = await launchPhoneDialer(enquiry.phone);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Dialing ${enquiry.phone} (number copied to clipboard)'
                : 'Phone number ${enquiry.phone} copied to clipboard',
          ),
          backgroundColor: AppColors.primaryNavy,
        ),
      );
    }
  }

  Future<void> _handleDelete(EnquiryItem enquiry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Enquiry?'),
        content: Text(
          'Are you sure you want to delete the enquiry from "${enquiry.name.isEmpty ? enquiry.phone : enquiry.name}"?\n\n'
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
      final success = await controller.deleteEnquiry(enquiry.phone);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enquiry deleted successfully.'),
            backgroundColor: AppColors.mediumNavy,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return '$m min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(enquiryListProvider);
    final opState = ref.watch(enquiryOperationControllerProvider);

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
                    _buildHeader(isDesktop),
                    const SizedBox(height: 24),
                    enquiriesAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => _buildErrorCard(err),
                      data: (enquiries) => _buildContent(enquiries, opState),
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

  Widget _buildHeader(bool isDesktop) {
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
              Icons.mail_outline_rounded,
              color: AppColors.primaryGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Admissions Enquiries',
                      style: AppTypography.headingMedium().copyWith(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Live Admissions',
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
                  'Manage admissions enquiries submitted through the public website (enquiries collection).',
                  style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Refresh Enquiries',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.read(enquiryOperationControllerProvider.notifier).refresh();
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
          Text('Failed to load admissions enquiries',
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
              ref.read(enquiryOperationControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<EnquiryItem> allEnquiries,
    EnquiryOperationState opState,
  ) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Summary statistics
    final totalCount = allEnquiries.length;
    final activeCount = allEnquiries.where((e) => e.status).length;
    final recentCount = allEnquiries.where((e) {
      if (e.createdAt == null) return false;
      return e.createdAt!.isAfter(sevenDaysAgo);
    }).length;

    // Distinct programs
    final programs = allEnquiries
        .map((e) => e.program.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Client-side filtering
    final query = _searchQuery.trim().toLowerCase();
    var filtered = allEnquiries.where((e) {
      // Search filter
      if (query.isNotEmpty) {
        final matchesName = e.name.toLowerCase().contains(query);
        final matchesPhone = e.phone.toLowerCase().contains(query);
        if (!matchesName && !matchesPhone) return false;
      }

      // Program filter
      if (_selectedProgram != 'All' && e.program.trim() != _selectedProgram) {
        return false;
      }

      // Status filter
      if (_selectedStatus == 'Active' && !e.status) return false;
      if (_selectedStatus == 'Archived' && e.status) return false;

      return true;
    }).toList();

    // Sorting
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
            final isWide = constraints.maxWidth > 700;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 1.8 : 1.5,
              children: [
                _buildMetricCard(
                  title: 'Total Enquiries',
                  value: '$totalCount',
                  subtitle: 'All-time submissions',
                  icon: Icons.all_inbox_rounded,
                  iconColor: AppColors.infoBlue,
                  bgColor: AppColors.softBlueBg,
                ),
                _buildMetricCard(
                  title: 'Active / Received',
                  value: '$activeCount',
                  subtitle: 'Pending follow-up',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.successGreen,
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildMetricCard(
                  title: 'Last 7 Days',
                  value: '$recentCount',
                  subtitle: 'Recently submitted',
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.primaryGold,
                  bgColor: AppColors.softGoldBg,
                ),
                _buildMetricCard(
                  title: 'Programs',
                  value: '${programs.length}',
                  subtitle: 'Distinct inquiries',
                  icon: Icons.school_outlined,
                  iconColor: AppColors.accentCyan,
                  bgColor: AppColors.softGrayBg,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Search & Filter Toolbar
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
              // Search Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by student/parent name or phone number...',
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
                      onChanged: (val) => setState(() => _searchQuery = val),
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
                ],
              ),
              const SizedBox(height: 14),

              // Filter Chips Row
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final s in ['All', 'Active', 'Archived'])
                    ChoiceChip(
                      label: Text(s),
                      selected: _selectedStatus == s,
                      onSelected: (_) => setState(() => _selectedStatus = s),
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: TextStyle(
                        color: _selectedStatus == s
                            ? AppColors.surfaceWhite
                            : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Text(
                    'Program:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProgram,
                        isDense: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All Programs'),
                          ),
                          for (final p in programs)
                            DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedProgram = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // List / Empty State
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
                  Icons.inbox_outlined,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  allEnquiries.isEmpty
                      ? 'No admissions enquiries received yet'
                      : 'No enquiries match your search criteria',
                  style: AppTypography.headingSmall(),
                ),
                const SizedBox(height: 6),
                Text(
                  allEnquiries.isEmpty
                      ? 'Admissions form submissions from next-gen-excellence.web.app will appear here automatically.'
                      : 'Try clearing your search query or program/status filters.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildEnquiryCard(item);
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

  Widget _buildEnquiryCard(EnquiryItem item) {
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
          // Initial Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundLight,
            child: Text(
              item.name.isNotEmpty ? item.name[0].toUpperCase() : '#',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name.isNotEmpty ? item.name : 'Prospective Student',
                        style: AppTypography.headingSmall().copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.status
                            ? const Color(0xFFECFDF5)
                            : AppColors.softGrayBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status ? 'ACTIVE' : 'ARCHIVED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.status
                              ? AppColors.successGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    if (item.program.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.school_outlined,
                          size: 14, color: AppColors.primaryGold),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.program,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Actions
          IconButton(
            tooltip: 'Call Phone',
            icon: const Icon(Icons.phone, size: 20),
            color: AppColors.primaryGold,
            onPressed: () => _handleCall(item),
          ),
          IconButton(
            tooltip: 'View Details',
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: AppColors.primaryNavy,
            onPressed: () => _openDetails(item),
          ),
          IconButton(
            tooltip: 'Delete Enquiry',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.errorRed,
            onPressed: () => _handleDelete(item),
          ),
        ],
      ),
    );
  }
}
