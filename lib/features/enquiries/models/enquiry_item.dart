import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported admissions workflow statuses for enquiries.
class EnquiryWorkflowStatus {
  static const String newStatus = 'new';
  static const String contacted = 'contacted';
  static const String enrolled = 'enrolled';
  static const String closed = 'closed';

  static const List<String> all = [
    newStatus,
    contacted,
    enrolled,
    closed,
  ];

  /// Safely normalizes raw values, defaulting missing or unknown values to `new`.
  static String normalize(String? raw) {
    if (raw == null) return newStatus;
    final lower = raw.trim().toLowerCase();
    if (all.contains(lower)) return lower;
    return newStatus;
  }

  /// User-facing display label.
  static String displayName(String status) {
    switch (normalize(status)) {
      case contacted:
        return 'Contacted';
      case enrolled:
        return 'Enrolled';
      case closed:
        return 'Closed';
      case newStatus:
      default:
        return 'New';
    }
  }
}

/// Domain model for an admissions enquiry submitted from the public website.
///
/// Preserves the existing Firestore schema stored under `enquiries/{phone}`:
/// - id: String
/// - name: String
/// - phone: String (also used as Document ID)
/// - program: String
/// - message: String
/// - status: bool (true = Active/Received, false = Inactive/Archived)
/// - workflowStatus: String (optional: new, contacted, enrolled, closed)
/// - adminNotes: String (optional: administrative private notes)
/// - createdAt: Timestamp?
/// - updatedAt: Timestamp?
class EnquiryItem {
  final String id;
  final String name;
  final String phone;
  final String program;
  final String message;
  final bool status;
  final String workflowStatus;
  final String adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EnquiryItem({
    this.id = '1',
    required this.name,
    required this.phone,
    required this.program,
    required this.message,
    this.status = true,
    this.workflowStatus = EnquiryWorkflowStatus.newStatus,
    this.adminNotes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to safely parse Firestore document snapshots.
  /// Backward compatible: missing `workflowStatus` defaults to `new`,
  /// and missing `adminNotes` defaults to empty string.
  factory EnquiryItem.fromFirestore(Map<String, dynamic> data, String docId) {
    return EnquiryItem(
      id: data['id']?.toString() ?? '1',
      name: data['name']?.toString().trim() ?? '',
      phone: (data['phone']?.toString().trim().isNotEmpty == true)
          ? data['phone'].toString().trim()
          : docId.trim(),
      program: data['program']?.toString().trim() ?? '',
      message: data['message']?.toString().trim() ?? '',
      status: data['status'] == true,
      workflowStatus:
          EnquiryWorkflowStatus.normalize(data['workflowStatus']?.toString()),
      adminNotes: data['adminNotes']?.toString() ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Converts model back into a Firestore payload matching existing schema.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'program': program,
      'message': message,
      'status': status,
      if (workflowStatus.isNotEmpty) 'workflowStatus': workflowStatus,
      if (adminNotes.isNotEmpty) 'adminNotes': adminNotes,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  EnquiryItem copyWith({
    String? id,
    String? name,
    String? phone,
    String? program,
    String? message,
    bool? status,
    String? workflowStatus,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnquiryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      program: program ?? this.program,
      message: message ?? this.message,
      status: status ?? this.status,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
