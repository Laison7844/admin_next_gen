import 'package:cloud_firestore/cloud_firestore.dart';
import '../../content/models/cms_content_item.dart';
import '../../content/models/content_type.dart';
import '../../content/models/publish_status.dart';

/// Domain model representing a student, parent, or alumni testimonial in the CMS.
class TestimonialItem {
  final String id;
  final String personName;
  final String role;
  final String? program;
  final String testimonialText;
  final String? profileImage;
  final int rating;
  final bool isFeatured;
  final int displayOrder;
  final bool isPublished;
  final bool hasUnpublishedChanges;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? lastEditedBy;

  const TestimonialItem({
    required this.id,
    required this.personName,
    required this.role,
    this.program,
    required this.testimonialText,
    this.profileImage,
    this.rating = 5,
    this.isFeatured = false,
    this.displayOrder = 1,
    this.isPublished = false,
    this.hasUnpublishedChanges = true,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.lastEditedBy,
  });

  /// Resolves publish status
  PublishStatus get publishStatus =>
      isPublished ? PublishStatus.published : PublishStatus.draft;

  /// Converts this testimonial into a data map suitable for `CmsContentItem.data`
  /// and Firestore document storage.
  Map<String, dynamic> toDataMap() {
    return {
      'id': id,
      'personName': personName,
      'role': role,
      if (program != null && program!.trim().isNotEmpty) 'program': program!.trim(),
      'testimonialText': testimonialText,
      if (profileImage != null && profileImage!.trim().isNotEmpty)
        'profileImage': profileImage!.trim(),
      'rating': rating,
      'isFeatured': isFeatured,
      'displayOrder': displayOrder,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (lastEditedBy != null) 'lastEditedBy': lastEditedBy,
    };
  }

  /// Converts this item into a standard [CmsContentItem] for atomic lifecycle operations.
  CmsContentItem toCmsContentItem() {
    return CmsContentItem(
      id: id,
      contentType: ContentType.testimonials.key,
      title: personName,
      data: toDataMap(),
      publishStatus: publishStatus,
      hasUnpublishedChanges: hasUnpublishedChanges,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: publishedAt,
      lastEditedBy: lastEditedBy,
    );
  }

  /// Reconstructs a [TestimonialItem] from a [CmsContentItem].
  factory TestimonialItem.fromCmsContentItem(CmsContentItem item) {
    return TestimonialItem.fromMap(
      item.data,
      docId: item.id,
      isPublished: item.publishStatus == PublishStatus.published,
      hasUnpublishedChanges: item.hasUnpublishedChanges,
      publishedAt: item.publishedAt,
      lastEditedBy: item.lastEditedBy,
    );
  }

  /// Factory constructor to parse a testimonial map from Firestore.
  /// Handles both direct documents and nested data envelopes safely.
  factory TestimonialItem.fromMap(
    Map<String, dynamic> map, {
    String? docId,
    bool? isPublished,
    bool? hasUnpublishedChanges,
    DateTime? publishedAt,
    String? lastEditedBy,
  }) {
    Map<String, dynamic> data = map;
    if (map['data'] is Map) {
      data = Map<String, dynamic>.from(map['data'] as Map);
    }

    final id = (map['id'] ?? data['id'] ?? docId ?? '').toString();
    final personName = (data['personName'] ?? data['name'] ?? map['title'] ?? '').toString();
    final role = (data['role'] ?? data['designation'] ?? 'Student').toString();
    final program = data['program']?.toString();
    final testimonialText = (data['testimonialText'] ?? data['text'] ?? data['message'] ?? data['quote'] ?? '').toString();
    final profileImage = data['profileImage']?.toString() ?? data['imageUrl']?.toString() ?? data['avatar']?.toString();
    
    int rating = 5;
    final rawRating = data['rating'];
    if (rawRating is int) {
      rating = rawRating;
    } else if (rawRating is num) {
      rating = rawRating.toInt();
    } else if (rawRating is String) {
      rating = int.tryParse(rawRating) ?? 5;
    }
    rating = rating.clamp(1, 5);

    bool isFeatured = false;
    final rawFeatured = data['isFeatured'] ?? data['featured'];
    if (rawFeatured is bool) {
      isFeatured = rawFeatured;
    } else if (rawFeatured is String) {
      isFeatured = rawFeatured.toLowerCase().trim() == 'true';
    }

    int displayOrder = 1;
    final rawOrder = data['displayOrder'] ?? data['order'];
    if (rawOrder is int) {
      displayOrder = rawOrder;
    } else if (rawOrder is num) {
      displayOrder = rawOrder.toInt();
    } else if (rawOrder is String) {
      displayOrder = int.tryParse(rawOrder) ?? 1;
    }

    final resolvedIsPublished = isPublished ??
        (map['publishStatus'] == 'published' ||
            data['isPublished'] == true ||
            map['isPublished'] == true);

    final resolvedHasUnpublishedChanges = hasUnpublishedChanges ??
        (map['hasUnpublishedChanges'] == true || !resolvedIsPublished);

    final createdAt = _parseDate(data['createdAt'] ?? map['createdAt']) ?? DateTime.now();
    final updatedAt = _parseDate(data['updatedAt'] ?? map['updatedAt']) ?? DateTime.now();
    final resolvedPublishedAt = publishedAt ?? _parseDate(data['publishedAt'] ?? map['publishedAt']);

    return TestimonialItem(
      id: id,
      personName: personName,
      role: role,
      program: (program != null && program.trim().isNotEmpty) ? program.trim() : null,
      testimonialText: testimonialText,
      profileImage: (profileImage != null && profileImage.trim().isNotEmpty) ? profileImage.trim() : null,
      rating: rating,
      isFeatured: isFeatured,
      displayOrder: displayOrder,
      isPublished: resolvedIsPublished,
      hasUnpublishedChanges: resolvedHasUnpublishedChanges,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: resolvedPublishedAt,
      lastEditedBy: lastEditedBy ?? map['lastEditedBy']?.toString() ?? data['lastEditedBy']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  TestimonialItem copyWith({
    String? id,
    String? personName,
    String? role,
    String? program,
    String? testimonialText,
    String? profileImage,
    int? rating,
    bool? isFeatured,
    int? displayOrder,
    bool? isPublished,
    bool? hasUnpublishedChanges,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? lastEditedBy,
  }) {
    return TestimonialItem(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      role: role ?? this.role,
      program: program ?? this.program,
      testimonialText: testimonialText ?? this.testimonialText,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      isFeatured: isFeatured ?? this.isFeatured,
      displayOrder: displayOrder ?? this.displayOrder,
      isPublished: isPublished ?? this.isPublished,
      hasUnpublishedChanges:
          hasUnpublishedChanges ?? this.hasUnpublishedChanges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
    );
  }
}

