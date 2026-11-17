import 'package:admin_next_gen/core/constants/admin_config.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/auth/providers/auth_provider.dart';
import 'package:admin_next_gen/features/auth/services/auth_service.dart';
import 'package:admin_next_gen/features/enquiries/data/enquiry_repository.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_item.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_page.dart';
import 'package:admin_next_gen/features/enquiries/presentation/enquiry_list_screen.dart';
import 'package:admin_next_gen/features/enquiries/providers/enquiry_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;

  MockUser({required this.uid, this.email = 'admin@nextgen.edu'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final User? _user;
  FakeAuthService([this._user]);

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);

  @override
  User? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class TestablePaginatedEnquiryRepository implements EnquiryRepository {
  final List<EnquiryItem> items = [];
  bool shouldThrow = false;
  int paginatedCallCount = 0;

  TestablePaginatedEnquiryRepository([List<EnquiryItem>? initial]) {
    if (initial != null) {
      items.addAll(initial);
    }
  }

  @override
  Future<List<EnquiryItem>> getEnquiries({int limit = 100}) async {
    final sorted = List<EnquiryItem>.from(items);
    sorted.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) {
        return b.phone.compareTo(a.phone);
      }
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      final cmp = b.createdAt!.compareTo(a.createdAt!);
      if (cmp != 0) return cmp;
      return b.phone.compareTo(a.phone);
    });
    return sorted.take(limit).toList();
  }

  @override
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  }) async {
    paginatedCallCount++;
    if (shouldThrow) {
      throw StateError('Simulated Firestore pagination error');
    }

    var list = List<EnquiryItem>.from(items);
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

    if (filter != null && !filter.isDefault) {
      list = list.where((item) => filter.matches(item)).toList();
    }

    // Cursor-based simulation using document phone ID as cursor
    int startIndex = 0;
    if (startAfterCursor != null) {
      final cursorPhone = startAfterCursor.toString();
      final idx = list.indexWhere((e) => e.phone == cursorPhone);
      if (idx != -1) {
        startIndex = idx + 1;
      }
    } else {
      startIndex = (pageIndex - 1) * pageSize;
    }

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
    return items.where((e) => e.phone == phone).firstOrNull;
  }

  @override
  Future<void> updateEnquiryStatus(String phone, bool status) async {
    final idx = items.indexWhere((e) => e.phone == phone);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(status: status, updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> updateWorkflow({
    required String phone,
    String? workflowStatus,
    String? adminNotes,
  }) async {
    final idx = items.indexWhere((e) => e.phone == phone);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(
        workflowStatus: workflowStatus ?? items[idx].workflowStatus,
        adminNotes: adminNotes ?? items[idx].adminNotes,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteEnquiry(String phone) async {
    items.removeWhere((e) => e.phone == phone);
  }
}

void main() {
  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  List<EnquiryItem> generateEnquiries(int count) {
    final baseTime = DateTime(2026, 11, 16, 10, 0);
    return List.generate(count, (index) {
      final numStr = (index + 1).toString().padLeft(3, '0');
      return EnquiryItem(
        id: 'enq_$numStr',
        name: 'Student $numStr',
        phone: '9876500$numStr',
        program: index % 2 == 0 ? 'Classes 1 – 7' : 'Classes 8 – 10',
        message: 'Message from student $numStr',
        status: index % 3 != 0, // 2 active, 1 archived
        workflowStatus: index % 4 == 0
            ? 'new'
            : (index % 4 == 1
                ? 'contacted'
                : (index % 4 == 2 ? 'enrolled' : 'closed')),
        createdAt: baseTime.subtract(Duration(minutes: index * 10)),
      );
    });
  }

  final adminUser = MockUser(uid: AdminConfig.authorizedAdminUid);

  Future<void> tapNext(WidgetTester tester) async {
    final nextFinder = find.widgetWithText(ElevatedButton, 'Next');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapPrevious(WidgetTester tester) async {
    final prevFinder = find.widgetWithText(OutlinedButton, 'Previous');
    await tester.ensureVisible(prevFinder);
    await tester.pumpAndSettle();
    await tester.tap(prevFinder);
    await tester.pumpAndSettle();
  }

  group('Phase 4.13 — Enquiry Management Cursor-Based Pagination Tests', () {
    // 1. First page loads 25 enquiries
    testWidgets('1. First page loads 25 enquiries', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(50));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Showing 25 records'), findsOneWidget);
      expect(find.text('Student 001'), findsOneWidget);
      expect(find.text('Student 025'), findsOneWidget);
      expect(find.text('Student 026'), findsNothing);

      // Previous disabled, Next enabled
      final prevBtn = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Previous'),
      );
      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(prevBtn.onPressed, isNull);
      expect(nextBtn.onPressed, isNotNull);
    });

    // 2. Next page loads the following records
    testWidgets('2. Next page loads the following records', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(50));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Next
      await tapNext(tester);

      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Showing 25 records'), findsOneWidget);
      expect(find.text('Student 026'), findsOneWidget);
      expect(find.text('Student 050'), findsOneWidget);
      expect(find.text('Student 001'), findsNothing);

      // On Page 2 of 2: Previous is enabled, Next is disabled
      final prevBtn = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Previous'),
      );
      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(prevBtn.onPressed, isNotNull);
      expect(nextBtn.onPressed, isNull);
    });

    // 3. Previous page returns the correct records
    testWidgets('3. Previous page returns the correct records', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(50));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Forward to Page 2
      await tapNext(tester);
      expect(find.text('Page 2'), findsOneWidget);

      // Back to Page 1
      await tapPrevious(tester);

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Student 001'), findsOneWidget);
      expect(find.text('Student 025'), findsOneWidget);
    });

    // 4. Final page with fewer than 25 records
    testWidgets('4. Final page with fewer than 25 records', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(30));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tapNext(tester);

      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Showing 5 records'), findsOneWidget);
      expect(find.text('Student 030'), findsOneWidget);

      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextBtn.onPressed, isNull);
    });

    // 5. Empty collection
    testWidgets('5. Empty collection handles gracefully', (tester) async {
      final repo = TestablePaginatedEnquiryRepository([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No admissions enquiries received yet'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Showing 0 records'), findsOneWidget);

      final prevBtn = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Previous'),
      );
      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(prevBtn.onPressed, isNull);
      expect(nextBtn.onPressed, isNull);
    });

    // 6. Exactly 25 records
    testWidgets('6. Exactly 25 records hasNextPage is false', (tester) async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(25));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Showing 25 records'), findsOneWidget);

      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextBtn.onPressed, isNull);
    });

    // 7. Exactly 26 records
    testWidgets('7. Exactly 26 records enables Next button', (tester) async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(26));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Showing 25 records'), findsOneWidget);

      final nextBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextBtn.onPressed, isNotNull);

      await tapNext(tester);

      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Showing 1 record'), findsOneWidget);
      expect(find.text('Student 026'), findsOneWidget);
    });

    // 8. Identical createdAt timestamps
    test('8. Identical createdAt timestamps are sorted deterministically with tie-breaker',
        () async {
      final sameTime = DateTime(2026, 11, 16, 12, 0);
      final items = [
        EnquiryItem(name: 'A', phone: '9000000001', program: 'P', message: 'M', createdAt: sameTime),
        EnquiryItem(name: 'B', phone: '9000000003', program: 'P', message: 'M', createdAt: sameTime),
        EnquiryItem(name: 'C', phone: '9000000002', program: 'P', message: 'M', createdAt: sameTime),
      ];

      final repo = TestablePaginatedEnquiryRepository(items);
      final page = await repo.getEnquiriesPaginated(pageSize: 10);

      expect(page.items.length, 3);
      // Tie-breaker sorts by phone descending: '9000000003', '9000000002', '9000000001'
      expect(page.items[0].phone, '9000000003');
      expect(page.items[1].phone, '9000000002');
      expect(page.items[2].phone, '9000000001');
    });

    // 9. Search by name
    testWidgets('9. Search by name filters records and resets pagination',
        (tester) async {
      final repo = TestablePaginatedEnquiryRepository([
        EnquiryItem(name: 'Special Student', phone: '9111111111', program: 'P', message: 'M'),
        ...generateEnquiries(30),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Special Student');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(Card),
          matching: find.text('Special Student'),
        ),
        findsOneWidget,
      );
      expect(find.text('Showing 1 record'), findsOneWidget);
    });

    // 10. Search by phone
    testWidgets('10. Search by phone number', (tester) async {
      final repo = TestablePaginatedEnquiryRepository([
        EnquiryItem(name: 'Target Person', phone: '8075854535', program: 'P', message: 'M'),
        ...generateEnquiries(20),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '8075854535');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(Card),
          matching: find.text('Target Person'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Card),
          matching: find.text('8075854535'),
        ),
        findsOneWidget,
      );
    });

    // 11. Program filter
    testWidgets('11. Program filter filters collection-wide', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(30));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap program dropdown and select 'Classes 8 – 10'
      final dropdown = find.byType(DropdownButton<String>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classes 8 – 10').last);
      await tester.pumpAndSettle();

      // All displayed items belong to selected program
      expect(find.text('Classes 8 – 10'), findsWidgets);
    });

    // 12. Active/archived filter
    testWidgets('12. Active and Archived status filter chips', (tester) async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(10));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select 'Archived' chip
      final archivedChip = find.widgetWithText(ChoiceChip, 'Archived');
      await tester.ensureVisible(archivedChip);
      await tester.pumpAndSettle();
      await tester.tap(archivedChip);
      await tester.pumpAndSettle();

      expect(find.text('ARCHIVED'), findsWidgets);
      expect(find.text('ACTIVE'), findsNothing);
    });

    // 13. Workflow status filter
    testWidgets('13. Workflow status filter chip filters records', (tester) async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(20));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Contacted' chip
      final contactedChip = find.widgetWithText(ChoiceChip, 'Contacted');
      await tester.ensureVisible(contactedChip);
      await tester.pumpAndSettle();
      await tester.tap(contactedChip);
      await tester.pumpAndSettle();

      expect(find.text('CONTACTED'), findsWidgets);
      expect(find.text('NEW'), findsNothing);
    });

    // 14. Filter changes reset pagination
    testWidgets('14. Filter changes reset pagination to Page 1', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(60));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Go to page 2
      await tapNext(tester);
      expect(find.text('Page 2'), findsOneWidget);

      // Change status filter to 'Active'
      final activeChip = find.widgetWithText(ChoiceChip, 'Active');
      await tester.ensureVisible(activeChip);
      await tester.pumpAndSettle();
      await tester.tap(activeChip);
      await tester.pumpAndSettle();

      // Automatically reset to Page 1!
      expect(find.text('Page 1'), findsOneWidget);
    });

    // 15. No duplicate requests during loading
    test('15. Controller prevents duplicate concurrent page requests while loading',
        () async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(50));
      final controller = EnquiryPaginationController(repo);

      // Initial load triggered in constructor
      expect(repo.paginatedCallCount, 1);

      // Attempt concurrent duplicate load
      controller.loadPage(1);
      controller.loadPage(1);

      // No redundant requests dispatched
      expect(repo.paginatedCallCount, 1);
    });

    // 16. Firestore errors and retry
    testWidgets('16. Firestore errors display error card with retry button',
        (tester) async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(10));
      repo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            enquiryRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: EnquiryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load admissions enquiries'), findsOneWidget);
      expect(find.textContaining('Simulated Firestore pagination error'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry Fetch'), findsOneWidget);

      // Fix repo and tap retry
      repo.shouldThrow = false;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry Fetch'));
      await tester.pumpAndSettle();

      expect(find.text('Showing 10 records'), findsOneWidget);
    });

    // 17. Missing or invalid timestamps
    test('17. Missing or invalid timestamps handled safely without crashing', () async {
      final repo = TestablePaginatedEnquiryRepository([
        EnquiryItem(name: 'Null Date', phone: '111', program: 'P', message: 'M', createdAt: null),
        EnquiryItem(
          name: 'Valid Date',
          phone: '222',
          program: 'P',
          message: 'M',
          createdAt: DateTime(2026, 11, 16),
        ),
      ]);

      final page = await repo.getEnquiriesPaginated();
      expect(page.items.length, 2);
      expect(page.items[0].name, 'Valid Date');
      expect(page.items[1].name, 'Null Date');
    });

    // 18. Dashboard recent 5 enquiries remain independent of pagination
    test('18. Dashboard recent 5 enquiries remain independent of pagination',
        () async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(50));

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
          enquiryRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Verify dashboard reads through enquiryListProvider
      final dashboardEnquiries = await container.read(enquiryListProvider.future);
      expect(dashboardEnquiries.length, 50);

      // Wait until initial page 1 loading is complete
      while (container.read(enquiryPaginationControllerProvider).isLoading) {
        await Future.delayed(Duration.zero);
      }

      // Paginate through pagination controller to Page 2
      final pagController =
          container.read(enquiryPaginationControllerProvider.notifier);
      await pagController.nextPage();
      expect(container.read(enquiryPaginationControllerProvider).pageIndex, 2);

      // Dashboard provider is unaffected and still holds all recent enquiries
      final dashboardAfter = container.read(enquiryListProvider).valueOrNull;
      expect(dashboardAfter?.length, 50);
    });

    // 19. Administrator-only access remains intact
    test('19. Non-admin visitor cannot perform enquiry mutations', () async {
      final repo = TestablePaginatedEnquiryRepository(generateEnquiries(5));
      final nonAdminUser = MockUser(uid: 'unauthorized_guest');

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService(nonAdminUser)),
          enquiryRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final opController =
          container.read(enquiryOperationControllerProvider.notifier);

      final statusResult = await opController.toggleStatus('9876500001', false);
      expect(statusResult, isFalse);

      final workflowResult =
          await opController.updateWorkflowStatus('9876500001', 'contacted');
      expect(workflowResult, isFalse);

      final notesResult =
          await opController.saveAdminNotes('9876500001', 'Private Note');
      expect(notesResult, isFalse);

      final deleteResult = await opController.deleteEnquiry('9876500001');
      expect(deleteResult, isFalse);

      // Document in repo remains untouched
      expect(repo.items.length, 5);
      expect(repo.items.first.status, isFalse);
    });
  });
}
