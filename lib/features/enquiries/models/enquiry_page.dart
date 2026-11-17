import 'enquiry_item.dart';

/// Filter criteria for admissions enquiries queries.
class EnquiryFilter {
  final String searchQuery;
  final String program; // 'All' or specific program
  final String status; // 'All', 'Active', 'Archived'
  final String workflowStatus; // 'All', 'new', 'contacted', 'enrolled', 'closed'

  const EnquiryFilter({
    this.searchQuery = '',
    this.program = 'All',
    this.status = 'All',
    this.workflowStatus = 'All',
  });

  bool get isDefault =>
      searchQuery.trim().isEmpty &&
      program == 'All' &&
      status == 'All' &&
      workflowStatus == 'All';

  EnquiryFilter copyWith({
    String? searchQuery,
    String? program,
    String? status,
    String? workflowStatus,
  }) {
    return EnquiryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      program: program ?? this.program,
      status: status ?? this.status,
      workflowStatus: workflowStatus ?? this.workflowStatus,
    );
  }

  /// Evaluates whether an [EnquiryItem] satisfies all active filter criteria.
  bool matches(EnquiryItem item) {
    // 1. Search Query (Name or Phone)
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final nameMatches = item.name.toLowerCase().contains(query);
      final phoneMatches = item.phone.toLowerCase().contains(query);
      if (!nameMatches && !phoneMatches) return false;
    }

    // 2. Program Filter
    if (program != 'All' &&
        item.program.trim().toLowerCase() != program.trim().toLowerCase()) {
      return false;
    }

    // 3. Status Filter (Active / Archived)
    if (status == 'Active' && !item.status) return false;
    if (status == 'Archived' && item.status) return false;

    // 4. Workflow Status Filter
    if (workflowStatus != 'All') {
      final target = workflowStatus.trim().toLowerCase();
      if (item.workflowStatus.trim().toLowerCase() != target) return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnquiryFilter &&
          other.searchQuery == searchQuery &&
          other.program == program &&
          other.status == status &&
          other.workflowStatus == workflowStatus;

  @override
  int get hashCode =>
      Object.hash(searchQuery, program, status, workflowStatus);
}

/// Represents a single cursor-paginated page of admissions enquiries.
class EnquiryPage {
  final List<EnquiryItem> items;
  final dynamic cursor;
  final bool hasNextPage;
  final int pageIndex;
  final int pageSize;

  const EnquiryPage({
    required this.items,
    this.cursor,
    required this.hasNextPage,
    required this.pageIndex,
    this.pageSize = 25,
  });

  factory EnquiryPage.empty({int pageIndex = 1, int pageSize = 25}) {
    return EnquiryPage(
      items: const [],
      cursor: null,
      hasNextPage: false,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  /// Number of records loaded on this specific page.
  int get totalOnPage => items.length;

  /// True if there is a valid previous page to navigate back to.
  bool get hasPreviousPage => pageIndex > 1;

  /// True if this page returned zero enquiries.
  bool get isEmpty => items.isEmpty;
}
