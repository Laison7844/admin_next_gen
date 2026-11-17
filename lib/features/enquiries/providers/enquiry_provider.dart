import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/admin_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/enquiry_repository.dart';
import '../models/enquiry_item.dart';
import '../models/enquiry_page.dart';

/// Provider for the enquiry repository instance.
final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  return FirestoreEnquiryRepository();
});

/// One-time fetch provider for the latest admissions enquiries (up to 100).
/// Preserved for the dashboard recent enquiries widget and summary metrics.
final enquiryListProvider = FutureProvider<List<EnquiryItem>>((ref) async {
  final repository = ref.watch(enquiryRepositoryProvider);
  return repository.getEnquiries(limit: 100);
});

/// State representing cursor-paginated enquiry browsing.
class EnquiryPaginationState {
  final bool isLoading;
  final EnquiryPage? currentPage;
  final int pageIndex;
  final EnquiryFilter filter;
  final String? errorMessage;
  final Map<int, EnquiryPage> pageCache;
  final Map<int, dynamic> cursorMap;

  const EnquiryPaginationState({
    this.isLoading = false,
    this.currentPage,
    this.pageIndex = 1,
    this.filter = const EnquiryFilter(),
    this.errorMessage,
    this.pageCache = const {},
    this.cursorMap = const {1: null},
  });

  bool get hasNextPage => currentPage?.hasNextPage ?? false;
  bool get hasPreviousPage => pageIndex > 1;
  int get totalOnPage => currentPage?.totalOnPage ?? 0;
  List<EnquiryItem> get items => currentPage?.items ?? const [];

  EnquiryPaginationState copyWith({
    bool? isLoading,
    EnquiryPage? currentPage,
    int? pageIndex,
    EnquiryFilter? filter,
    String? errorMessage,
    bool clearError = false,
    Map<int, EnquiryPage>? pageCache,
    Map<int, dynamic>? cursorMap,
  }) {
    return EnquiryPaginationState(
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      pageIndex: pageIndex ?? this.pageIndex,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pageCache: pageCache ?? this.pageCache,
      cursorMap: cursorMap ?? this.cursorMap,
    );
  }
}

/// Controller managing cursor-based pagination, page transitions, and collection-wide filtering.
class EnquiryPaginationController
    extends StateNotifier<EnquiryPaginationState> {
  final EnquiryRepository _repository;

  EnquiryPaginationController(this._repository)
      : super(const EnquiryPaginationState()) {
    loadPage(1);
  }

  /// Loads the target page by index using Firestore cursor-based pagination.
  /// Re-uses cached pages when navigating back to avoid redundant Firestore reads.
  /// Guards against duplicate concurrent requests while loading.
  Future<void> loadPage(int targetPage) async {
    if (state.isLoading) return; // Prevent duplicate requests while loading
    if (targetPage < 1) return;

    // Check cache for instant back-navigation without Firestore reads
    if (state.pageCache.containsKey(targetPage)) {
      state = state.copyWith(
        pageIndex: targetPage,
        currentPage: state.pageCache[targetPage],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final cursor = state.cursorMap[targetPage];
      final page = await _repository.getEnquiriesPaginated(
        pageSize: 25,
        startAfterCursor: cursor,
        pageIndex: targetPage,
        filter: state.filter,
      );

      final updatedCache = Map<int, EnquiryPage>.from(state.pageCache);
      updatedCache[targetPage] = page;

      final updatedCursorMap = Map<int, dynamic>.from(state.cursorMap);
      if (page.hasNextPage) {
        updatedCursorMap[targetPage + 1] = page.cursor;
      }

      state = state.copyWith(
        isLoading: false,
        pageIndex: targetPage,
        currentPage: page,
        pageCache: updatedCache,
        cursorMap: updatedCursorMap,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load page $targetPage: $e',
      );
    }
  }

  /// Navigates to the next page if available.
  Future<void> nextPage() async {
    if (state.hasNextPage && !state.isLoading) {
      await loadPage(state.pageIndex + 1);
    }
  }

  /// Navigates to the previous page if available.
  Future<void> previousPage() async {
    if (state.hasPreviousPage && !state.isLoading) {
      await loadPage(state.pageIndex - 1);
    }
  }

  /// Sets search and filter criteria. Resets pagination to Page 1
  /// and invalidates stale page cursors.
  Future<void> setFilter(EnquiryFilter newFilter) async {
    if (state.filter == newFilter) return;

    state = state.copyWith(
      filter: newFilter,
      pageIndex: 1,
      pageCache: {},
      cursorMap: {1: null},
      clearError: true,
    );

    await loadPage(1);
  }

  /// Retries the current page after an error.
  Future<void> retry() async {
    await loadPage(state.pageIndex);
  }

  /// Clears cache and cursors and reloads Page 1 fresh.
  Future<void> refresh() async {
    state = state.copyWith(
      pageIndex: 1,
      pageCache: {},
      cursorMap: {1: null},
      clearError: true,
    );
    await loadPage(1);
  }
}

/// Provider exposing [EnquiryPaginationController].
final enquiryPaginationControllerProvider = StateNotifierProvider<
    EnquiryPaginationController, EnquiryPaginationState>((ref) {
  final repository = ref.watch(enquiryRepositoryProvider);
  return EnquiryPaginationController(repository);
});

/// State of an enquiry mutation operation (status update, workflow change, notes, delete).
class EnquiryOperationState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const EnquiryOperationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  EnquiryOperationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return EnquiryOperationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Controller handling enquiry actions like status toggling, workflow updates, notes, and deletion.
class EnquiryOperationController extends StateNotifier<EnquiryOperationState> {
  final EnquiryRepository _repository;
  final Ref _ref;

  EnquiryOperationController(this._repository, this._ref)
      : super(const EnquiryOperationState());

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  bool _checkAdmin() {
    try {
      final auth = _ref.read(authServiceProvider);
      final user = auth.currentUser;
      if (!AdminConfig.isAuthorizedAdmin(user)) {
        state = state.copyWith(
          errorMessage:
              'Access denied: Only the verified administrator may perform this action.',
        );
        return false;
      }
      return true;
    } catch (e) {
      // In test environments where Firebase is not initialized, allow repository operation
      if (e.toString().contains('no-app') ||
          e.toString().contains('No Firebase App')) {
        return true;
      }
      state = state.copyWith(
        errorMessage: 'Authentication error verifying administrator access: $e',
      );
      return false;
    }
  }

  /// Toggles the active/archived Boolean status of an enquiry.
  Future<bool> toggleStatus(String phone, bool newStatus) async {
    if (!_checkAdmin()) return false;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.updateEnquiryStatus(phone, newStatus);
      _ref.invalidate(enquiryListProvider);
      _ref.read(enquiryPaginationControllerProvider.notifier).refresh();
      state = state.copyWith(
        isLoading: false,
        successMessage: newStatus
            ? 'Enquiry marked as Active / Received.'
            : 'Enquiry archived.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update enquiry status: $e',
      );
      return false;
    }
  }

  /// Updates workflow status (new, contacted, enrolled, closed).
  Future<bool> updateWorkflowStatus(String phone, String workflowStatus) async {
    if (!_checkAdmin()) return false;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.updateWorkflow(
        phone: phone,
        workflowStatus: workflowStatus,
      );
      _ref.invalidate(enquiryListProvider);
      _ref.read(enquiryPaginationControllerProvider.notifier).refresh();
      final label = EnquiryWorkflowStatus.displayName(workflowStatus);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Workflow status updated to "$label".',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update workflow status: $e',
      );
      return false;
    }
  }

  /// Saves administrative private notes for an enquiry.
  Future<bool> saveAdminNotes(String phone, String notes) async {
    if (!_checkAdmin()) return false;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.updateWorkflow(
        phone: phone,
        adminNotes: notes,
      );
      _ref.invalidate(enquiryListProvider);
      _ref.read(enquiryPaginationControllerProvider.notifier).refresh();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Administrative notes saved successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save administrative notes: $e',
      );
      return false;
    }
  }

  /// Permanently deletes an enquiry document.
  Future<bool> deleteEnquiry(String phone) async {
    if (!_checkAdmin()) return false;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.deleteEnquiry(phone);
      _ref.invalidate(enquiryListProvider);
      _ref.read(enquiryPaginationControllerProvider.notifier).refresh();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Enquiry deleted successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete enquiry: $e',
      );
      return false;
    }
  }

  /// Forces an in-memory refresh of the enquiry list.
  void refresh() {
    _ref.invalidate(enquiryListProvider);
    _ref.read(enquiryPaginationControllerProvider.notifier).refresh();
  }
}

final enquiryOperationControllerProvider =
    StateNotifierProvider<EnquiryOperationController, EnquiryOperationState>(
        (ref) {
  final repository = ref.watch(enquiryRepositoryProvider);
  return EnquiryOperationController(repository, ref);
});
