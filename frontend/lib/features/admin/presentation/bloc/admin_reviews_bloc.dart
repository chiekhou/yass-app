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

class AdminReviewsLoadAll extends AdminReviewsEvent {
  final int page;
  final String status;
  const AdminReviewsLoadAll({this.page = 1, this.status = 'all'});
  @override
  List<Object?> get props => [page, status];
}

class AdminReviewsLoadMore extends AdminReviewsEvent {}

class AdminReviewsGoToPage extends AdminReviewsEvent {
  final int page;
  const AdminReviewsGoToPage({required this.page});
  @override
  List<Object?> get props => [page];
}

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

class AdminReviewRevoke extends AdminReviewsEvent {
  final String reviewId;
  const AdminReviewRevoke({required this.reviewId});
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

// 'pending' | 'reported' | 'all'
typedef ReviewTab = String;

class AdminReviewsLoaded extends AdminReviewsState {
  final List<Review> reviews;
  final List<Review> filteredReviews;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final ReviewTab activeTab;
  final String statusFilter; // 'all' | 'approved' | 'pending' | 'rejected'
  final bool isLoadingMore;
  final bool isPageLoading;
  final String? searchQuery;

  const AdminReviewsLoaded({
    required this.reviews,
    required this.filteredReviews,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.activeTab = 'pending',
    this.statusFilter = 'all',
    this.isLoadingMore = false,
    this.isPageLoading = false,
    this.searchQuery,
  });

  bool get isReportedTab => activeTab == 'reported';
  bool get isAllTab => activeTab == 'all';

  AdminReviewsLoaded copyWith({
    List<Review>? reviews,
    List<Review>? filteredReviews,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    ReviewTab? activeTab,
    String? statusFilter,
    bool? isLoadingMore,
    bool? isPageLoading,
    String? searchQuery,
  }) {
    return AdminReviewsLoaded(
      reviews: reviews ?? this.reviews,
      filteredReviews: filteredReviews ?? this.filteredReviews,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      activeTab: activeTab ?? this.activeTab,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isPageLoading: isPageLoading ?? this.isPageLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        reviews,
        filteredReviews,
        totalCount,
        currentPage,
        totalPages,
        hasMore,
        activeTab,
        statusFilter,
        isLoadingMore,
        isPageLoading,
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

  AdminReviewsBloc() : super(AdminReviewsInitial()) {
    on<AdminReviewsLoadPending>(_onLoadPending);
    on<AdminReviewsLoadReported>(_onLoadReported);
    on<AdminReviewsLoadAll>(_onLoadAll);
    on<AdminReviewsLoadMore>(_onLoadMore);
    on<AdminReviewsGoToPage>(_onGoToPage);
    on<AdminReviewsRefresh>(_onRefresh);
    on<AdminReviewsSearch>(_onSearch);
    on<AdminReviewApprove>(_onApprove);
    on<AdminReviewReject>(_onReject);
    on<AdminReviewDismissReport>(_onDismissReport);
    on<AdminReviewRevoke>(_onRevoke);
  }

  List<Review> _filterReviews(List<Review> reviews, String? query) {
    if (query == null || query.isEmpty) return reviews;
    final lowerQuery = query.toLowerCase();
    return reviews.where((review) {
      final userName = review.user != null
          ? '${review.user!.firstName} ${review.user!.lastName}'.toLowerCase()
          : '';
      final establishment = review.establishment?.name.toLowerCase() ?? '';
      return review.comment.toLowerCase().contains(lowerQuery) ||
          (review.title?.toLowerCase().contains(lowerQuery) ?? false) ||
          userName.contains(lowerQuery) ||
          establishment.contains(lowerQuery);
    }).toList();
  }

  List<Review> _parseReviews(Map<String, dynamic> data) =>
      (data['reviews'] as List?)?.map((e) => Review.fromJson(e)).toList() ?? [];

  int _total(Map<String, dynamic> data, List reviews) =>
      (data['pagination'] as Map<String, dynamic>?)?['total'] ?? reviews.length;

  int _totalPages(Map<String, dynamic> data) =>
      (data['pagination'] as Map<String, dynamic>?)?['totalPages'] ?? 1;

  Future<void> _onLoadPending(
    AdminReviewsLoadPending event,
    Emitter<AdminReviewsState> emit,
  ) async {
    emit(AdminReviewsLoading());
    try {
      final data = await _repository.getPendingReviews(page: event.page);
      final reviews = _parseReviews(data);
      emit(AdminReviewsLoaded(
        reviews: reviews,
        filteredReviews: reviews,
        totalCount: _total(data, reviews),
        currentPage: event.page,
        totalPages: _totalPages(data),
        hasMore: event.page < _totalPages(data),
        activeTab: 'pending',
      ));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onLoadReported(
    AdminReviewsLoadReported event,
    Emitter<AdminReviewsState> emit,
  ) async {
    emit(AdminReviewsLoading());
    try {
      final data = await _repository.getReportedReviews(page: event.page);
      final reviews = _parseReviews(data);
      emit(AdminReviewsLoaded(
        reviews: reviews,
        filteredReviews: reviews,
        totalCount: _total(data, reviews),
        currentPage: event.page,
        totalPages: _totalPages(data),
        hasMore: event.page < _totalPages(data),
        activeTab: 'reported',
      ));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onLoadAll(
    AdminReviewsLoadAll event,
    Emitter<AdminReviewsState> emit,
  ) async {
    emit(AdminReviewsLoading());
    try {
      final data = await _repository.getAllReviews(
        page: event.page,
        status: event.status,
      );
      final reviews = _parseReviews(data);
      emit(AdminReviewsLoaded(
        reviews: reviews,
        filteredReviews: reviews,
        totalCount: _total(data, reviews),
        currentPage: event.page,
        totalPages: _totalPages(data),
        hasMore: event.page < _totalPages(data),
        activeTab: 'all',
        statusFilter: event.status,
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
      late Map<String, dynamic> data;
      if (currentState.activeTab == 'reported') {
        data = await _repository.getReportedReviews(page: nextPage);
      } else if (currentState.activeTab == 'all') {
        data = await _repository.getAllReviews(
          page: nextPage,
          status: currentState.statusFilter,
        );
      } else {
        data = await _repository.getPendingReviews(page: nextPage);
      }

      final newReviews = _parseReviews(data);
      final allReviews = [...currentState.reviews, ...newReviews];
      emit(AdminReviewsLoaded(
        reviews: allReviews,
        filteredReviews: _filterReviews(allReviews, currentState.searchQuery),
        totalCount: currentState.totalCount,
        currentPage: nextPage,
        totalPages: _totalPages(data),
        hasMore: nextPage < _totalPages(data),
        activeTab: currentState.activeTab,
        statusFilter: currentState.statusFilter,
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
    final currentState = state;
    if (currentState is AdminReviewsLoaded) {
      if (currentState.activeTab == 'reported') {
        add(const AdminReviewsLoadReported());
      } else if (currentState.activeTab == 'all') {
        add(AdminReviewsLoadAll(status: currentState.statusFilter));
      } else {
        add(const AdminReviewsLoadPending());
      }
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
      emit(const AdminReviewActionSuccess(message: 'Signalement ignoré'));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onRevoke(
    AdminReviewRevoke event,
    Emitter<AdminReviewsState> emit,
  ) async {
    try {
      await _repository.revokeReview(event.reviewId);
      emit(const AdminReviewActionSuccess(message: 'Avis révoqué'));
    } catch (e) {
      emit(AdminReviewsError(message: e.toString()));
    }
  }

  Future<void> _onGoToPage(
    AdminReviewsGoToPage event,
    Emitter<AdminReviewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AdminReviewsLoaded) return;

    emit(currentState.copyWith(isPageLoading: true));
    try {
      late Map<String, dynamic> data;
      if (currentState.activeTab == 'reported') {
        data = await _repository.getReportedReviews(page: event.page);
      } else if (currentState.activeTab == 'all') {
        data = await _repository.getAllReviews(
          page: event.page,
          status: currentState.statusFilter,
        );
      } else {
        data = await _repository.getPendingReviews(page: event.page);
      }

      final reviews = _parseReviews(data);
      emit(AdminReviewsLoaded(
        reviews: reviews,
        filteredReviews: _filterReviews(reviews, currentState.searchQuery),
        totalCount: _total(data, reviews),
        currentPage: event.page,
        totalPages: _totalPages(data),
        hasMore: event.page < _totalPages(data),
        activeTab: currentState.activeTab,
        statusFilter: currentState.statusFilter,
        searchQuery: currentState.searchQuery,
      ));
    } catch (e) {
      emit(currentState.copyWith(isPageLoading: false));
    }
  }
}
