import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../models/media_reference.dart';

/// Contract for detecting content references to media assets across Firestore.
abstract class MediaReferenceRepository {
  /// Inspects both published content and CMS drafts for any references to [item].
  Future<MediaReferenceCheckResult> checkReferences(MediaItem item);
}

/// Firestore implementation of [MediaReferenceRepository] performing
/// bounded, one-time reads across public collections and CMS drafts.
class FirestoreMediaReferenceRepository implements MediaReferenceRepository {
  final FirebaseFirestore? _customFirestore;

  FirestoreMediaReferenceRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[FirestoreMediaReferenceRepository] Firebase access error: $e');
      return null;
    }
  }

  static const List<String> publicCollections = [
    'courses',
    'programs',
    'gallery',
    'faqs',
    'testimonials',
    'site_sections',
  ];

  @override
  Future<MediaReferenceCheckResult> checkReferences(MediaItem item) async {
    final firestore = _firestore;
    if (firestore == null) {
      // In testing environments without Firebase initialized, fail closed
      return MediaReferenceCheckResult(
        mediaItem: item,
        errorMessage: 'Firestore instance is not initialized.',
      );
    }

    try {
      final List<MediaReference> references = [];

      // 1. Fetch CMS drafts and all 6 public collections concurrently
      final draftFuture = firestore.collection('cms_drafts').get();
      final publicFutures = publicCollections.map(
        (coll) => firestore.collection(coll).get(),
      );

      final results = await Future.wait([draftFuture, ...publicFutures]);

      // 2. Process CMS Drafts
      final QuerySnapshot<Map<String, dynamic>> draftSnap = results[0];

      for (final doc in draftSnap.docs) {
        final data = doc.data();
        final matchedFields = MediaReferenceScanner.scanObject(data, item);
        if (matchedFields.isNotEmpty) {
          final draftType = data['contentType']?.toString() ?? 'draft';
          final title = data['title']?.toString() ??
              data['data']?['title']?.toString() ??
              data['data']?['personName']?.toString() ??
              doc.id;
          references.add(
            MediaReference(
              collection: 'cms_drafts',
              documentId: doc.id,
              title: title,
              fieldPaths: matchedFields,
              isDraft: true,
              contentType: draftType,
            ),
          );
        }
      }

      // 3. Process Public Collections
      for (int i = 0; i < publicCollections.length; i++) {
        final collectionName = publicCollections[i];
        final QuerySnapshot<Map<String, dynamic>> snap = results[i + 1];

        for (final doc in snap.docs) {
          final data = doc.data();
          final matchedFields = MediaReferenceScanner.scanObject(data, item);
          if (matchedFields.isNotEmpty) {
            final title = data['title']?.toString() ??
                data['personName']?.toString() ??
                data['name']?.toString() ??
                data['data']?['title']?.toString() ??
                data['data']?['personName']?.toString() ??
                doc.id;
            references.add(
              MediaReference(
                collection: collectionName,
                documentId: doc.id,
                title: title,
                fieldPaths: matchedFields,
                isDraft: false,
                contentType: collectionName,
              ),
            );
          }
        }
      }

      return MediaReferenceCheckResult(
        mediaItem: item,
        references: references,
      );
    } catch (e) {
      // Fail closed: Return error result so deletion cannot proceed
      return MediaReferenceCheckResult(
        mediaItem: item,
        references: const [],
        errorMessage: 'Failed to verify references: $e',
      );
    }
  }
}

/// In-memory fake implementation of [MediaReferenceRepository] for testing.
class FakeMediaReferenceRepository implements MediaReferenceRepository {
  final Map<String, Map<String, dynamic>> cmsDrafts = {};
  final Map<String, Map<String, dynamic>> courses = {};
  final Map<String, Map<String, dynamic>> programs = {};
  final Map<String, Map<String, dynamic>> gallery = {};
  final Map<String, Map<String, dynamic>> faqs = {};
  final Map<String, Map<String, dynamic>> testimonials = {};
  final Map<String, Map<String, dynamic>> siteSections = {};

  bool shouldFail = false;
  String failureMessage = 'Simulated reference check failure';

  FakeMediaReferenceRepository();

  void clearAll() {
    cmsDrafts.clear();
    courses.clear();
    programs.clear();
    gallery.clear();
    faqs.clear();
    testimonials.clear();
    siteSections.clear();
    shouldFail = false;
  }

  @override
  Future<MediaReferenceCheckResult> checkReferences(MediaItem item) async {
    if (shouldFail) {
      return MediaReferenceCheckResult(
        mediaItem: item,
        errorMessage: failureMessage,
      );
    }

    final List<MediaReference> references = [];

    // Scan drafts
    for (final entry in cmsDrafts.entries) {
      final matched = MediaReferenceScanner.scanObject(entry.value, item);
      if (matched.isNotEmpty) {
        final draftType = entry.value['contentType']?.toString() ?? 'draft';
        final title = entry.value['title']?.toString() ??
            entry.value['data']?['title']?.toString() ??
            entry.value['data']?['personName']?.toString() ??
            entry.key;
        references.add(
          MediaReference(
            collection: 'cms_drafts',
            documentId: entry.key,
            title: title,
            fieldPaths: matched,
            isDraft: true,
            contentType: draftType,
          ),
        );
      }
    }

    // Scan public collections
    final Map<String, Map<String, Map<String, dynamic>>> publicMap = {
      'courses': courses,
      'programs': programs,
      'gallery': gallery,
      'faqs': faqs,
      'testimonials': testimonials,
      'site_sections': siteSections,
    };

    for (final collEntry in publicMap.entries) {
      for (final docEntry in collEntry.value.entries) {
        final matched = MediaReferenceScanner.scanObject(docEntry.value, item);
        if (matched.isNotEmpty) {
          final title = docEntry.value['title']?.toString() ??
              docEntry.value['personName']?.toString() ??
              docEntry.value['name']?.toString() ??
              docEntry.value['data']?['title']?.toString() ??
              docEntry.value['data']?['personName']?.toString() ??
              docEntry.key;
          references.add(
            MediaReference(
              collection: collEntry.key,
              documentId: docEntry.key,
              title: title,
              fieldPaths: matched,
              isDraft: false,
              contentType: collEntry.key,
            ),
          );
        }
      }
    }

    return MediaReferenceCheckResult(
      mediaItem: item,
      references: references,
    );
  }
}

/// Riverpod provider for [MediaReferenceRepository].
/// Automatically falls back to [FakeMediaReferenceRepository] if Firebase is not initialized (e.g. in tests).
final mediaReferenceRepositoryProvider =
    Provider<MediaReferenceRepository>((ref) {
  try {
    final instance = FirebaseFirestore.instance;
    return FirestoreMediaReferenceRepository(firestore: instance);
  } catch (_) {
    return FakeMediaReferenceRepository();
  }
});
