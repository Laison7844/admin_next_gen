import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/enquiries/data/enquiry_repository.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_item.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_page.dart';
import 'package:admin_next_gen/features/enquiries/presentation/enquiry_list_screen.dart';
import 'package:admin_next_gen/features/enquiries/presentation/widgets/enquiry_detail_dialog.dart';
import 'package:admin_next_gen/features/enquiries/providers/enquiry_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeEnquiryRepository implements EnquiryRepository {
  final Map<String, EnquiryItem> items = {};

  FakeEnquiryRepository([List<EnquiryItem>? initial]) {
    if (initial != null) {
      for (final item in initial) {
        items[item.phone] = item;
      }
    }
  }

  @override
  Future<List<EnquiryItem>> getEnquiries({int limit = 100}) async {
    final list = items.values.toList();
    list.sort((a, b) {
      final dtA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });
    return list.take(limit).toList();
  }

  @override
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  }) async {
    var list = items.values.toList();
    list.sort((a, b) {
      final dtA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = dtB.compareTo(dtA);
      if (cmp != 0) return cmp;
      return b.phone.compareTo(a.phone);
    });

    if (filter != null && !filter.isDefault) {
      list = list.where((item) => filter.matches(item)).toList();
    }

    final startIndex = (pageIndex - 1) * pageSize;
    if (startIndex >= list.length) {
      return EnquiryPage(
        items: const [],
        cursor: null,
        hasNextPage: false,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
    }

    final endIndex = (startIndex + pageSize).clamp(0, list.length);
    final pageItems = list.sublist(startIndex, endIndex);
    final hasNext = endIndex < list.length;

    return EnquiryPage(
      items: pageItems,
      cursor: pageItems.isNotEmpty ? pageItems.last.phone : null,
      hasNextPage: hasNext,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  @override
  Future<EnquiryItem?> getEnquiryByPhone(String phone) async => items[phone];

  @override
  Future<void> updateEnquiryStatus(String phone, bool status) async {
    final existing = items[phone];
    if (existing != null) {
      items[phone] = existing.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateWorkflow({
    required String phone,
    String? workflowStatus,
    String? adminNotes,
  }) async {
    final existing = items[phone];
    if (existing != null) {
      items[phone] = existing.copyWith(
        workflowStatus: workflowStatus ?? existing.workflowStatus,
        adminNotes: adminNotes ?? existing.adminNotes,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteEnquiry(String phone) async {
    items.remove(phone);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('EnquiryItem Model Tests', () {
    test('Correctly parses from Firestore data with Timestamp and workflow fields', () {
      final now = DateTime(2026, 11, 13, 14, 30);
      final timestamp = Timestamp.fromDate(now);

      final raw = {
        'id': 'enq_123',
        'name': 'Priya Sharma',
        'phone': '9876543210',
        'program': 'Class 10 Board Excellence',
        'message': 'Interested in morning batch details.',
        'status': true,
        'workflowStatus': 'contacted',
        'adminNotes': 'Parent called to discuss timings.',
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      final enquiry = EnquiryItem.fromFirestore(raw, '9876543210');

      expect(enquiry.id, 'enq_123');
      expect(enquiry.name, 'Priya Sharma');
      expect(enquiry.phone, '9876543210');
      expect(enquiry.program, 'Class 10 Board Excellence');
      expect(enquiry.message, 'Interested in morning batch details.');
      expect(enquiry.status, isTrue);
      expect(enquiry.workflowStatus, 'contacted');
      expect(enquiry.adminNotes, 'Parent called to discuss timings.');
      expect(enquiry.createdAt, now);
      expect(enquiry.updatedAt, now);
    });

    test('Falls back gracefully for missing fields', () {
      final raw = <String, dynamic>{
        'name': 'Rahul Verma',
      };

      final enquiry = EnquiryItem.fromFirestore(raw, '9988776655');

      expect(enquiry.id, '1');
      expect(enquiry.name, 'Rahul Verma');
      expect(enquiry.phone, '9988776655');
      expect(enquiry.program, '');
      expect(enquiry.message, '');
      expect(enquiry.status, isFalse); // null is not true
      expect(enquiry.workflowStatus, 'new'); // defaults to new
      expect(enquiry.adminNotes, ''); // defaults to empty
      expect(enquiry.createdAt, isNull);
      expect(enquiry.updatedAt, isNull);
    });

    test('toFirestore preserves schema types and workflow fields', () {
      final now = DateTime(2026, 11, 13, 14, 30);
      final enquiry = EnquiryItem(
        id: '1',
        name: 'Anita Roy',
        phone: '9123456780',
        program: 'Foundation Course (Classes 6-8)',
        message: 'Looking for trial classes.',
        status: true,
        workflowStatus: 'enrolled',
        adminNotes: 'Enrolled in Batch A',
        createdAt: now,
        updatedAt: now,
      );

      final map = enquiry.toFirestore();

      expect(map['name'], 'Anita Roy');
      expect(map['phone'], '9123456780');
      expect(map['status'], isTrue);
      expect(map['status'], isA<bool>());
      expect(map['workflowStatus'], 'enrolled');
      expect(map['adminNotes'], 'Enrolled in Batch A');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('EnquiryWorkflowStatus helper normalizes and displays labels', () {
      expect(EnquiryWorkflowStatus.all, ['new', 'contacted', 'enrolled', 'closed']);
      expect(EnquiryWorkflowStatus.normalize(null), 'new');
      expect(EnquiryWorkflowStatus.normalize(''), 'new');
      expect(EnquiryWorkflowStatus.normalize('UNKNOWN'), 'new');
      expect(EnquiryWorkflowStatus.normalize('Contacted'), 'contacted');
      expect(EnquiryWorkflowStatus.normalize('ENROLLED'), 'enrolled');
      expect(EnquiryWorkflowStatus.normalize('closed'), 'closed');

      expect(EnquiryWorkflowStatus.displayName('new'), 'New');
      expect(EnquiryWorkflowStatus.displayName('contacted'), 'Contacted');
      expect(EnquiryWorkflowStatus.displayName('enrolled'), 'Enrolled');
      expect(EnquiryWorkflowStatus.displayName('closed'), 'Closed');
    });
  });

  group('EnquiryRepository Operations Tests', () {
    test('getEnquiries returns items sorted newest first', () async {
      final dt1 = DateTime(2026, 11, 10);
      final dt2 = DateTime(2026, 11, 12);
      final dt3 = DateTime(2026, 11, 13);

      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Old User',
          phone: '1111111111',
          program: 'Course A',
          message: 'Old',
          createdAt: dt1,
        ),
        EnquiryItem(
          name: 'Newest User',
          phone: '3333333333',
          program: 'Course C',
          message: 'Newest',
          createdAt: dt3,
        ),
        EnquiryItem(
          name: 'Middle User',
          phone: '2222222222',
          program: 'Course B',
          message: 'Middle',
          createdAt: dt2,
        ),
      ]);

      final list = await repo.getEnquiries();
      expect(list.length, 3);
      expect(list[0].name, 'Newest User');
      expect(list[1].name, 'Middle User');
      expect(list[2].name, 'Old User');
    });

    test('updateEnquiryStatus updates status flag', () async {
      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Student',
          phone: '9876543210',
          program: 'Abacus',
          message: 'Hello',
          status: true,
        ),
      ]);

      await repo.updateEnquiryStatus('9876543210', false);
      final updated = await repo.getEnquiryByPhone('9876543210');
      expect(updated?.status, isFalse);
    });

    test('updateWorkflow updates workflowStatus and adminNotes', () async {
      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Student',
          phone: '9876543210',
          program: 'Abacus',
          message: 'Hello',
          workflowStatus: 'new',
          adminNotes: '',
        ),
      ]);

      await repo.updateWorkflow(
        phone: '9876543210',
        workflowStatus: 'contacted',
        adminNotes: 'Called on Monday',
      );

      final updated = await repo.getEnquiryByPhone('9876543210');
      expect(updated?.workflowStatus, 'contacted');
      expect(updated?.adminNotes, 'Called on Monday');
      expect(updated?.updatedAt, isNotNull);
    });

    test('deleteEnquiry removes document', () async {
      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Spam Lead',
          phone: '9999999999',
          program: 'Test',
          message: 'Spam',
        ),
      ]);

      await repo.deleteEnquiry('9999999999');
      final deleted = await repo.getEnquiryByPhone('9999999999');
      expect(deleted, isNull);
    });
  });

  group('Enquiry UI & Filtering Tests', () {
    testWidgets('EnquiryListScreen renders empty state when no enquiries',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeEnquiryRepository([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admissions Enquiries'), findsOneWidget);
      expect(find.text('Loaded Enquiries'), findsOneWidget);
      expect(find.text('No admissions enquiries received yet'), findsOneWidget);
    });

    testWidgets('EnquiryListScreen displays metric cards and cards for loaded enquiries',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Kavita Das',
          phone: '9876500001',
          program: 'Secondary School (Classes 9-10)',
          message: 'Need fee schedule and timing.',
          status: true,
          workflowStatus: 'new',
          createdAt: now,
        ),
        EnquiryItem(
          name: 'Vikram Joshi',
          phone: '9876500002',
          program: 'Spoken English & Communication',
          message: 'Weekend batch preferred.',
          status: false,
          workflowStatus: 'contacted',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Notice banner
      expect(
        find.text('Showing latest 100 admissions enquiries. Statistics reflect loaded records.'),
        findsOneWidget,
      );

      // Metrics
      expect(find.text('Loaded Enquiries'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2)); // totalCount = 2, programs.length = 2
      expect(find.text('1'), findsNWidgets(2)); // activeCount = 1, recentCount = 1

      // Cards
      expect(find.text('Kavita Das'), findsOneWidget);
      expect(find.text('9876500001'), findsOneWidget);
      expect(find.text('Vikram Joshi'), findsOneWidget);
      expect(find.text('9876500002'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);

      // Workflow Badges
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('CONTACTED'), findsOneWidget);
    });

    testWidgets('Workflow filter chips filter list by workflow status', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Lead One',
          phone: '1111111111',
          program: 'Course A',
          message: 'Msg 1',
          workflowStatus: 'new',
        ),
        EnquiryItem(
          name: 'Lead Two',
          phone: '2222222222',
          program: 'Course B',
          message: 'Msg 2',
          workflowStatus: 'contacted',
        ),
        EnquiryItem(
          name: 'Lead Three',
          phone: '3333333333',
          program: 'Course C',
          message: 'Msg 3',
          workflowStatus: 'enrolled',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lead One'), findsOneWidget);
      expect(find.text('Lead Two'), findsOneWidget);
      expect(find.text('Lead Three'), findsOneWidget);

      // Tap Contacted chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Contacted'));
      await tester.pumpAndSettle();

      expect(find.text('Lead Two'), findsOneWidget);
      expect(find.text('Lead One'), findsNothing);
      expect(find.text('Lead Three'), findsNothing);

      // Tap Enrolled chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Enrolled'));
      await tester.pumpAndSettle();

      expect(find.text('Lead Three'), findsOneWidget);
      expect(find.text('Lead Two'), findsNothing);

      // Tap All chip for workflow (index 1 of 'All' choice chips)
      await tester.tap(find.widgetWithText(ChoiceChip, 'All').at(1));
      await tester.pumpAndSettle();

      expect(find.text('Lead One'), findsOneWidget);
      expect(find.text('Lead Two'), findsOneWidget);
      expect(find.text('Lead Three'), findsOneWidget);
    });

    testWidgets('Search filters by name and phone number', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Aarav Mehta',
          phone: '9111111111',
          program: 'Class 10',
          message: 'Query 1',
        ),
        EnquiryItem(
          name: 'Sunita Rao',
          phone: '9222222222',
          program: 'Class 8',
          message: 'Query 2',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search by name "Sunita"
      await tester.enterText(find.byType(TextField), 'Sunita');
      await tester.pumpAndSettle();

      expect(find.text('Sunita Rao'), findsOneWidget);
      expect(find.text('Aarav Mehta'), findsNothing);

      // Search by phone "9111"
      await tester.enterText(find.byType(TextField), '9111');
      await tester.pumpAndSettle();

      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('Sunita Rao'), findsNothing);
    });

    testWidgets('Detail dialog allows updating workflow status, admin notes, and archive toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Deepak Kumar',
          phone: '9333333333',
          program: 'Foundation Course',
          message: 'Looking for 1-to-1 care tutoring.',
          status: true,
          workflowStatus: 'new',
          adminNotes: 'Initial note',
          createdAt: DateTime(2026, 11, 13, 10, 0),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open detail dialog
      await tester.tap(find.byTooltip('View Details'));
      await tester.pumpAndSettle();

      expect(find.byType(EnquiryDetailDialog), findsOneWidget);
      expect(find.text('Admissions Enquiry & Workflow Details'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EnquiryDetailDialog),
          matching: find.text('Looking for 1-to-1 care tutoring.'),
        ),
        findsOneWidget,
      );

      // Change workflow status in dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contacted').last);
      await tester.pumpAndSettle();

      // Tap "Save Status"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Status'));
      await tester.pumpAndSettle();

      expect(repo.items['9333333333']?.workflowStatus, 'contacted');

      // Edit admin notes
      final notesField = find.widgetWithText(TextFormField, 'Initial note');
      await tester.enterText(notesField, 'Follow-up call completed on Wednesday');
      await tester.pumpAndSettle();

      // Tap "Save Notes"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Notes'));
      await tester.pumpAndSettle();

      expect(repo.items['9333333333']?.adminNotes, 'Follow-up call completed on Wednesday');

      // Tap Archive action
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      // Status in repository should now be false
      expect(repo.items['9333333333']?.status, isFalse);
    });

    testWidgets('Delete action shows confirmation dialog and deletes item',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeEnquiryRepository([
        EnquiryItem(
          name: 'Spam Sender',
          phone: '9444444444',
          program: 'None',
          message: 'Spam link',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spam Sender'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byTooltip('Delete Enquiry'));
      await tester.pumpAndSettle();

      expect(find.text('Permanently Delete Enquiry?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Permanently'));
      await tester.pumpAndSettle();

      // Item should be deleted from repository
      expect(repo.items.containsKey('9444444444'), isFalse);
      expect(find.text('Spam Sender'), findsNothing);
    });
  });
}
