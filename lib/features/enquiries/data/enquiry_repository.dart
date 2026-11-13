import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enquiry_item.dart';

/// Contract for admissions enquiry administrative operations.
abstract class EnquiryRepository {
  /// Fetches enquiries ordered newest first, limited by [limit] for efficiency.
  Future<List<EnquiryItem>> getEnquiries({int limit = 100});

  /// Retrieves a single enquiry document by phone number (doc ID).
  Future<EnquiryItem?> getEnquiryByPhone(String phone);

  /// Updates the active/archived status of an existing enquiry.
  Future<void> updateEnquiryStatus(String phone, bool status);

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

      // Sort client-side newest first
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return list;
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
  Future<void> deleteEnquiry(String phone) async {
    final cleanPhone = phone.trim();
    await _firestore.collection(collectionPath).doc(cleanPhone).delete();
  }
}
