import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cms_content_item.dart';
import '../models/publish_status.dart';

/// Abstract contract for CMS content operations.
abstract class ContentRepository {
  /// Retrieves working drafts from `cms_drafts`, optionally filtered by [contentType].
  /// Uses a one-time fetch to optimize cost and avoid unnecessary listeners.
  Future<List<CmsContentItem>> getDrafts({String? contentType});

  /// Retrieves a single draft item by its [id].
  Future<CmsContentItem?> getDraft(String id);

  /// Retrieves the current published version from the public collection if it exists.
  Future<Map<String, dynamic>?> getPublishedItem(String contentType, String id);

  /// Saves or updates a draft document in `cms_drafts/{id}`.
  /// If the item was already published, this does NOT touch the public collection.
  Future<void> saveDraft(CmsContentItem item);

  /// Atomically publishes content:
  /// 1. Exactly replaces the target public collection document (e.g. `courses/{id}`)
  ///    with current draft data (removed fields/arrays disappear cleanly).
  /// 2. Updates `cms_drafts/{id}` with `publishStatus = published` and
  ///    `hasUnpublishedChanges = false`.
  /// If [expectedUpdatedAt] is provided and the stored draft is newer, throws a
  /// conflict exception to protect against concurrent tab overwrites.
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt});

  /// Atomically unpublishes content:
  /// 1. Deletes document from public collection.
  /// 2. Updates `cms_drafts/{id}` with `publishStatus = draft` and
  ///    `hasUnpublishedChanges = true`.
  /// The draft is safely preserved in the CMS.
  Future<void> unpublish(String draftId);

  /// Permanently removes content:
  /// 1. Deletes public version from public collection if currently published.
  /// 2. Deletes draft from `cms_drafts/{id}`.
  Future<void> delete(String draftId);

  /// Retrieves the set of document IDs currently present in the public collection.
  /// Used for verifying actual live published content on the public website.
  Future<Set<String>> getPublishedDocIds(String contentType) async => const {};
}

/// Firestore implementation of [ContentRepository] enforcing the dual-collection
/// architecture and atomic publishing lifecycle.
class FirestoreContentRepository implements ContentRepository {
  static const String draftsCollection = 'cms_drafts';

  final FirebaseFirestore _firestore;

  FirestoreContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    Query<Map<String, dynamic>> query = _firestore.collection(draftsCollection);

    if (contentType != null && contentType.isNotEmpty) {
      query = query.where('contentType', isEqualTo: contentType);
    }

    // Cost-conscious: one-time get() avoiding persistent real-time listener bandwidth.
    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return CmsContentItem.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  @override
  Future<CmsContentItem?> getDraft(String id) async {
    final doc = await _firestore.collection(draftsCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return CmsContentItem.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    final doc = await _firestore.collection(contentType).doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return doc.data();
  }

  @override
  Future<Set<String>> getPublishedDocIds(String contentType) async {
    Query<Map<String, dynamic>> query = _firestore.collection(contentType);

    // For testimonials, public website strictly requires isPublished == true.
    if (contentType == 'testimonials') {
      query = query.where('isPublished', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    final draftRef = _firestore.collection(draftsCollection).doc(item.id);

    // Save strictly to `cms_drafts`. Live public collection is completely untouched.
    await draftRef.set(
      item.toFirestore(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {
    final draftDocRef = _firestore.collection(draftsCollection).doc(draftId);

    await _firestore.runTransaction((transaction) async {
      final draftSnapshot = await transaction.get(draftDocRef);
      if (!draftSnapshot.exists || draftSnapshot.data() == null) {
        throw StateError(
            'Cannot publish draft: item "$draftId" does not exist.');
      }

      final draft = CmsContentItem.fromFirestore(
        draftSnapshot.data()!,
        draftSnapshot.id,
      );

      // Concurrent modification safety check:
      // If expectedUpdatedAt is passed and stored draft was modified after that time, abort.
      if (expectedUpdatedAt != null &&
          draft.updatedAt.difference(expectedUpdatedAt).inMilliseconds > 500) {
        throw StateError(
          'Concurrent edit detected: This item was updated in another session at '
          '${draft.updatedAt.toIso8601String()}. Please reload before publishing.',
        );
      }

      final publicCollection = draft.publicCollection;
      final publicDocRef =
          _firestore.collection(publicCollection).doc(draft.id);

      final now = DateTime.now();

      final publishedItem = draft.copyWith(
        publishStatus: PublishStatus.published,
        hasUnpublishedChanges: false,
        publishedAt: now,
        updatedAt: now,
      );

      // 1. EXACT REPLACEMENT of public document (no merge: true).
      // Any fields or array elements deleted from the draft are removed from the public site.
      transaction.set(
        publicDocRef,
        publishedItem.toPublicPayload(),
      );

      // 2. Update draft record in CMS
      transaction.set(
        draftDocRef,
        publishedItem.toFirestore(),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> unpublish(String draftId) async {
    final draft = await getDraft(draftId);
    if (draft == null) {
      throw StateError('Cannot unpublish draft: item "$draftId" does not exist.');
    }

    final publicCollection = draft.publicCollection;
    final publicDocRef = _firestore.collection(publicCollection).doc(draft.id);
    final draftDocRef = _firestore.collection(draftsCollection).doc(draft.id);

    final now = DateTime.now();

    final updatedDraft = draft.copyWith(
      publishStatus: PublishStatus.draft,
      hasUnpublishedChanges: true,
      updatedAt: now,
    );

    // Atomic batch write
    final batch = _firestore.batch();

    // 1. Remove from public collection
    batch.delete(publicDocRef);

    // 2. Update draft record in CMS
    batch.set(
      draftDocRef,
      updatedDraft.toFirestore(),
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<void> delete(String draftId) async {
    final draft = await getDraft(draftId);
    final draftDocRef = _firestore.collection(draftsCollection).doc(draftId);

    final batch = _firestore.batch();

    // 1. If item was published, remove public document
    if (draft != null && draft.publishStatus.isPublished) {
      final publicDocRef =
          _firestore.collection(draft.publicCollection).doc(draft.id);
      batch.delete(publicDocRef);
    }

    // 2. Remove draft from CMS
    batch.delete(draftDocRef);

    await batch.commit();
  }
}

