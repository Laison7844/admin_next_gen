import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/providers/content_provider.dart';
import '../../enquiries/providers/enquiry_provider.dart';
import '../../media/providers/media_provider.dart';
import '../models/dashboard_analytics.dart';

/// Provider holding the timestamp of the last manual or automatic refresh.
final dashboardLastRefreshedProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Combined provider computing [DashboardAnalyticsData] from the respective
/// domain providers: [enquiryListProvider], [contentListProvider(null)], and [mediaListProvider].
///
/// Each data source is evaluated independently, meaning that a delay or error in
/// one domain (e.g. Storage media listing) does not block or corrupt the other domains.
final dashboardAnalyticsProvider = Provider<DashboardAnalyticsData>((ref) {
  final lastRefreshed = ref.watch(dashboardLastRefreshedProvider);

  final enquiriesAsync = ref.watch(enquiryListProvider);
  final contentAsync = ref.watch(contentListProvider(null));
  final publishedDocIdsAsync = ref.watch(publishedDocIdsProvider);
  final mediaAsync = ref.watch(mediaListProvider);

  // Compute Enquiry Analytics
  final enquiryAnalytics = enquiriesAsync.when(
    data: (items) => EnquiryAnalytics.fromEnquiries(items),
    loading: () => const EnquiryAnalytics(),
    error: (error, stackTrace) => const EnquiryAnalytics(),
  );

  // Compute Content Analytics
  final contentAnalytics = contentAsync.when(
    data: (drafts) => ContentAnalytics.fromDrafts(
      drafts,
      publishedDocIds: publishedDocIdsAsync.valueOrNull,
    ),
    loading: () => const ContentAnalytics(),
    error: (error, stackTrace) => const ContentAnalytics(),
  );

  // Compute Media Analytics
  final mediaAnalytics = mediaAsync.when(
    data: (media) => MediaAnalytics.fromMedia(media),
    loading: () => const MediaAnalytics(),
    error: (error, stackTrace) => const MediaAnalytics(),
  );

  return DashboardAnalyticsData(
    enquiryAnalytics: enquiryAnalytics,
    contentAnalytics: contentAnalytics,
    mediaAnalytics: mediaAnalytics,
    isEnquiriesLoading: enquiriesAsync.isLoading,
    isContentLoading:
        contentAsync.isLoading || publishedDocIdsAsync.isLoading,
    isMediaLoading: mediaAsync.isLoading,
    enquiriesError: enquiriesAsync.hasError
        ? enquiriesAsync.error.toString()
        : null,
    contentError: contentAsync.hasError
        ? contentAsync.error.toString()
        : (publishedDocIdsAsync.hasError
            ? publishedDocIdsAsync.error.toString()
            : null),
    mediaError: mediaAsync.hasError
        ? mediaAsync.error.toString()
        : null,
    lastRefreshed: lastRefreshed,
  );
});

/// Controller handling manual dashboard refreshes.
///
/// Invalidates the underlying FutureProviders to trigger clean, fresh
/// one-time reads without persistent snapshot listeners.
class DashboardRefreshController {
  final Ref _ref;

  DashboardRefreshController(this._ref);

  void refreshAll() {
    _ref.invalidate(enquiryListProvider);
    _ref.invalidate(contentListProvider(null));
    _ref.invalidate(publishedDocIdsProvider);
    _ref.invalidate(mediaListProvider);
    _ref.read(dashboardLastRefreshedProvider.notifier).state = DateTime.now();
  }
}

final dashboardRefreshControllerProvider =
    Provider<DashboardRefreshController>((ref) {
  return DashboardRefreshController(ref);
});
