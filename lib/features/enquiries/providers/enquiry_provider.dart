import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/enquiry_repository.dart';
import '../models/enquiry_item.dart';

/// Provider for the enquiry repository instance.
final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  return FirestoreEnquiryRepository();
});

/// One-time fetch provider for the latest admissions enquiries.
/// Avoids persistent real-time listener bandwidth.
final enquiryListProvider = FutureProvider<List<EnquiryItem>>((ref) async {
  final repository = ref.watch(enquiryRepositoryProvider);
  return repository.getEnquiries();
});

/// State of an enquiry mutation operation (update status or delete).
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

/// Controller handling enquiry actions like status toggling and deletion.
class EnquiryOperationController extends StateNotifier<EnquiryOperationState> {
  final EnquiryRepository _repository;
  final Ref _ref;

  EnquiryOperationController(this._repository, this._ref)
      : super(const EnquiryOperationState());

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Toggles the active/archived status of an enquiry.
  Future<bool> toggleStatus(String phone, bool newStatus) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.updateEnquiryStatus(phone, newStatus);
      _ref.invalidate(enquiryListProvider);
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

  /// Permanently deletes an enquiry document.
  Future<bool> deleteEnquiry(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.deleteEnquiry(phone);
      _ref.invalidate(enquiryListProvider);
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
  }
}

final enquiryOperationControllerProvider =
    StateNotifierProvider<EnquiryOperationController, EnquiryOperationState>(
        (ref) {
  final repository = ref.watch(enquiryRepositoryProvider);
  return EnquiryOperationController(repository, ref);
});

