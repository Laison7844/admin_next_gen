import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/enquiries/data/enquiry_repository.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_item.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_page.dart';
import 'package:admin_next_gen/features/enquiries/providers/enquiry_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository implementation simulating Firestore collection-wide querying
/// and cursor-based pagination over an arbitrary dataset.
class AuditDatasetEnquiryRepository implements EnquiryRepository {
  final List<EnquiryItem> _dataset;

  AuditDatasetEnquiryRepository(this._dataset);

  @override
  Future<List<EnquiryItem>> getEnquiries({int limit = 100}) async {
    final sorted = List<EnquiryItem>.from(_dataset);
    sorted.sort(_sortComparator);
    return sorted.take(limit).toList();
  }

  @override
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  }) async {
    final activeFilter = filter ?? const EnquiryFilter();

    // 1. Exact phone search optimization (O(1) document ID lookup)
    final cleanSearch = activeFilter.searchQuery.trim();
    final isExact10DigitPhone = RegExp(r'^\d{10}$').hasMatch(cleanSearch);
    if (isExact10DigitPhone) {
      final doc = _dataset.where((e) => e.phone == cleanSearch).firstOrNull;
      if (doc != null && activeFilter.matches(doc)) {
        return EnquiryPage(
          items: [doc],
          cursor: null,
          hasNextPage: false,
          pageIndex: 1,
          pageSize: pageSize,
        );
      }
      return EnquiryPage.empty(pageIndex: 1, pageSize: pageSize);
    }

    // 2. Collection-wide filtering: executed BEFORE pagination
    var filtered = List<EnquiryItem>.from(_dataset);
    filtered.sort(_sortComparator);

    if (!activeFilter.isDefault) {
      filtered = filtered.where((item) => activeFilter.matches(item)).toList();
    }

    // 3. Cursor determination
    int startIndex = 0;
    if (startAfterCursor != null) {
      final cursorId = startAfterCursor.toString();
      final idx = filtered.indexWhere((e) => e.phone == cursorId);
      if (idx != -1) {
        startIndex = idx + 1;
      }
    } else {
      startIndex = (pageIndex - 1) * pageSize;
    }

    if (startIndex >= filtered.length) {
      return EnquiryPage(
        items: const [],
        cursor: null,
        hasNextPage: false,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
    }

    final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(startIndex, endIndex);
    final hasNext = endIndex < filtered.length;
    final nextCursor = pageItems.isNotEmpty ? pageItems.last.phone : null;

    return EnquiryPage(
      items: pageItems,
      cursor: nextCursor,
      hasNextPage: hasNext,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  @override
  Future<EnquiryItem?> getEnquiryByPhone(String phone) async {
    return _dataset.where((e) => e.phone == phone).firstOrNull;
  }

  @override
  Future<void> updateEnquiryStatus(String phone, bool status) async {}

  @override
  Future<void> updateWorkflow({
    required String phone,
    String? workflowStatus,
    String? adminNotes,
  }) async {}

  @override
  Future<void> deleteEnquiry(String phone) async {}

  static int _sortComparator(EnquiryItem a, EnquiryItem b) {
    if (a.createdAt == null && b.createdAt == null) {
      return b.phone.compareTo(a.phone);
    }
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    final cmp = b.createdAt!.compareTo(a.createdAt!);
    if (cmp != 0) return cmp;
    return b.phone.compareTo(a.phone);
  }
}

void main() {
  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  /// Generates 500 enquiries distributed across different ranges:
  /// - 001..100: 'Classes 1 – 7', active (true), 'new'
  /// - 101..200: 'Classes 8 – 10', active (true), 'contacted'
  /// - 201..300: 'Crash Course', archived (false), 'enrolled'
  /// - 301..400: 'Classes 1 – 7', archived (false), 'closed' (includes Record 350)
  /// - 401..500: 'Classes 8 – 10', active (true), 'enrolled' (includes Record 420)
  List<EnquiryItem> generate500Enquiries() {
    final baseTime = DateTime(2026, 11, 16, 12, 0);
    return List.generate(500, (index) {
      final num = index + 1;
      final numStr = num.toString().padLeft(3, '0');
      final phone = '9876500$numStr';

      String program;
      bool status;
      String workflowStatus;

      if (num <= 100) {
        program = 'Classes 1 – 7';
        status = true;
        workflowStatus = 'new';
      } else if (num <= 200) {
        program = 'Classes 8 – 10';
        status = true;
        workflowStatus = 'contacted';
      } else if (num <= 300) {
        program = 'Crash Course';
        status = false;
        workflowStatus = 'enrolled';
      } else if (num <= 400) {
        program = 'Classes 1 – 7';
        status = false;
        workflowStatus = 'closed';
      } else {
        program = 'Classes 8 – 10';
        status = true;
        workflowStatus = 'enrolled';
      }

      String name = 'Candidate $numStr';
      if (num == 350) {
        name = 'Candidate 350';
      } else if (num == 420) {
        name = 'Special Candidate 420';
      }

      return EnquiryItem(
        id: 'enq_$numStr',
        name: name,
        phone: phone,
        program: program,
        message: 'Message from candidate $numStr',
        status: status,
        workflowStatus: workflowStatus,
        createdAt: baseTime.subtract(Duration(minutes: index)),
      );
    });
  }

  group('Phase 4.13.1 — Collection-Wide Enquiry Search & Filtering Audit Tests', () {
    late List<EnquiryItem> dataset;
    late AuditDatasetEnquiryRepository repository;

    setUp(() {
      dataset = generate500Enquiries();
      repository = AuditDatasetEnquiryRepository(dataset);
    });

    test('1. Search for phone number belonging to record 350 out of 500 records',
        () async {
      // Record 350 phone: '9876500350'
      const filter = EnquiryFilter(searchQuery: '9876500350');
      final page = await repository.getEnquiriesPaginated(filter: filter);

      expect(page.items.length, 1);
      expect(page.items.first.phone, '9876500350');
      expect(page.items.first.name, 'Candidate 350');
      expect(page.hasNextPage, isFalse);
      expect(page.pageIndex, 1);
    });

    test('2. Search for candidate name belonging to record 420 out of 500 records',
        () async {
      // Record 420 name: 'Special Candidate 420'
      const filter = EnquiryFilter(searchQuery: 'Special Candidate 420');
      final page = await repository.getEnquiriesPaginated(filter: filter);

      expect(page.items.length, 1);
      expect(page.items.first.phone, '9876500420');
      expect(page.items.first.name, 'Special Candidate 420');
      expect(page.hasNextPage, isFalse);
    });

    test('3. Filter for a program where matching records exist only after record 100',
        () async {
      // 'Crash Course' records only exist at indices 201..300 (100 total matching records)
      const filter = EnquiryFilter(program: 'Crash Course');

      // Page 1
      final page1 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        pageIndex: 1,
        filter: filter,
      );

      expect(page1.items.length, 25);
      expect(page1.hasNextPage, isTrue);
      // All 25 items on Page 1 must be 'Crash Course'
      expect(page1.items.every((e) => e.program == 'Crash Course'), isTrue);
      expect(page1.items.first.phone, '9876500201');
      expect(page1.items.last.phone, '9876500225');

      // Page 2
      final page2 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        startAfterCursor: page1.cursor,
        pageIndex: 2,
        filter: filter,
      );

      expect(page2.items.length, 25);
      expect(page2.hasNextPage, isTrue);
      expect(page2.items.every((e) => e.program == 'Crash Course'), isTrue);
      expect(page2.items.first.phone, '9876500226');
      expect(page2.items.last.phone, '9876500250');

      // Page 3
      final page3 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        startAfterCursor: page2.cursor,
        pageIndex: 3,
        filter: filter,
      );
      expect(page3.items.length, 25);
      expect(page3.hasNextPage, isTrue);

      // Page 4 (Final 25 records: 276..300)
      final page4 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        startAfterCursor: page3.cursor,
        pageIndex: 4,
        filter: filter,
      );
      expect(page4.items.length, 25);
      expect(page4.hasNextPage, isFalse);
      expect(page4.items.last.phone, '9876500300');
    });

    test('4. Filter for archived enquiries where matching records exist on later pages',
        () async {
      // Records 201..400 are archived (200 records total), 1..200 are active
      const filter = EnquiryFilter(status: 'Archived');

      final page1 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        pageIndex: 1,
        filter: filter,
      );

      expect(page1.items.length, 25);
      expect(page1.hasNextPage, isTrue);
      // Zero active records must be present
      expect(page1.items.every((e) => e.status == false), isTrue);
      // Starts with the newest archived record (record 201)
      expect(page1.items.first.phone, '9876500201');
    });

    test('5. Filter for workflowStatus = enrolled where matching records exist on later pages',
        () async {
      // 'enrolled' records are 201..300 and 401..500 (200 records total)
      const filter = EnquiryFilter(workflowStatus: 'enrolled');

      final page1 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        pageIndex: 1,
        filter: filter,
      );

      expect(page1.items.length, 25);
      expect(page1.hasNextPage, isTrue);
      expect(page1.items.every((e) => e.workflowStatus == 'enrolled'), isTrue);
      // First enrolled record is 201
      expect(page1.items.first.phone, '9876500201');
    });

    test('6. Combine program, archived status, and workflow filters collection-wide',
        () async {
      // Only records 201..300 have:
      // program: 'Crash Course', status: 'Archived' (false), workflowStatus: 'enrolled'
      const filter = EnquiryFilter(
        program: 'Crash Course',
        status: 'Archived',
        workflowStatus: 'enrolled',
      );

      final page1 = await repository.getEnquiriesPaginated(
        pageSize: 25,
        pageIndex: 1,
        filter: filter,
      );

      expect(page1.items.length, 25);
      expect(page1.hasNextPage, isTrue);
      for (final item in page1.items) {
        expect(item.program, 'Crash Course');
        expect(item.status, isFalse);
        expect(item.workflowStatus, 'enrolled');
      }
    });

    test('7. Change a filter while viewing page 3 resets to Page 1',
        () async {
      final controller = EnquiryPaginationController(repository);

      // Wait until initial constructor load of Page 1 completes
      while (controller.state.isLoading) {
        await Future.delayed(Duration.zero);
      }

      // Initially on Page 1
      expect(controller.state.pageIndex, 1);

      // Advance to Page 2 then Page 3
      await controller.nextPage();
      expect(controller.state.pageIndex, 2);
      await controller.nextPage();
      expect(controller.state.pageIndex, 3);

      // Now apply filter for 'Classes 8 – 10'
      await controller.setFilter(const EnquiryFilter(program: 'Classes 8 – 10'));

      // Automatically resets to Page 1!
      expect(controller.state.pageIndex, 1);
      expect(controller.state.filter.program, 'Classes 8 – 10');
      expect(
        controller.state.currentPage?.items
            .every((e) => e.program == 'Classes 8 – 10'),
        isTrue,
      );
    });

    test('8. Navigate forward and backward after applying filters preserves cursor integrity',
        () async {
      final controller = EnquiryPaginationController(repository);

      // Wait until initial constructor load completes
      while (controller.state.isLoading) {
        await Future.delayed(Duration.zero);
      }

      // Apply filter for 'Classes 8 – 10' (records 101..200 and 401..500)
      await controller.setFilter(const EnquiryFilter(program: 'Classes 8 – 10'));
      expect(controller.state.pageIndex, 1);
      final page1FirstItem = controller.state.currentPage!.items.first;

      // Navigate forward to Page 2
      await controller.nextPage();
      expect(controller.state.pageIndex, 2);
      expect(controller.state.currentPage!.items.first.phone, isNot(page1FirstItem.phone));

      // Navigate backward to Page 1 (using cached page / cursor)
      await controller.previousPage();
      expect(controller.state.pageIndex, 1);
      expect(controller.state.currentPage!.items.first.phone, page1FirstItem.phone);
    });

    test('9. Filtering occurs before pagination: proves total dataset exceeds 100 records',
        () async {
      expect(dataset.length, 500);

      // Query for program 'Classes 1 – 7' (100 records in 1..100, 100 in 301..400 = 200 total)
      const filter = EnquiryFilter(program: 'Classes 1 – 7');
      final page1 = await repository.getEnquiriesPaginated(pageSize: 25, filter: filter);
      expect(page1.items.length, 25);
      expect(page1.hasNextPage, isTrue);

      // If filtering was applied after a 100-record query slice,
      // it would be impossible to access records in range 301..400.
      // Fetch through to page 5 (records 101-125 of matching subset, which is record 301+)
      dynamic cursor = page1.cursor;
      for (int i = 2; i <= 5; i++) {
        final page = await repository.getEnquiriesPaginated(
          pageSize: 25,
          startAfterCursor: cursor,
          pageIndex: i,
          filter: filter,
        );
        expect(page.items.every((e) => e.program == 'Classes 1 – 7'), isTrue);
        cursor = page.cursor;
      }
      expect(cursor, isNotNull);
    });

    test('10. Dashboard recent 5 enquiries remain unaffected by 500-record pagination',
        () async {
      final recent = await repository.getEnquiries(limit: 5);
      expect(recent.length, 5);
      expect(recent[0].phone, '9876500001');
      expect(recent[4].phone, '9876500005');
    });
  });
}
