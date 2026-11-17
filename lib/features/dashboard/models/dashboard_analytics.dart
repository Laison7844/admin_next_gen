import 'package:flutter/foundation.dart';
import '../../content/models/cms_content_item.dart';
import '../../content/models/content_type.dart';
import '../../content/models/publish_status.dart';
import '../../enquiries/models/enquiry_item.dart';
import '../../media/models/media_item.dart';

/// Analytics metrics calculated from the loaded admissions enquiry dataset.
///
/// NOTE: The enquiry repository loads up to 100 records for performance.
/// These metrics represent the latest loaded sample, not necessarily the
/// entire collection.
@immutable
class EnquiryAnalytics {
  final int totalLoaded;
  final int activeCount;
  final int archivedCount;
  final int newCount;
  final int contactedCount;
  final int enrolledCount;
  final int closedCount;
  final int last7DaysCount;
  final List<EnquiryItem> recentEnquiries;

  const EnquiryAnalytics({
    this.totalLoaded = 0,
    this.activeCount = 0,
    this.archivedCount = 0,
    this.newCount = 0,
    this.contactedCount = 0,
    this.enrolledCount = 0,
    this.closedCount = 0,
    this.last7DaysCount = 0,
    this.recentEnquiries = const [],
  });

  /// Calculates analytics from a list of loaded [EnquiryItem]s.
  /// An optional [referenceTime] can be supplied for deterministic testing.
  factory EnquiryAnalytics.fromEnquiries(
    List<EnquiryItem> items, {
    DateTime? referenceTime,
  }) {
    if (items.isEmpty) {
      return const EnquiryAnalytics();
    }

    int active = 0;
    int archived = 0;
    int newWorkflow = 0;
    int contacted = 0;
    int enrolled = 0;
    int closed = 0;
    int last7Days = 0;

    final now = referenceTime ?? DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final item in items) {
      // Active vs Archived (status is boolean where true = Active, false = Archived)
      if (item.status) {
        active++;
      } else {
        archived++;
      }

      // Workflow status breakdown
      final normalizedStatus =
          EnquiryWorkflowStatus.normalize(item.workflowStatus);
      switch (normalizedStatus) {
        case EnquiryWorkflowStatus.contacted:
          contacted++;
          break;
        case EnquiryWorkflowStatus.enrolled:
          enrolled++;
          break;
        case EnquiryWorkflowStatus.closed:
          closed++;
          break;
        case EnquiryWorkflowStatus.newStatus:
        default:
          newWorkflow++;
          break;
      }

      // Last 7 days check
      if (item.createdAt != null && item.createdAt!.isAfter(sevenDaysAgo)) {
        last7Days++;
      }
    }

    // Sort newest first to ensure recentEnquiries is correctly ordered
    final sorted = List<EnquiryItem>.from(items)
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    final recent = sorted.take(5).toList();

    return EnquiryAnalytics(
      totalLoaded: items.length,
      activeCount: active,
      archivedCount: archived,
      newCount: newWorkflow,
      contactedCount: contacted,
      enrolledCount: enrolled,
      closedCount: closed,
      last7DaysCount: last7Days,
      recentEnquiries: recent,
    );
  }

  /// Calculates percentage of total loaded (0.0 to 100.0).
  double percentage(int count) {
    if (totalLoaded <= 0) return 0.0;
    return ((count / totalLoaded) * 100).clamp(0.0, 100.0);
  }
}

/// Analytics metrics calculated from website CMS content working drafts.
@immutable
class ContentAnalytics {
  final int publishedCourses;
  final int draftCourses;
  final int publishedPrograms;
  final int draftPrograms;
  final int publishedTestimonials;
  final int draftTestimonials;
  final int publishedGallery;
  final int draftGallery;
  final int totalGallery;
  final int publishedFaqs;
  final int draftFaqs;
  final int publishedSections;
  final int draftSections;
  final int totalSections;
  final List<CmsContentItem> recentUpdates;

  const ContentAnalytics({
    this.publishedCourses = 0,
    this.draftCourses = 0,
    this.publishedPrograms = 0,
    this.draftPrograms = 0,
    this.publishedTestimonials = 0,
    this.draftTestimonials = 0,
    this.publishedGallery = 0,
    this.draftGallery = 0,
    this.totalGallery = 0,
    this.publishedFaqs = 0,
    this.draftFaqs = 0,
    this.publishedSections = 0,
    this.draftSections = 0,
    this.totalSections = 0,
    this.recentUpdates = const [],
  });

  int get totalPublished =>
      publishedCourses +
      publishedPrograms +
      publishedTestimonials +
      publishedGallery +
      publishedFaqs +
      publishedSections;

  int get totalDrafts =>
      draftCourses +
      draftPrograms +
      draftTestimonials +
      draftGallery +
      draftFaqs +
      draftSections;

  static const List<String> coreSingletonSectionIds = [
    'home_hero',
    'feature_highlights',
    'about_us',
    'why_nextgen',
    'learning_modes',
    'pledge',
    'assessments',
    'banner_cta',
    'contact_footer',
  ];

  /// Aggregates content metrics across working drafts in `cms_drafts`
  /// and cross-references actual live public documents in Firestore collections.
  factory ContentAnalytics.fromDrafts(
    List<CmsContentItem> drafts, {
    Map<String, Set<String>>? publishedDocIds,
  }) {
    if (drafts.isEmpty &&
        (publishedDocIds == null ||
            publishedDocIds.values.every((s) => s.isEmpty))) {
      return const ContentAnalytics();
    }

    int pubCourses = 0;
    int dftCourses = 0;
    int pubPrograms = 0;
    int dftPrograms = 0;
    int pubTestimonials = 0;
    int dftTestimonials = 0;
    int pubGallery = 0;
    int dftGallery = 0;
    int pubFaqs = 0;
    int dftFaqs = 0;
    int pubSections = 0;
    int dftSections = 0;

    if (publishedDocIds != null) {
      // 1. Live counts derived directly from actual public Firestore collections
      final liveCourses = publishedDocIds['courses'] ?? const <String>{};
      final livePrograms = publishedDocIds['programs'] ?? const <String>{};
      final liveTestimonials =
          publishedDocIds['testimonials'] ?? const <String>{};
      final liveGallery = publishedDocIds['gallery'] ?? const <String>{};
      final liveFaqs = publishedDocIds['faqs'] ?? const <String>{};
      final liveSections =
          publishedDocIds['site_sections'] ?? const <String>{};

      pubCourses = liveCourses.length;
      pubPrograms = livePrograms.length;
      pubTestimonials = liveTestimonials.length;
      pubGallery = liveGallery.length;
      pubFaqs = liveFaqs.length;

      // Only count sections in site_sections that match valid core singletons
      pubSections = coreSingletonSectionIds
          .where((id) => liveSections.contains(id))
          .length;

      // 2. Draft counts derived from working drafts in cms_drafts
      for (final item in drafts) {
        final type = ContentType.tryFromKey(item.contentType);
        final bool isLive;
        switch (type) {
          case ContentType.courses:
            isLive = liveCourses.contains(item.id);
            if (!isLive || item.publishStatus.isDraft) dftCourses++;
            break;
          case ContentType.programs:
            isLive = livePrograms.contains(item.id);
            if (!isLive || item.publishStatus.isDraft) dftPrograms++;
            break;
          case ContentType.testimonials:
            isLive = liveTestimonials.contains(item.id);
            if (!isLive || item.publishStatus.isDraft) dftTestimonials++;
            break;
          case ContentType.gallery:
            isLive = liveGallery.contains(item.id);
            if (!isLive || item.publishStatus.isDraft) dftGallery++;
            break;
          case ContentType.faqs:
            isLive = liveFaqs.contains(item.id);
            if (!isLive || item.publishStatus.isDraft) dftFaqs++;
            break;
          case ContentType.siteSections:
            isLive = liveSections.contains(item.id);
            if (!isLive || item.publishStatus.isDraft) dftSections++;
            break;
          case null:
            break;
        }
      }
    } else {
      // Fallback: examine draft metadata when public collections are not directly queried
      for (final item in drafts) {
        final isPublished = item.publishStatus == PublishStatus.published;
        final type = ContentType.tryFromKey(item.contentType);

        switch (type) {
          case ContentType.courses:
            if (isPublished) {
              pubCourses++;
            } else {
              dftCourses++;
            }
            break;
          case ContentType.programs:
            if (isPublished) {
              pubPrograms++;
            } else {
              dftPrograms++;
            }
            break;
          case ContentType.testimonials:
            if (isPublished) {
              pubTestimonials++;
            } else {
              dftTestimonials++;
            }
            break;
          case ContentType.gallery:
            if (isPublished) {
              pubGallery++;
            } else {
              dftGallery++;
            }
            break;
          case ContentType.faqs:
            if (isPublished) {
              pubFaqs++;
            } else {
              dftFaqs++;
            }
            break;
          case ContentType.siteSections:
            if (isPublished) {
              pubSections++;
            } else {
              dftSections++;
            }
            break;
          case null:
            // Unknown or legacy content type
            break;
        }
      }
    }

    // Sort by updatedAt descending to identify recent content updates
    final sorted = List<CmsContentItem>.from(drafts)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final recent = sorted.take(6).toList();

    return ContentAnalytics(
      publishedCourses: pubCourses,
      draftCourses: dftCourses,
      publishedPrograms: pubPrograms,
      draftPrograms: dftPrograms,
      publishedTestimonials: pubTestimonials,
      draftTestimonials: dftTestimonials,
      publishedGallery: pubGallery,
      draftGallery: dftGallery,
      totalGallery: pubGallery + dftGallery,
      publishedFaqs: pubFaqs,
      draftFaqs: dftFaqs,
      publishedSections: pubSections,
      draftSections: dftSections,
      totalSections: pubSections + dftSections,
      recentUpdates: recent,
    );
  }
}

/// Analytics metrics calculated from Firebase Storage media library items.
@immutable
class MediaAnalytics {
  final int totalImages;
  final Map<String, int> folderCounts;

  const MediaAnalytics({
    this.totalImages = 0,
    this.folderCounts = const {},
  });

  factory MediaAnalytics.fromMedia(List<MediaItem> items) {
    if (items.isEmpty) {
      return const MediaAnalytics();
    }

    final counts = <String, int>{};
    for (final item in items) {
      final folder = item.folder.trim().toLowerCase();
      counts[folder] = (counts[folder] ?? 0) + 1;
    }

    return MediaAnalytics(
      totalImages: items.length,
      folderCounts: counts,
    );
  }
}

/// Consolidated state model for CMS Dashboard Analytics.
@immutable
class DashboardAnalyticsData {
  final EnquiryAnalytics enquiryAnalytics;
  final ContentAnalytics contentAnalytics;
  final MediaAnalytics mediaAnalytics;
  final bool isEnquiriesLoading;
  final bool isContentLoading;
  final bool isMediaLoading;
  final String? enquiriesError;
  final String? contentError;
  final String? mediaError;
  final DateTime lastRefreshed;

  const DashboardAnalyticsData({
    this.enquiryAnalytics = const EnquiryAnalytics(),
    this.contentAnalytics = const ContentAnalytics(),
    this.mediaAnalytics = const MediaAnalytics(),
    this.isEnquiriesLoading = false,
    this.isContentLoading = false,
    this.isMediaLoading = false,
    this.enquiriesError,
    this.contentError,
    this.mediaError,
    required this.lastRefreshed,
  });

  bool get isAnyLoading =>
      isEnquiriesLoading || isContentLoading || isMediaLoading;

  bool get hasAnyError =>
      enquiriesError != null || contentError != null || mediaError != null;

  DashboardAnalyticsData copyWith({
    EnquiryAnalytics? enquiryAnalytics,
    ContentAnalytics? contentAnalytics,
    MediaAnalytics? mediaAnalytics,
    bool? isEnquiriesLoading,
    bool? isContentLoading,
    bool? isMediaLoading,
    String? enquiriesError,
    String? contentError,
    String? mediaError,
    DateTime? lastRefreshed,
  }) {
    return DashboardAnalyticsData(
      enquiryAnalytics: enquiryAnalytics ?? this.enquiryAnalytics,
      contentAnalytics: contentAnalytics ?? this.contentAnalytics,
      mediaAnalytics: mediaAnalytics ?? this.mediaAnalytics,
      isEnquiriesLoading: isEnquiriesLoading ?? this.isEnquiriesLoading,
      isContentLoading: isContentLoading ?? this.isContentLoading,
      isMediaLoading: isMediaLoading ?? this.isMediaLoading,
      enquiriesError: enquiriesError ?? this.enquiriesError,
      contentError: contentError ?? this.contentError,
      mediaError: mediaError ?? this.mediaError,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }
}

