import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_dialer.dart';
import '../models/enquiry_item.dart';
import '../models/enquiry_page.dart';
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
  String _selectedWorkflow = 'All'; // 'All', 'New', 'Contacted', 'Enrolled', 'Closed'
  bool _sortNewestFirst = true;

  void _applyFilter() {
    ref.read(enquiryPaginationControllerProvider.notifier).setFilter(
          EnquiryFilter(
            searchQuery: _searchQuery,
            program: _selectedProgram,
            status: _selectedStatus,
            workflowStatus: _selectedWorkflow,
          ),
        );
  }

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
    final pagState = ref.watch(enquiryPaginationControllerProvider);
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
                    if (pagState.isLoading && pagState.currentPage == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (pagState.errorMessage != null &&
                        pagState.currentPage == null)
                      _buildErrorCard(pagState.errorMessage!)
                    else
                      _buildContent(pagState, opState),
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
      padding: EdgeInsets.all(isDesktop ? 24 : 14),
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
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Admissions Enquiries',
                      style: AppTypography.headingMedium().copyWith(fontSize: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withAlpha(46),
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
                  'Manage admissions enquiries submitted through the public website.',
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
        border: Border.all(color: AppColors.errorRed.withAlpha(76)),
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
              ref.read(enquiryPaginationControllerProvider.notifier).retry();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    EnquiryPaginationState pagState,
    EnquiryOperationState opState,
  ) {
    final items = pagState.items;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Summary statistics for current page
    final totalCount = items.length;
    final activeCount = items.where((e) => e.status).length;
    final recentCount = items.where((e) {
      if (e.createdAt == null) return false;
      return e.createdAt!.isAfter(sevenDaysAgo);
    }).length;

    // Distinct programs
    final loadedPrograms = items
        .map((e) => e.program.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    final programs = loadedPrograms.toList()..sort();

    // Client-side sort toggle
    final displayItems = List<EnquiryItem>.from(items);
    displayItems.sort((a, b) {
      final dtA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = _sortNewestFirst ? dtB.compareTo(dtA) : dtA.compareTo(dtB);
      if (cmp != 0) return cmp;
      return b.phone.compareTo(a.phone);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Notice Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.softBlueBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.infoBlue.withAlpha(51)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.infoBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Showing latest 100 admissions enquiries. Statistics reflect loaded records.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

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
                  title: 'Loaded Enquiries',
                  value: '$totalCount',
                  subtitle: 'Latest 100 loaded',
                  icon: Icons.all_inbox_rounded,
                  iconColor: AppColors.infoBlue,
                  bgColor: AppColors.softBlueBg,
                ),
                _buildMetricCard(
                  title: 'Active (Loaded)',
                  value: '$activeCount',
                  subtitle: 'Pending follow-up',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.successGreen,
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildMetricCard(
                  title: 'Last 7 Days (Loaded)',
                  value: '$recentCount',
                  subtitle: 'From loaded records',
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.primaryGold,
                  bgColor: AppColors.softGoldBg,
                ),
                _buildMetricCard(
                  title: 'Programs (Loaded)',
                  value: '${programs.length}',
                  subtitle: 'From loaded records',
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
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        _applyFilter();
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
                      onSelected: (_) {
                        setState(() => _selectedStatus = s);
                        _applyFilter();
                      },
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
                    'Workflow:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final w in ['All', 'New', 'Contacted', 'Enrolled', 'Closed'])
                    ChoiceChip(
                      label: Text(w),
                      selected: _selectedWorkflow == w,
                      onSelected: (_) {
                        setState(() => _selectedWorkflow = w);
                        _applyFilter();
                      },
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: TextStyle(
                        color: _selectedWorkflow == w
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
                        value: programs.contains(_selectedProgram)
                            ? _selectedProgram
                            : 'All',
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
                            _applyFilter();
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
        if (displayItems.isEmpty)
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
                  pagState.filter.isDefault
                      ? 'No admissions enquiries received yet'
                      : 'No enquiries match your search criteria',
                  style: AppTypography.headingSmall(),
                ),
                const SizedBox(height: 6),
                Text(
                  pagState.filter.isDefault
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
            itemCount: displayItems.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return _buildEnquiryCard(item);
            },
          ),

        const SizedBox(height: 16),
        _buildPaginationBar(pagState),
      ],
    );
  }

  Widget _buildPaginationBar(EnquiryPaginationState pagState) {
    final pageIndex = pagState.pageIndex;
    final totalOnPage = pagState.totalOnPage;
    final hasNext = pagState.hasNextPage;
    final hasPrev = pagState.hasPreviousPage;
    final isLoading = pagState.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Page $pageIndex',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  'Showing $totalOnPage record${totalOnPage == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Previous'),
                onPressed: (!hasPrev || isLoading)
                    ? null
                    : () {
                        ref
                            .read(enquiryPaginationControllerProvider.notifier)
                            .previousPage();
                      },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: AppColors.surfaceWhite,
                ),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Next'),
                onPressed: (!hasNext || isLoading)
                    ? null
                    : () {
                        ref
                            .read(enquiryPaginationControllerProvider.notifier)
                            .nextPage();
                      },
              ),
            ],
          ),
        ],
      ),
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
                const SizedBox(height: 1),
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
    final statusColor =
        item.status ? AppColors.successGreen : AppColors.textSecondary;
    final statusLabel = item.status ? 'ACTIVE' : 'ARCHIVED';

    Color workflowBg;
    Color workflowText;
    switch (item.workflowStatus.toLowerCase()) {
      case EnquiryWorkflowStatus.contacted:
        workflowBg = AppColors.infoBlue.withAlpha(38);
        workflowText = AppColors.infoBlue;
        break;
      case EnquiryWorkflowStatus.enrolled:
        workflowBg = AppColors.successGreen.withAlpha(38);
        workflowText = AppColors.successGreen;
        break;
      case EnquiryWorkflowStatus.closed:
        workflowBg = AppColors.textSecondary.withAlpha(38);
        workflowText = AppColors.textSecondary;
        break;
      case EnquiryWorkflowStatus.newStatus:
      default:
        workflowBg = AppColors.primaryGold.withAlpha(46);
        workflowText = AppColors.primaryNavy;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Student Name + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.isEmpty ? 'Anonymous Parent' : item.name,
                        style: AppTypography.headingSmall().copyWith(
                          fontSize: 17,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
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
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    // Active/Archived Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Workflow Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: workflowBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        EnquiryWorkflowStatus.displayName(item.workflowStatus)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: workflowText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Program Chip
            if (item.program.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softBlueBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.infoBlue.withAlpha(51)),
                ),
                child: Text(
                  item.program,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),

            // Enquiry Message Box
            if (item.message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),

            // Admin Notes Indicator
            if (item.adminNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 14, color: AppColors.primaryGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Admin Note: ${item.adminNotes}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              children: [
                // Quick Call
                TextButton.icon(
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.successGreen,
                  ),
                  onPressed: () => _handleCall(item),
                ),
                const SizedBox(width: 8),

                // Details & Workflow Dialog
                Tooltip(
                  message: 'View Details',
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Details & Workflow'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                    ),
                    onPressed: () => _openDetails(item),
                  ),
                ),
                const Spacer(),

                // Delete Action
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.textSecondary),
                  tooltip: 'Delete Enquiry',
                  onPressed: () => _handleDelete(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
