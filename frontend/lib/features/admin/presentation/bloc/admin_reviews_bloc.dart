import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../reviews/data/models/review_model.dart';
import '../../data/repositories/admin_repository.dart';

// ==================== EVENTS ====================

abstract class AdminReviewsEvent extends Equatable {
  const AdminReviewsEvent();

  @override
  List<Object?> get props => [];
}

class AdminReviewsLoadPending extends AdminReviewsEvent {
  final int page;

  const AdminReviewsLoadPending({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class AdminReviewsLoadReported extends AdminReviewsEvent {
  final int page;

  const AdminReviewsLoadReported({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class AdminReviewsLoadMore extends AdminReviewsEvent {}

class AdminReviewsRefresh extends AdminReviewsEvent {}

class AdminReviewsSearch extends AdminReviewsEvent {
  final String query;

  const AdminReviewsSearch({required this.query});

  @override
  List<Object?> get props => [query];
}

class AdminReviewApprove extends AdminReviewsEvent {
  final String reviewId;

  const AdminReviewApprove({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class AdminReviewReject extends AdminReviewsEvent {
  final String reviewId;
  final String reason;

  const AdminReviewReject({required this.reviewId, required this.reason});

  @override
  List<Object?> get props => [reviewId, reason];
}

class AdminReviewDismissReport extends AdminReviewsEvent {
  final String reviewId;

  const AdminReviewDismissReport({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

// ==================== STATES ====================

abstract class AdminReviewsState extends Equatable {
  const AdminReviewsState();

  @override
  List<Object?> get props => [];
}

class AdminReviewsInitial extends AdminReviewsState {}

class AdminReviewsLoading extends AdminReviewsState {}

class AdminReviewsLoaded extends AdminReviewsState {
  final List<Review> reviews;
  final List<Review> filteredReviews;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isReportedTab;
  final bool isLoadingMore;
  final String? searchQuery;

  const AdminReviewsLoaded({
    required this.reviews,
    required this.filteredReviews,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
    this.isReportedTab = false,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  AdminReviewsLoaded copyWith({
    List<Review>? reviews,
    List<Review>? filteredReviews,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isReportedTab,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return AdminReviewsLoaded(
      reviews: reviews ?? this.reviews,
      filteredReviews: filteredReviews ?? this.filteredReviews,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isReportedTab: isReportedTab ?? this.isReportedTab,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        reviews,
        filteredReviews,
        totalCount,
        currentPage,
        hasMore,
        isReportedTab,
        isLoadingMore,
        searchQuery,
      ];
}

class AdminReviewActionSuccess extends AdminReviewsState {
  final String message;

  const AdminReviewActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminReviewsError extends AdminReviewsState {
  final String message;

  const AdminReviewsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class AdminReviewsBloc extends Bloc<AdminReviewsEvent, AdminReviewsState> {
  final AdminRepository _repository = AdminRepository();
  bool _isReportedTab = false;

  AdminReviewsBloc() : super(AdminReviewsInitial()) {
    on<AdminReviewsLoadPending>(_onLoadPending);
    on<AdminReviewsLoadReported>(_onLoadReported);
    on<AdminReviewsLoadMore>(_onLoadMore);
    on<AdminReviewsRefresh>(_onRefresh);
    on<AdminReviewsSearch>(_onSearch);
    on<AdminReviewApprove>(_onApprove);
    on<AdminReviewReject>(_onReject);
    on<AdminReviewDismissReport>(_onDismissReport);
  }

  List<Review> _filterReviews(List<Review> reviews, String? query) {
    if (query == null || query.isEmpty) return reviews;
    final lowerQuery = query.toLowerCase();
    return reviews.where((review) {
      final userName = review.user != null
          ? '${review.user!.firstName} ${review.user!.lastName}'.toLowerCase()
          : '';
      return review.comment.toLowerCase().contains(lowerQuery) ||
          userName.contains(lowerQuery);
    }).toList();
  }

  Future<void> _onLoadPending(
    AdminReviewsLoadPending event,
    Emitter<AdminReviewsState> emit,
  ) async {
    _isReportedTab = false;
    emit(AdminReviewsLoading());
    try {
      final data = await _repository.getPendingReviews(page: event.page);
      final reviewsList = (data['reviews'] as List?)
              ?.map((e) => Review.fromJson(e))
              .toList() ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] ?? reviewsList.length;
      final totalPages = pagination?['totalPages'] ?? 1;

      emit(AdminReviewsLoaded(
        reviews: reviewsList,
        filteredReviews: reviewsList,
        totalCount: total,
        currentPage: event.page,
        hasMore: event.page < totalPages,
        isReportedTab: false,
      ));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onLoadReported(
    AdminReviewsLoadReported event,
    Emitter<AdminReviewsState> emit,
  ) async {
    _isReportedTab = true;
    emit(AdminReviewsLoading());
    try {
      final data = await _repository.getReportedReviews(page: event.page);
      final reviewsList = (data['reviews'] as List?)
              ?.map((e) => Review.fromJson(e))
              .toList() ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] ?? reviewsList.length;
      final totalPages = pagination?['totalPages'] ?? 1;

      emit(AdminReviewsLoaded(
        reviews: reviewsList,
        filteredReviews: reviewsList,
        totalCount: total,
        currentPage: event.page,
        hasMore: event.page < totalPages,
        isReportedTab: true,
      ));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    AdminReviewsLoadMore event,
    Emitter<AdminReviewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AdminReviewsLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final data = _isReportedTab
          ? await _repository.getReportedReviews(page: nextPage)
          : await _repository.getPendingReviews(page: nextPage);

      final newReviews = (data['reviews'] as List?)
              ?.map((e) => Review.fromJson(e))
              .toList() ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final totalPages = pagination?['totalPages'] ?? 1;

      final allReviews = [...currentState.reviews, ...newReviews];
      emit(AdminReviewsLoaded(
        reviews: allReviews,
        filteredReviews: _filterReviews(allReviews, currentState.searchQuery),
        totalCount: currentState.totalCount,
        currentPage: nextPage,
        hasMore: nextPage < totalPages,
        isReportedTab: _isReportedTab,
        searchQuery: currentState.searchQuery,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onRefresh(
    AdminReviewsRefresh event,
    Emitter<AdminReviewsState> emit,
  ) async {
    if (_isReportedTab) {
      add(const AdminReviewsLoadReported());
    } else {
      add(const AdminReviewsLoadPending());
    }
  }

  void _onSearch(
    AdminReviewsSearch event,
    Emitter<AdminReviewsState> emit,
  ) {
    final currentState = state;
    if (currentState is AdminReviewsLoaded) {
      emit(currentState.copyWith(
        filteredReviews: _filterReviews(currentState.reviews, event.query),
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onApprove(
    AdminReviewApprove event,
    Emitter<AdminReviewsState> emit,
  ) async {
    try {
      await _repository.approveReview(event.reviewId);
      emit(const AdminReviewActionSuccess(message: 'Avis approuvé'));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onReject(
    AdminReviewReject event,
    Emitter<AdminReviewsState> emit,
  ) async {
    try {
      await _repository.rejectReview(event.reviewId, event.reason);
      emit(const AdminReviewActionSuccess(message: 'Avis rejeté'));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onDismissReport(
    AdminReviewDismissReport event,
    Emitter<AdminReviewsState> emit,
  ) async {
    try {
      await _repository.dismissReport(event.reviewId);
      emit(const AdminReviewActionSuccess(
          message: 'Signalement rejeté'));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }
}
