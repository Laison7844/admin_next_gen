import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_type.dart';
import 'publish_status.dart';

/// Reusable domain model for CMS content items and working drafts.
class CmsContentItem {
  final String id;
  final String contentType;
  final String title;
  final Map<String, dynamic> data;
  final PublishStatus publishStatus;
  final bool hasUnpublishedChanges;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? lastEditedBy;

  const CmsContentItem({
    required this.id,
    required this.contentType,
    required this.title,
    required this.data,
    this.publishStatus = PublishStatus.draft,
    this.hasUnpublishedChanges = true,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.lastEditedBy,
  });

  /// Helper to get typed ContentType enum
  ContentType get type => ContentType.fromKey(contentType);

  /// Target public collection name
  String get publicCollection => type.publicCollection;

  /// Creates a draft document payload for `cms_drafts/{id}`.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'contentType': contentType,
      'title': title,
      'data': data,
      'publishStatus': publishStatus.key,
      'hasUnpublishedChanges': hasUnpublishedChanges,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (lastEditedBy != null) 'lastEditedBy': lastEditedBy,
    };
  }

  /// Creates public payload for target public collection (e.g. `courses/{id}`, `testimonials/{id}`).
  Map<String, dynamic> toPublicPayload() {
    final publicData = Map<String, dynamic>.from(data);
    publicData['isPublished'] = true;

    return {
      'id': id,
      'title': title,
      'isPublished': true,
      'data': publicData,
      'publishedAt': Timestamp.fromDate(publishedAt ?? DateTime.now()),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Factory constructor to parse document from Firestore.
  factory CmsContentItem.fromFirestore(Map<String, dynamic> map, String docId) {
    return CmsContentItem(
      id: map['id']?.toString() ?? docId,
      contentType: map['contentType']?.toString() ?? 'courses',
      title: map['title']?.toString() ?? '',
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      publishStatus: PublishStatus.fromKey(map['publishStatus']?.toString()),
      hasUnpublishedChanges: map['hasUnpublishedChanges'] == true,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      publishedAt: _parseDate(map['publishedAt']),
      lastEditedBy: map['lastEditedBy']?.toString(),
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

  CmsContentItem copyWith({
    String? id,
    String? contentType,
    String? title,
    Map<String, dynamic>? data,
    PublishStatus? publishStatus,
    bool? hasUnpublishedChanges,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? lastEditedBy,
  }) {
    return CmsContentItem(
      id: id ?? this.id,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      data: data ?? this.data,
      publishStatus: publishStatus ?? this.publishStatus,
      hasUnpublishedChanges:
          hasUnpublishedChanges ?? this.hasUnpublishedChanges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
    );
  }
}

