import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enquiry_item.dart';
import '../models/enquiry_page.dart';

/// Contract for admissions enquiry administrative operations.
abstract class EnquiryRepository {
  /// Fetches enquiries ordered newest first, limited by [limit] for efficiency.
  /// Preserved for backward compatibility and dashboard widgets.
  Future<List<EnquiryItem>> getEnquiries({int limit = 100});

  /// Fetches a single page of enquiries using Firestore cursor-based pagination.
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  });

  /// Retrieves a single enquiry document by phone number (doc ID).
  Future<EnquiryItem?> getEnquiryByPhone(String phone);

  /// Updates the active/archived status of an existing enquiry.
  Future<void> updateEnquiryStatus(String phone, bool status);

  /// Updates workflow status and/or administrative private notes.
  Future<void> updateWorkflow({
    required String phone,
    String? workflowStatus,
    String? adminNotes,
  });

  /// Permanently deletes an enquiry document.
  Future<void> deleteEnquiry(String phone);
}

/// Firestore implementation for [EnquiryRepository] interacting with `enquiries` collection.
class FirestoreEnquiryRepository implements EnquiryRepository {
  static const String collectionPath = 'enquiries';

  final FirebaseFirestore _firestore;

  FirestoreEnquiryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<EnquiryItem>> getEnquiries({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return EnquiryItem.fromFirestore(doc.data(), doc.id);
      }).toList();
    } on FirebaseException {
      // Fallback in case of index issues or unindexed legacy documents
      final fallbackSnapshot =
          await _firestore.collection(collectionPath).limit(limit).get();

      final list = fallbackSnapshot.docs.map((doc) {
        return EnquiryItem.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Sort client-side newest first with phone tie-breaker
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) {
          return b.phone.compareTo(a.phone);
        }
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        final cmp = b.createdAt!.compareTo(a.createdAt!);
        if (cmp != 0) return cmp;
        return b.phone.compareTo(a.phone);
      });

      return list;
    }
  }

  @override
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  }) async {
    final activeFilter = filter ?? const EnquiryFilter();

    // 1. Exact phone search optimization: O(1) single-document fetch by doc ID
    final cleanSearch = activeFilter.searchQuery.trim();
    final isExact10DigitPhone = RegExp(r'^\d{10}$').hasMatch(cleanSearch);
    if (isExact10DigitPhone) {
      final doc =
          await _firestore.collection(collectionPath).doc(cleanSearch).get();
      if (doc.exists && doc.data() != null) {
        final item = EnquiryItem.fromFirestore(doc.data()!, doc.id);
        if (activeFilter.matches(item)) {
          return EnquiryPage(
            items: [item],
            cursor: null,
            hasNextPage: false,
            pageIndex: 1,
            pageSize: pageSize,
          );
        }
      }
      return EnquiryPage.empty(pageIndex: 1, pageSize: pageSize);
    }

    try {
      // 2. Structured Firestore queries
      // Build base query with server-side equality filters
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

      if (activeFilter.program != 'All') {
        query = query.where('program', isEqualTo: activeFilter.program);
      }
      if (activeFilter.status != 'All') {
        final isActive = activeFilter.status.toLowerCase() == 'active';
        query = query.where('status', isEqualTo: isActive);
      }
      if (activeFilter.workflowStatus != 'All') {
        query = query.where(
          'workflowStatus',
          isEqualTo: activeFilter.workflowStatus.toLowerCase(),
        );
      }

      // Order deterministically by createdAt DESC and FieldPath.documentId DESC
      query = query
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true);

      if (startAfterCursor is DocumentSnapshot) {
        query = query.startAfterDocument(startAfterCursor);
      }

      // If no text search query is set, execute pure server-side cursor pagination
      if (cleanSearch.isEmpty) {
        final snapshot = await query.limit(pageSize + 1).get();
        final hasNext = snapshot.docs.length > pageSize;
        final docs = hasNext
            ? snapshot.docs.sublist(0, pageSize)
            : snapshot.docs;

        final items = docs.map((doc) {
          return EnquiryItem.fromFirestore(doc.data(), doc.id);
        }).toList();

        final nextCursor = docs.isNotEmpty ? docs.last : null;

        return EnquiryPage(
          items: items,
          cursor: nextCursor,
          hasNextPage: hasNext,
          pageIndex: pageIndex,
          pageSize: pageSize,
        );
      } else {
        // Text search (candidate name or partial phone) applied on top of server-filtered query
        final matchedItems = <EnquiryItem>[];
        dynamic currentCursor = startAfterCursor;
        dynamic lastDoc;
        bool hasMoreDocs = true;

        while (matchedItems.length < pageSize && hasMoreDocs) {
          var batchQuery = query.limit(50);
          if (currentCursor is DocumentSnapshot) {
            batchQuery = batchQuery.startAfterDocument(currentCursor);
          }

          final batchSnapshot = await batchQuery.get();
          if (batchSnapshot.docs.isEmpty) {
            hasMoreDocs = false;
            break;
          }

          for (final doc in batchSnapshot.docs) {
            lastDoc = doc;
            final item = EnquiryItem.fromFirestore(doc.data(), doc.id);
            if (activeFilter.matches(item)) {
              matchedItems.add(item);
              if (matchedItems.length == pageSize) {
                break;
              }
            }
          }

          currentCursor = batchSnapshot.docs.last;
          if (batchSnapshot.docs.length < 50) {
            hasMoreDocs = false;
          }
        }

        // Check if additional matching records exist for hasNextPage
        bool hasNextPage = false;
        if (matchedItems.length == pageSize && hasMoreDocs) {
          var checkQuery = query.limit(50);
          if (lastDoc is DocumentSnapshot) {
            checkQuery = checkQuery.startAfterDocument(lastDoc);
          }
          final checkSnapshot = await checkQuery.get();
          for (final doc in checkSnapshot.docs) {
            final item = EnquiryItem.fromFirestore(doc.data(), doc.id);
            if (activeFilter.matches(item)) {
              hasNextPage = true;
              break;
            }
          }
        }

        return EnquiryPage(
          items: matchedItems,
          cursor: lastDoc,
          hasNextPage: hasNextPage,
          pageIndex: pageIndex,
          pageSize: pageSize,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' ||
          (e.message?.contains('requires an index') ?? false)) {
        throw StateError(
          'Firestore query requires a composite index: ${e.message}. '
          'Please ensure the composite index for the selected filter combinations is deployed.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<EnquiryItem?> getEnquiryByPhone(String phone) async {
    final cleanPhone = phone.trim();
    final doc =
        await _firestore.collection(collectionPath).doc(cleanPhone).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return EnquiryItem.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<void> updateEnquiryStatus(String phone, bool status) async {
    final cleanPhone = phone.trim();
    await _firestore.collection(collectionPath).doc(cleanPhone).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateWorkflow({
    required String phone,
    String? workflowStatus,
    String? adminNotes,
  }) async {
    final cleanPhone = phone.trim();
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (workflowStatus != null) {
      updates['workflowStatus'] =
          EnquiryWorkflowStatus.normalize(workflowStatus);
    }
    if (adminNotes != null) {
      updates['adminNotes'] = adminNotes.trim();
    }
    await _firestore.collection(collectionPath).doc(cleanPhone).update(updates);
  }

  @override
  Future<void> deleteEnquiry(String phone) async {
    final cleanPhone = phone.trim();
    await _firestore.collection(collectionPath).doc(cleanPhone).delete();
  }
}
