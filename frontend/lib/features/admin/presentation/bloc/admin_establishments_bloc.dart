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

class AdminEstablishmentsLoadPending extends AdminEstablishmentsEvent {}

class AdminEstablishmentsLoadMore extends AdminEstablishmentsEvent {}

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

  const AdminEstablishmentsLoaded({
    required this.establishments,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.isUpdating = false,
    this.processingId,
  });

  bool get hasMore => page < totalPages;

  AdminEstablishmentsLoaded copyWith({
    List<AdminEstablishment>? establishments,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    bool? isUpdating,
    String? processingId,
  }) {
    return AdminEstablishmentsLoaded(
      establishments: establishments ?? this.establishments,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdating: isUpdating ?? this.isUpdating,
      processingId: processingId,
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
    on<AdminEstablishmentsLoadPending>(_onLoadPending);
    on<AdminEstablishmentsLoadMore>(_onLoadMore);
    on<AdminEstablishmentsRefresh>(_onRefresh);
    on<AdminEstablishmentApprove>(_onApprove);
    on<AdminEstablishmentReject>(_onReject);
  }

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
        final result = await _adminRepository.getPendingEstablishments(
          page: currentState.page + 1,
        );
        emit(currentState.copyWith(
          establishments: [
            ...currentState.establishments,
            ...result.establishments
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

  Future<void> _onRefresh(
    AdminEstablishmentsRefresh event,
    Emitter<AdminEstablishmentsState> emit,
  ) async {
    try {
      final result = await _adminRepository.getPendingEstablishments(page: 1);
      emit(AdminEstablishmentsLoaded(
        establishments: result.establishments,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      ));
    } catch (e) {
      if (state is! AdminEstablishmentsLoaded) {
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
        final updatedEstablishments = currentState.establishments
            .where((e) => e.id != event.establishmentId)
            .toList();
        emit(currentState.copyWith(
          establishments: updatedEstablishments,
          total: currentState.total - 1,
          isUpdating: false,
          processingId: null,
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
        final updatedEstablishments = currentState.establishments
            .where((e) => e.id != event.establishmentId)
            .toList();
        emit(currentState.copyWith(
          establishments: updatedEstablishments,
          total: currentState.total - 1,
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
