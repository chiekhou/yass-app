import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../data/repositories/partner_repository.dart';

// Events
abstract class PartnerEstablishmentsEvent extends Equatable {
  const PartnerEstablishmentsEvent();

  @override
  List<Object?> get props => [];
}

class PartnerEstablishmentsLoad extends PartnerEstablishmentsEvent {
  final String? status;

  const PartnerEstablishmentsLoad({this.status});

  @override
  List<Object?> get props => [status];
}

class PartnerEstablishmentsLoadMore extends PartnerEstablishmentsEvent {}

class PartnerEstablishmentsRefresh extends PartnerEstablishmentsEvent {}

class PartnerEstablishmentsFilterByStatus extends PartnerEstablishmentsEvent {
  final String? status;

  const PartnerEstablishmentsFilterByStatus({this.status});

  @override
  List<Object?> get props => [status];
}

class PartnerEstablishmentCreate extends PartnerEstablishmentsEvent {
  final Map<String, dynamic> data;

  const PartnerEstablishmentCreate({required this.data});

  @override
  List<Object?> get props => [data];
}

class PartnerEstablishmentUpdate extends PartnerEstablishmentsEvent {
  final String id;
  final Map<String, dynamic> data;

  const PartnerEstablishmentUpdate({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class PartnerEstablishmentDelete extends PartnerEstablishmentsEvent {
  final String id;

  const PartnerEstablishmentDelete({required this.id});

  @override
  List<Object?> get props => [id];
}

class PartnerEstablishmentUpdateStatus extends PartnerEstablishmentsEvent {
  final String id;
  final String status;

  const PartnerEstablishmentUpdateStatus({required this.id, required this.status});

  @override
  List<Object?> get props => [id, status];
}

class PartnerEstablishmentsGoToPage extends PartnerEstablishmentsEvent {
  final int page;

  const PartnerEstablishmentsGoToPage({required this.page});

  @override
  List<Object?> get props => [page];
}

// States
abstract class PartnerEstablishmentsState extends Equatable {
  const PartnerEstablishmentsState();

  @override
  List<Object?> get props => [];
}

class PartnerEstablishmentsInitial extends PartnerEstablishmentsState {}

class PartnerEstablishmentsLoading extends PartnerEstablishmentsState {}

class PartnerEstablishmentsLoaded extends PartnerEstablishmentsState {
  final List<Establishment> establishments;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool isUpdating;
  final String? statusFilter;
  final String? processingId;

  const PartnerEstablishmentsLoaded({
    required this.establishments,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
    this.isUpdating = false,
    this.statusFilter,
    this.processingId,
  });

  bool get hasMore => currentPage < totalPages;

  PartnerEstablishmentsLoaded copyWith({
    List<Establishment>? establishments,
    int? total,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? isUpdating,
    String? statusFilter,
    String? processingId,
  }) {
    return PartnerEstablishmentsLoaded(
      establishments: establishments ?? this.establishments,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdating: isUpdating ?? this.isUpdating,
      statusFilter: statusFilter ?? this.statusFilter,
      processingId: processingId,
    );
  }

  @override
  List<Object?> get props => [
        establishments,
        total,
        currentPage,
        totalPages,
        isLoadingMore,
        isUpdating,
        statusFilter,
        processingId,
      ];
}

class PartnerEstablishmentsError extends PartnerEstablishmentsState {
  final String message;

  const PartnerEstablishmentsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PartnerEstablishmentCreated extends PartnerEstablishmentsState {
  final Establishment establishment;

  const PartnerEstablishmentCreated({required this.establishment});

  @override
  List<Object?> get props => [establishment];
}

class PartnerEstablishmentUpdated extends PartnerEstablishmentsState {
  final Establishment establishment;

  const PartnerEstablishmentUpdated({required this.establishment});

  @override
  List<Object?> get props => [establishment];
}

class PartnerEstablishmentDeleted extends PartnerEstablishmentsState {
  final String id;

  const PartnerEstablishmentDeleted({required this.id});

  @override
  List<Object?> get props => [id];
}

// BLoC
class PartnerEstablishmentsBloc
    extends Bloc<PartnerEstablishmentsEvent, PartnerEstablishmentsState> {
  final PartnerRepository _repository = PartnerRepository();

  PartnerEstablishmentsBloc() : super(PartnerEstablishmentsInitial()) {
    on<PartnerEstablishmentsLoad>(_onLoad);
    on<PartnerEstablishmentsLoadMore>(_onLoadMore);
    on<PartnerEstablishmentsRefresh>(_onRefresh);
    on<PartnerEstablishmentsFilterByStatus>(_onFilterByStatus);
    on<PartnerEstablishmentCreate>(_onCreate);
    on<PartnerEstablishmentUpdate>(_onUpdate);
    on<PartnerEstablishmentDelete>(_onDelete);
    on<PartnerEstablishmentUpdateStatus>(_onUpdateStatus);
    on<PartnerEstablishmentsGoToPage>(_onGoToPage);
  }

  Future<void> _onLoad(
    PartnerEstablishmentsLoad event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    emit(PartnerEstablishmentsLoading());
    try {
      final response = await _repository.getEstablishments(status: event.status);
      emit(PartnerEstablishmentsLoaded(
        establishments: response.items,
        total: response.pagination.total,
        currentPage: response.pagination.page,
        totalPages: response.pagination.totalPages,
        statusFilter: event.status,
      ));
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    PartnerEstablishmentsLoadMore event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is PartnerEstablishmentsLoaded && currentState.hasMore && !currentState.isLoadingMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      try {
        final response = await _repository.getEstablishments(
          status: currentState.statusFilter,
          page: currentState.currentPage + 1,
        );
        emit(currentState.copyWith(
          establishments: [...currentState.establishments, ...response.items],
          currentPage: response.pagination.page,
          totalPages: response.pagination.totalPages,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onRefresh(
    PartnerEstablishmentsRefresh event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    final currentState = state;
    String? statusFilter;
    if (currentState is PartnerEstablishmentsLoaded) {
      statusFilter = currentState.statusFilter;
    }
    try {
      final response = await _repository.getEstablishments(status: statusFilter);
      emit(PartnerEstablishmentsLoaded(
        establishments: response.items,
        total: response.pagination.total,
        currentPage: response.pagination.page,
        totalPages: response.pagination.totalPages,
        statusFilter: statusFilter,
      ));
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onFilterByStatus(
    PartnerEstablishmentsFilterByStatus event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    emit(PartnerEstablishmentsLoading());
    try {
      final response = await _repository.getEstablishments(status: event.status);
      emit(PartnerEstablishmentsLoaded(
        establishments: response.items,
        total: response.pagination.total,
        currentPage: response.pagination.page,
        totalPages: response.pagination.totalPages,
        statusFilter: event.status,
      ));
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onCreate(
    PartnerEstablishmentCreate event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    try {
      final establishment = await _repository.createEstablishment(event.data);
      emit(PartnerEstablishmentCreated(establishment: establishment));
      add(const PartnerEstablishmentsLoad());
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    PartnerEstablishmentUpdate event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is PartnerEstablishmentsLoaded) {
      emit(currentState.copyWith(isUpdating: true, processingId: event.id));
    }
    try {
      final establishment = await _repository.updateEstablishment(event.id, event.data);
      emit(PartnerEstablishmentUpdated(establishment: establishment));
      add(const PartnerEstablishmentsLoad());
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onDelete(
    PartnerEstablishmentDelete event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is PartnerEstablishmentsLoaded) {
      emit(currentState.copyWith(isUpdating: true, processingId: event.id));
    }
    try {
      await _repository.deleteEstablishment(event.id);
      emit(PartnerEstablishmentDeleted(id: event.id));
      add(const PartnerEstablishmentsLoad());
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    PartnerEstablishmentUpdateStatus event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is PartnerEstablishmentsLoaded) {
      emit(currentState.copyWith(isUpdating: true, processingId: event.id));
    }
    try {
      final establishment = await _repository.updateEstablishmentStatus(event.id, event.status);
      emit(PartnerEstablishmentUpdated(establishment: establishment));
      add(const PartnerEstablishmentsLoad());
    } catch (e) {
      emit(PartnerEstablishmentsError(message: e.toString()));
    }
  }

  Future<void> _onGoToPage(
    PartnerEstablishmentsGoToPage event,
    Emitter<PartnerEstablishmentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is PartnerEstablishmentsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final response = await _repository.getEstablishments(
          status: currentState.statusFilter,
          page: event.page,
        );
        emit(currentState.copyWith(
          establishments: response.items,
          currentPage: response.pagination.page,
          totalPages: response.pagination.totalPages,
          total: response.pagination.total,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
      }
    }
  }
}
