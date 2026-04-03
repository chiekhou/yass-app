import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/admin_establishment_model.dart';
import '../../data/repositories/admin_repository.dart';

// ==================== EVENTS ====================

abstract class AdminEstablishmentsEvent extends Equatable {
  const AdminEstablishmentsEvent();

  @override
  List<Object?> get props => [];
}

// --- Pending page events (inchangés) ---

class AdminEstablishmentsLoadPending extends AdminEstablishmentsEvent {}

class AdminEstablishmentsRefresh extends AdminEstablishmentsEvent {}

class AdminEstablishmentApprove extends AdminEstablishmentsEvent {
  final String establishmentId;

  const AdminEstablishmentApprove({required this.establishmentId});

  @override
  List<Object?> get props => [establishmentId];
}

class AdminEstablishmentReject extends AdminEstablishmentsEvent {
  final String establishmentId;
  final String reason;

  const AdminEstablishmentReject({
    required this.establishmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [establishmentId, reason];
}

// --- All-establishments page events ---

class AdminEstablishmentsLoad extends AdminEstablishmentsEvent {
  final String? status;
  final String? search;

  const AdminEstablishmentsLoad({this.status, this.search});

  @override
  List<Object?> get props => [status, search];
}

class AdminEstablishmentsLoadMore extends AdminEstablishmentsEvent {}

class AdminEstablishmentsFilterByStatus extends AdminEstablishmentsEvent {
  final String? status; // null = tous

  const AdminEstablishmentsFilterByStatus({this.status});

  @override
  List<Object?> get props => [status];
}

class AdminEstablishmentsSearch extends AdminEstablishmentsEvent {
  final String query;

  const AdminEstablishmentsSearch({required this.query});

  @override
  List<Object?> get props => [query];
}

class AdminEstablishmentDelete extends AdminEstablishmentsEvent {
  final String establishmentId;

  const AdminEstablishmentDelete({required this.establishmentId});

  @override
  List<Object?> get props => [establishmentId];
}

class AdminEstablishmentSetFeatured extends AdminEstablishmentsEvent {
  final String establishmentId;
  final int? durationDays; // null = sans limite, 0 = retirer

  const AdminEstablishmentSetFeatured({
    required this.establishmentId,
    this.durationDays,
  });

  @override
  List<Object?> get props => [establishmentId, durationDays];
}

class AdminEstablishmentsGoToPage extends AdminEstablishmentsEvent {
  final int page;

  const AdminEstablishmentsGoToPage({required this.page});

  @override
  List<Object?> get props => [page];
}

class AdminEstablishmentAssignPartner extends AdminEstablishmentsEvent {
  final String establishmentId;
  final String? partnerId; // null = détacher

  const AdminEstablishmentAssignPartner({
    required this.establishmentId,
    this.partnerId,
  });

  @override
  List<Object?> get props => [establishmentId, partnerId];
}

// ==================== STATES ====================

abstract class AdminEstablishmentsState extends Equatable {
  const AdminEstablishmentsState();

  @override
  List<Object?> get props => [];
}

class AdminEstablishmentsInitial extends AdminEstablishmentsState {}

class AdminEstablishmentsLoading extends AdminEstablishmentsState {}

class AdminEstablishmentsLoaded extends AdminEstablishmentsState {
  final List<AdminEstablishment> establishments;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final bool isUpdating;
  final String? processingId;
  final String? statusFilter;
  final String? searchQuery;
  final bool isPendingMode;

  const AdminEstablishmentsLoaded({
    required this.establishments,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.isUpdating = false,
    this.processingId,
    this.statusFilter,
    this.searchQuery,
    this.isPendingMode = false,
  });

  bool get hasMore => page < totalPages;

  // Sentinel pour distinguer "non fourni" de "null explicite"
  static const _absent = Object();

  AdminEstablishmentsLoaded copyWith({
    List<AdminEstablishment>? establishments,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    bool? isUpdating,
    Object? processingId = _absent,
    Object? statusFilter = _absent,
    Object? searchQuery = _absent,
    bool? isPendingMode,
  }) {
    return AdminEstablishmentsLoaded(
      establishments: establishments ?? this.establishments,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdating: isUpdating ?? this.isUpdating,
      processingId: processingId == _absent ? this.processingId : processingId as String?,
      statusFilter: statusFilter == _absent ? this.statusFilter : statusFilter as String?,
      searchQuery: searchQuery == _absent ? this.searchQuery : searchQuery as String?,
      isPendingMode: isPendingMode ?? this.isPendingMode,
    );
  }

  @override
  List<Object?> get props => [
        establishments,
        total,
        page,
        totalPages,
        isLoadingMore,
        isUpdating,
        processingId,
        statusFilter,
        searchQuery,
        isPendingMode,
      ];
}

class AdminEstablishmentsError extends AdminEstablishmentsState {
  final String message;

  const AdminEstablishmentsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class AdminEstablishmentsBloc
    extends Bloc<AdminEstablishmentsEvent, AdminEstablishmentsState> {
  final AdminRepository _adminRepository = AdminRepository();

  AdminEstablishmentsBloc() : super(AdminEstablishmentsInitial()) {
    // Pending page
    on<AdminEstablishmentsLoadPending>(_onLoadPending);
    on<AdminEstablishmentsRefresh>(_onRefresh);
    on<AdminEstablishmentApprove>(_onApprove);
    on<AdminEstablishmentReject>(_onReject);
    // All-establishments page
    on<AdminEstablishmentsLoad>(_onLoad);
    on<AdminEstablishmentsLoadMore>(_onLoadMore);
    on<AdminEstablishmentsFilterByStatus>(_onFilterByStatus);
    on<AdminEstablishmentsSearch>(_onSearch);
    on<AdminEstablishmentDelete>(_onDelete);
    on<AdminEstablishmentSetFeatured>(_onSetFeatured);
    on<AdminEstablishmentsGoToPage>(_onGoToPage);
    on<AdminEstablishmentAssignPartner>(_onAssignPartner);
  }

  // ── Pending page handlers ─────────────────────────────────────────────────

  Future<void> _onLoadPending(
    AdminEstablishmentsLoadPending event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    emit(AdminEstablishmentsLoading());
    try {
      final result = await _adminRepository.getPendingEstablishments(page: 1);
      emit(AdminEstablishmentsLoaded(
        establishments: result.establishments,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        isPendingMode: true,
      ));
    } catch (e) {
      emit(AdminEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    AdminEstablishmentsRefresh event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    try {
      final result = await _adminRepository.getPendingEstablishments(page: 1);
      emit(AdminEstablishmentsLoaded(
        establishments: result.establishments,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        isPendingMode: true,
      ));
    } catch (e) {
      if (currentState is! AdminEstablishmentsLoaded) {
        emit(AdminEstablishmentsError(message: e.toString()));
      }
    }
  }

  Future<void> _onApprove(
    AdminEstablishmentApprove event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded) {
      emit(currentState.copyWith(
        isUpdating: true,
        processingId: event.establishmentId,
      ));
      try {
        await _adminRepository.approveEstablishment(event.establishmentId);
        final updated = currentState.establishments
            .where((e) => e.id != event.establishmentId)
            .toList();
        emit(currentState.copyWith(
          establishments: updated,
          total: currentState.total - 1,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false, processingId: null));
        rethrow;
      }
    }
  }

  Future<void> _onReject(
    AdminEstablishmentReject event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded) {
      emit(currentState.copyWith(
        isUpdating: true,
        processingId: event.establishmentId,
      ));
      try {
        await _adminRepository.rejectEstablishment(
          event.establishmentId,
          event.reason,
        );
        final updated = currentState.establishments
            .where((e) => e.id != event.establishmentId)
            .toList();
        emit(currentState.copyWith(
          establishments: updated,
          total: currentState.total - 1,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false, processingId: null));
        rethrow;
      }
    }
  }

  // ── All-establishments page handlers ─────────────────────────────────────

  Future<void> _onLoad(
    AdminEstablishmentsLoad event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    emit(AdminEstablishmentsLoading());
    try {
      final result = await _adminRepository.getEstablishments(
        page: 1,
        status: event.status,
        search: event.search,
      );
      emit(AdminEstablishmentsLoaded(
        establishments: result.establishments,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: event.status,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(AdminEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    AdminEstablishmentsLoadMore event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      try {
        final AdminEstablishmentPagination result;
        if (currentState.isPendingMode) {
          result = await _adminRepository.getPendingEstablishments(
            page: currentState.page + 1,
          );
        } else {
          result = await _adminRepository.getEstablishments(
            page: currentState.page + 1,
            status: currentState.statusFilter,
            search: currentState.searchQuery,
          );
        }
        emit(currentState.copyWith(
          establishments: [
            ...currentState.establishments,
            ...result.establishments,
          ],
          page: result.page,
          totalPages: result.totalPages,
          total: result.total,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onFilterByStatus(
    AdminEstablishmentsFilterByStatus event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    final search = currentState is AdminEstablishmentsLoaded
        ? currentState.searchQuery
        : null;

    emit(AdminEstablishmentsLoading());
    try {
      final result = await _adminRepository.getEstablishments(
        page: 1,
        status: event.status,
        search: search,
      );
      emit(AdminEstablishmentsLoaded(
        establishments: result.establishments,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: event.status,
        searchQuery: search,
      ));
    } catch (e) {
      emit(AdminEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onSearch(
    AdminEstablishmentsSearch event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    final status = currentState is AdminEstablishmentsLoaded
        ? currentState.statusFilter
        : null;

    emit(AdminEstablishmentsLoading());
    try {
      final result = await _adminRepository.getEstablishments(
        page: 1,
        status: status,
        search: event.query.isEmpty ? null : event.query,
      );
      emit(AdminEstablishmentsLoaded(
        establishments: result.establishments,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: status,
        searchQuery: event.query.isEmpty ? null : event.query,
      ));
    } catch (e) {
      emit(AdminEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onDelete(
    AdminEstablishmentDelete event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded) {
      emit(currentState.copyWith(
        isUpdating: true,
        processingId: event.establishmentId,
      ));
      try {
        await _adminRepository.deleteEstablishment(event.establishmentId);
        final updated = currentState.establishments
            .where((e) => e.id != event.establishmentId)
            .toList();
        emit(currentState.copyWith(
          establishments: updated,
          total: currentState.total - 1,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false, processingId: null));
        rethrow;
      }
    }
  }

  Future<void> _onSetFeatured(
    AdminEstablishmentSetFeatured event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded) {
      emit(currentState.copyWith(
        isUpdating: true,
        processingId: event.establishmentId,
      ));
      try {
        final updated = await _adminRepository.setFeatured(
          event.establishmentId,
          durationDays: event.durationDays,
        );
        final updatedList = currentState.establishments.map((e) {
          return e.id == event.establishmentId ? updated : e;
        }).toList();
        emit(currentState.copyWith(
          establishments: updatedList,
          isUpdating: false,
          processingId: null,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false, processingId: null));
        rethrow;
      }
    }
  }

  Future<void> _onGoToPage(
    AdminEstablishmentsGoToPage event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final result = await _adminRepository.getEstablishments(
          page: event.page,
          status: currentState.statusFilter,
          search: currentState.searchQuery,
        );
        emit(currentState.copyWith(
          establishments: result.establishments,
          page: result.page,
          totalPages: result.totalPages,
          total: result.total,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
      }
    }
  }

  Future<void> _onAssignPartner(
    AdminEstablishmentAssignPartner event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminEstablishmentsLoaded) {
      emit(currentState.copyWith(
        isUpdating: true,
        processingId: event.establishmentId,
      ));
      try {
        final updated = await _adminRepository.assignPartner(
          event.establishmentId,
          event.partnerId,
        );
        final updatedList = currentState.establishments.map((e) {
          return e.id == event.establishmentId ? updated : e;
        }).toList();
        emit(currentState.copyWith(
          establishments: updatedList,
          isUpdating: false,
          processingId: null,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false, processingId: null));
        rethrow;
      }
    }
  }
}
