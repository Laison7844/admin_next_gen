import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../content/models/cms_content_item.dart';
import '../../../content/models/content_type.dart';
import '../../../home_cms/presentation/widgets/publish_status_badge.dart';

class RecentContentCard extends StatelessWidget {
  final List<CmsContentItem> recentUpdates;
  final bool isLoading;

  const RecentContentCard({
    super.key,
    required this.recentUpdates,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recently Updated CMS Content',
                        style: AppTypography.headingSmall(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latest modified drafts and singleton sections in Firestore',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => context.go(RoutePaths.home),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('All Sections'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (recentUpdates.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentUpdates.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: AppColors.borderLight, height: 1),
                itemBuilder: (context, index) {
                  final item = recentUpdates[index];
                  return _buildContentRow(context, item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentRow(BuildContext context, CmsContentItem item) {
    final type = ContentType.tryFromKey(item.contentType);
    final typeName = type?.displayName ?? item.contentType;
    final displayTitle = item.title.trim().isNotEmpty ? item.title : item.id;
    final targetRoute = _resolveRoute(type);

    return InkWell(
      onTap: () {
        if (targetRoute != null) {
          context.go(targetRoute);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.softBlueBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _resolveIcon(type),
                size: 20,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayTitle,
                          style: AppTypography.titleMedium(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softGrayBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.history, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_formatDate(item.updatedAt)}',
                        style: AppTypography.bodySmall(
                            color: AppColors.textMuted),
                      ),
                      if (item.lastEditedBy != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'by ${item.lastEditedBy}',
                          style: AppTypography.bodySmall(
                              color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PublishStatusBadge(
              status: item.publishStatus,
              hasUnpublishedChanges: item.hasUnpublishedChanges,
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveRoute(ContentType? type) {
    if (type == null) return RoutePaths.home;
    switch (type) {
      case ContentType.courses:
        return RoutePaths.courses;
      case ContentType.programs:
        return RoutePaths.programs;
      case ContentType.testimonials:
        return RoutePaths.testimonials;
      case ContentType.gallery:
        return RoutePaths.gallery;
      case ContentType.faqs:
        return RoutePaths.faqs;
      case ContentType.siteSections:
        return RoutePaths.home;
    }
  }

  IconData _resolveIcon(ContentType? type) {
    if (type == null) return Icons.article_outlined;
    switch (type) {
      case ContentType.courses:
        return Icons.menu_book_outlined;
      case ContentType.programs:
        return Icons.school_outlined;
      case ContentType.testimonials:
        return Icons.reviews_outlined;
      case ContentType.gallery:
        return Icons.photo_library_outlined;
      case ContentType.faqs:
        return Icons.quiz_outlined;
      case ContentType.siteSections:
        return Icons.view_quilt_outlined;
    }
  }

  String _formatDate(DateTime dt) {
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
      return '${diff.inDays} d ago';
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.softBlueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 32,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Content Updates Recorded',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Text(
            'When content items and drafts are edited or published, recent activity will appear here.',
            style: AppTypography.bodySmall(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
