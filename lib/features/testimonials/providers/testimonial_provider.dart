import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/providers/content_provider.dart';
import '../data/testimonial_repository.dart';
import '../models/testimonial_item.dart';

/// Provider for the [TestimonialRepository].
final testimonialRepositoryProvider = Provider<TestimonialRepository>((ref) {
  final contentRepo = ref.watch(contentRepositoryProvider);
  return FirestoreTestimonialRepository(contentRepo: contentRepo);
});

/// One-time fetch provider for the full list of testimonials.
final testimonialsListProvider =
    FutureProvider<List<TestimonialItem>>((ref) async {
  final repo = ref.watch(testimonialRepositoryProvider);
  return repo.getTestimonials();
});

/// Filter tabs for testimonials view.
enum TestimonialFilter {
  all('All'),
  published('Published'),
  draft('Draft'),
  featured('Featured');

  final String label;
  const TestimonialFilter(this.label);
}

/// Currently active filter tab.
final testimonialFilterProvider =
    StateProvider<TestimonialFilter>((ref) => TestimonialFilter.all);

/// Current search query.
final testimonialSearchQueryProvider = StateProvider<String>((ref) => '');

/// Computed provider that applies active filter tab and search query.
final filteredTestimonialsProvider =
    Provider<AsyncValue<List<TestimonialItem>>>((ref) {
  final testimonialsAsync = ref.watch(testimonialsListProvider);
  final filter = ref.watch(testimonialFilterProvider);
  final query = ref.watch(testimonialSearchQueryProvider).trim().toLowerCase();

  return testimonialsAsync.whenData((items) {
    return items.where((item) {
      // 1. Filter tab check
      switch (filter) {
        case TestimonialFilter.published:
          if (!item.isPublished) return false;
          break;
        case TestimonialFilter.draft:
          if (item.isPublished) return false;
          break;
        case TestimonialFilter.featured:
          if (!item.isFeatured) return false;
          break;
        case TestimonialFilter.all:
          break;
      }

      // 2. Search query check
      if (query.isNotEmpty) {
        final matchesName = item.personName.toLowerCase().contains(query);
        final matchesRole = item.role.toLowerCase().contains(query);
        final matchesProgram = (item.program ?? '').toLowerCase().contains(query);
        final matchesText = item.testimonialText.toLowerCase().contains(query);
        if (!matchesName && !matchesRole && !matchesProgram && !matchesText) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

/// Metrics summary for the dashboard cards
class TestimonialMetrics {
  final int total;
  final int published;
  final int drafts;
  final int featured;

  const TestimonialMetrics({
    this.total = 0,
    this.published = 0,
    this.drafts = 0,
    this.featured = 0,
  });
}

final testimonialMetricsProvider = Provider<TestimonialMetrics>((ref) {
  final asyncVal = ref.watch(testimonialsListProvider);
  return asyncVal.maybeWhen(
    data: (items) {
      int pub = 0;
      int draft = 0;
      int feat = 0;
      for (final item in items) {
        if (item.isPublished) pub++;
        if (!item.isPublished) draft++;
        if (item.isFeatured) feat++;
      }
      return TestimonialMetrics(
        total: items.length,
        published: pub,
        drafts: draft,
        featured: feat,
      );
    },
    orElse: () => const TestimonialMetrics(),
  );
});

/// Operation state for mutations
class TestimonialOperationState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const TestimonialOperationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  TestimonialOperationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TestimonialOperationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TestimonialOperationController
    extends StateNotifier<TestimonialOperationState> {
  final TestimonialRepository _repository;
  final Ref _ref;

  TestimonialOperationController(this._repository, this._ref)
      : super(const TestimonialOperationState());

  void clearMessages() {
    state = const TestimonialOperationState();
  }

  Future<bool> saveTestimonial(TestimonialItem item) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.saveDraft(item);
      _ref.invalidate(testimonialsListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Saved draft for "${item.personName}" successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save testimonial: $e',
      );
      return false;
    }
  }

  Future<bool> publish(String id, {DateTime? expectedUpdatedAt}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.publish(id, expectedUpdatedAt: expectedUpdatedAt);
      _ref.invalidate(testimonialsListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Testimonial published live successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to publish testimonial: $e',
      );
      return false;
    }
  }

  Future<bool> unpublish(String id) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.unpublish(id);
      _ref.invalidate(testimonialsListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Testimonial unpublished. Draft preserved in CMS.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to unpublish testimonial: $e',
      );
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.delete(id);
      _ref.invalidate(testimonialsListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Testimonial permanently deleted.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete testimonial: $e',
      );
      return false;
    }
  }

  Future<bool> toggleFeatured(TestimonialItem item) async {
    final updated = item.copyWith(
      isFeatured: !item.isFeatured,
      updatedAt: DateTime.now(),
      hasUnpublishedChanges: true,
    );
    return saveTestimonial(updated);
  }

  Future<bool> updateDisplayOrder(TestimonialItem item, int newOrder) async {
    if (item.displayOrder == newOrder) return true;
    final updated = item.copyWith(
      displayOrder: newOrder,
      updatedAt: DateTime.now(),
      hasUnpublishedChanges: true,
    );
    return saveTestimonial(updated);
  }
}

final testimonialOperationControllerProvider = StateNotifierProvider<
    TestimonialOperationController, TestimonialOperationState>((ref) {
  final repo = ref.watch(testimonialRepositoryProvider);
  return TestimonialOperationController(repo, ref);
});

