import 'media_item.dart';

/// Represents a detected reference to a media asset in Firestore.
class MediaReference {
  /// The Firestore collection where the reference was found
  /// ('courses', 'programs', 'gallery', 'faqs', 'testimonials', 'site_sections', 'cms_drafts').
  final String collection;

  /// The document identifier.
  final String documentId;

  /// Human-readable title of the document.
  final String title;

  /// Field path(s) within the document containing the reference.
  final List<String> fieldPaths;

  /// Whether the reference is located in `cms_drafts`.
  final bool isDraft;

  /// Content type key (e.g. 'courses', 'programs', 'site_sections').
  final String contentType;

  const MediaReference({
    required this.collection,
    required this.documentId,
    required this.title,
    required this.fieldPaths,
    required this.isDraft,
    required this.contentType,
  });

  /// Friendly human-readable label for display in the deletion dialog.
  String get displayLabel {
    final fieldsDesc = fieldPaths.join(', ');
    if (isDraft) {
      return 'CMS Draft ($contentType): "$title" [$documentId] (Field: $fieldsDesc)';
    }
    return 'Published $contentType: "$title" [$documentId] (Field: $fieldsDesc)';
  }

  Map<String, dynamic> toMap() {
    return {
      'collection': collection,
      'documentId': documentId,
      'title': title,
      'fieldPaths': fieldPaths,
      'isDraft': isDraft,
      'contentType': contentType,
    };
  }

  factory MediaReference.fromMap(Map<String, dynamic> map) {
    return MediaReference(
      collection: map['collection']?.toString() ?? '',
      documentId: map['documentId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      fieldPaths: (map['fieldPaths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isDraft: map['isDraft'] == true,
      contentType: map['contentType']?.toString() ?? '',
    );
  }
}

/// Result of inspecting Firestore collections for references to a [MediaItem].
class MediaReferenceCheckResult {
  final MediaItem mediaItem;
  final List<MediaReference> references;
  final String? errorMessage;

  const MediaReferenceCheckResult({
    required this.mediaItem,
    this.references = const [],
    this.errorMessage,
  });

  /// True if at least one reference was found.
  bool get isReferenced => references.isNotEmpty;

  /// Total count of references found.
  int get referenceCount => references.length;

  /// True if an error occurred during verification (fails closed).
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// True if and only if the item has 0 references and verification succeeded without error.
  bool get canDelete => !isReferenced && !hasError;
}

/// Helper scanner utility to safely detect canonical Firebase Storage URL references.
class MediaReferenceScanner {
  /// Strictly checks whether a candidate string points to the given [MediaItem].
  /// Does NOT use loose substring matching.
  static bool isReferenceMatch(String candidate, MediaItem item) {
    final cleanCandidate = candidate.trim();
    if (cleanCandidate.isEmpty) return false;

    // 1. Direct exact match with downloadUrl
    if (cleanCandidate == item.downloadUrl.trim()) {
      return true;
    }

    // 2. Direct exact match with fullPath (e.g. 'media/general/photo.jpg')
    if (cleanCandidate == item.fullPath.trim()) {
      return true;
    }

    // 3. Match 'gs://<bucket>/<fullPath>'
    if (cleanCandidate.startsWith('gs://')) {
      final slashIndex = cleanCandidate.indexOf('/', 5);
      if (slashIndex != -1) {
        final path = cleanCandidate.substring(slashIndex + 1);
        if (path == item.fullPath) return true;
      }
    }

    // 4. Exact Firebase Storage REST download endpoint:
    // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<url-encoded-path>?alt=media...
    // or local emulator: http://127.0.0.1:9199/v0/b/<bucket>/o/<url-encoded-path>?alt=media...
    final uri = Uri.tryParse(cleanCandidate);
    if (uri != null && uri.hasScheme) {
      final segments = uri.pathSegments;
      final oIndex = segments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < segments.length) {
        final encodedPath = segments[oIndex + 1];
        try {
          final decodedPath = Uri.decodeComponent(encodedPath);
          if (decodedPath == item.fullPath) {
            return true;
          }
        } catch (_) {}
      }

      // 5. Google Cloud Storage endpoint: https://storage.googleapis.com/<bucket>/<path>
      if (uri.host == 'storage.googleapis.com' && segments.length > 1) {
        final path = segments.sublist(1).join('/');
        if (path == item.fullPath) {
          return true;
        }
      }

      // 6. Base URI match (without query parameters) if item.downloadUrl is a valid URI
      final itemUri = Uri.tryParse(item.downloadUrl);
      if (itemUri != null && itemUri.hasScheme) {
        if (uri.scheme == itemUri.scheme &&
            uri.host == itemUri.host &&
            uri.port == itemUri.port &&
            uri.path == itemUri.path) {
          return true;
        }
      }
    }

    return false;
  }

  /// Recursively walks any arbitrary object (Map, List, primitives)
  /// and gathers all field paths that reference [item].
  static List<String> scanObject(dynamic obj, MediaItem item) {
    final matchedFields = <String>[];
    _scanRecursive(obj, '', item, matchedFields);
    return matchedFields;
  }

  static void _scanRecursive(
    dynamic obj,
    String currentPath,
    MediaItem item,
    List<String> matchedFieldPaths,
  ) {
    if (obj == null) return;

    if (obj is String) {
      if (isReferenceMatch(obj, item)) {
        matchedFieldPaths.add(currentPath.isEmpty ? 'value' : currentPath);
      }
    } else if (obj is Map) {
      for (final entry in obj.entries) {
        final key = entry.key.toString();
        final newPath = currentPath.isEmpty ? key : '$currentPath.$key';
        _scanRecursive(entry.value, newPath, item, matchedFieldPaths);
      }
    } else if (obj is List) {
      for (int i = 0; i < obj.length; i++) {
        final newPath = '$currentPath[$i]';
        _scanRecursive(obj[i], newPath, item, matchedFieldPaths);
      }
    }
  }
}

