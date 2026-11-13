import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for an admissions enquiry submitted from the public website.
///
/// Preserves the existing Firestore schema stored under `enquiries/{phone}`:
/// - id: String
/// - name: String
/// - phone: String (also used as Document ID)
/// - program: String
/// - message: String
/// - status: bool (true = Active/Received, false = Inactive/Archived)
/// - createdAt: Timestamp?
/// - updatedAt: Timestamp?
class EnquiryItem {
  final String id;
  final String name;
  final String phone;
  final String program;
  final String message;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EnquiryItem({
    this.id = '1',
    required this.name,
    required this.phone,
    required this.program,
    required this.message,
    this.status = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to safely parse Firestore document snapshots.
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

