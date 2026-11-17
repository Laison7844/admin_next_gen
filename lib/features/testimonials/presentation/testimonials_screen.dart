import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/testimonial_item.dart';
import '../providers/testimonial_provider.dart';
import 'widgets/testimonial_card.dart';
import 'widgets/testimonial_delete_dialog.dart';
import 'widgets/testimonial_editor_dialog.dart';
import 'widgets/testimonial_preview_dialog.dart';

class TestimonialsScreen extends ConsumerStatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  ConsumerState<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends ConsumerState<TestimonialsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    TestimonialEditorDialog.show(
      context: context,
    );
  }

  void _openEditDialog(TestimonialItem testimonial) {
    TestimonialEditorDialog.show(
      context: context,
      item: testimonial,
    );
  }

  Future<void> _handleTogglePublish(TestimonialItem item) async {
    final controller =
        ref.read(testimonialOperationControllerProvider.notifier);

    if (item.isPublished) {
      await controller.unpublish(item.id);
    } else {
      await controller.publish(item.id);
    }
  }

  Future<void> _handleDelete(TestimonialItem item) async {
    final action = await TestimonialDeleteDialog.show(context, item);
    if (action == null || !mounted) return;

    final controller =
        ref.read(testimonialOperationControllerProvider.notifier);

    if (action == TestimonialDeleteAction.unpublishOnly) {
      await controller.unpublish(item.id);
    } else if (action == TestimonialDeleteAction.permanentDelete) {
      await controller.delete(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredTestimonialsProvider);
    final metrics = ref.watch(testimonialMetricsProvider);
    final currentFilter = ref.watch(testimonialFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final horizontalPadding = isDesktop ? 32.0 : 16.0;
          final verticalPadding = isDesktop ? 28.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildHeader(isDesktop),
                    const SizedBox(height: 24),

                    // Metrics Row
                    _buildStatCards(metrics, isDesktop),
                    const SizedBox(height: 24),

                    // Filter & Search Bar
                    _buildFilterBar(currentFilter, isDesktop),
                    const SizedBox(height: 20),

                    // List / Empty State / Loading / Error
                    filteredAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(60.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                      error: (err, stack) => _buildErrorCard(err),
                      data: (items) {
                        if (items.isEmpty) {
                          return _buildEmptyState(
                            isFiltered: metrics.total > 0,
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return TestimonialCard(
                              testimonial: item,
                              onPreview: () =>
                                  TestimonialPreviewDialog.show(context, item),
                              onEdit: () => _openEditDialog(item),
                              onTogglePublish: () =>
                                  _handleTogglePublish(item),
                              onDelete: () => _handleDelete(item),
                            );
                          },
                        );
                      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final addButton = ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Testimonial'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: AppColors.surfaceWhite,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _openCreateDialog,
        );

        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
                        color: AppColors.primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.primaryGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Testimonials',
                            style: AppTypography.headingMedium(
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage student achievements and parent reviews for the public website.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                addButton,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testimonials',
                      style: AppTypography.headingLarge(
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage student achievements, parent reviews, and alumni endorsements for the public website.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              addButton,
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(TestimonialMetrics metrics, bool isDesktop) {
    final cards = [
      _buildStatItem('Total Testimonials', metrics.total.toString(),
          Icons.reviews_outlined, AppColors.primaryNavy),
      _buildStatItem('Published', metrics.published.toString(),
          Icons.check_circle_outline, AppColors.successGreen),
      _buildStatItem('Unpublished', metrics.drafts.toString(),
          Icons.pending_actions_outlined, AppColors.textSecondary),
      _buildStatItem('Featured', metrics.featured.toString(),
          Icons.star_outline, AppColors.primaryGold),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktop) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        }

        final cardWidth = ((constraints.maxWidth - 12) / 2).clamp(130.0, 260.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((c) => SizedBox(
                    width: cardWidth,
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(TestimonialFilter currentFilter, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          // Filter Chips
          Wrap(
            spacing: 8,
            children: TestimonialFilter.values.map((filter) {
              final isSelected = currentFilter == filter;
              return ChoiceChip(
                label: Text(filter.label),
                selected: isSelected,
                selectedColor: AppColors.primaryNavy,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.surfaceWhite
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.softGrayBg,
                onSelected: (val) {
                  if (val) {
                    ref.read(testimonialFilterProvider.notifier).state =
                        filter;
                  }
                },
              );
            }).toList(),
          ),
          // Search Field
          SizedBox(
            width: isDesktop ? 260 : 180,
            height: 38,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reviews...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(testimonialSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) {
                ref.read(testimonialSearchQueryProvider.notifier).state =
                    val.trim();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isFiltered}) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.format_quote_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No matching testimonials found'
                : 'No testimonials added yet.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try adjusting your search query or filter selection.'
                : 'Click "Add First Testimonial" below to create your first student or parent review.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add First Testimonial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: AppColors.surfaceWhite,
              ),
              onPressed: _openCreateDialog,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object err) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.errorRed),
          const SizedBox(height: 12),
          Text(
            'Error Loading Testimonials: $err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.errorRed),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.refresh(testimonialsListProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
