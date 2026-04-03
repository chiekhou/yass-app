import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/admin_partner_model.dart';
import '../../data/repositories/admin_repository.dart';

// ==================== EVENTS ====================

abstract class AdminPartnersEvent extends Equatable {
  const AdminPartnersEvent();

  @override
  List<Object?> get props => [];
}

class AdminPartnersLoad extends AdminPartnersEvent {
  final String? status;
  final String? search;
  final bool pendingOnly;

  const AdminPartnersLoad({
    this.status,
    this.search,
    this.pendingOnly = false,
  });

  @override
  List<Object?> get props => [status, search, pendingOnly];
}

class AdminPartnersLoadMore extends AdminPartnersEvent {}

class AdminPartnersRefresh extends AdminPartnersEvent {}

class AdminPartnersSearch extends AdminPartnersEvent {
  final String query;

  const AdminPartnersSearch({required this.query});

  @override
  List<Object?> get props => [query];
}

class AdminPartnersFilterByStatus extends AdminPartnersEvent {
  final String? status;

  const AdminPartnersFilterByStatus({this.status});

  @override
  List<Object?> get props => [status];
}

class AdminPartnerApprove extends AdminPartnersEvent {
  final String partnerId;

  const AdminPartnerApprove({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

class AdminPartnerReject extends AdminPartnersEvent {
  final String partnerId;
  final String reason;

  const AdminPartnerReject({required this.partnerId, required this.reason});

  @override
  List<Object?> get props => [partnerId, reason];
}

class AdminPartnerSuspend extends AdminPartnersEvent {
  final String partnerId;
  final String reason;

  const AdminPartnerSuspend({required this.partnerId, required this.reason});

  @override
  List<Object?> get props => [partnerId, reason];
}

class AdminPartnerLoadDetails extends AdminPartnersEvent {
  final String partnerId;

  const AdminPartnerLoadDetails({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

class AdminPartnerCreate extends AdminPartnersEvent {
  final Map<String, dynamic> data;

  const AdminPartnerCreate({required this.data});

  @override
  List<Object?> get props => [data];
}

class AdminPartnersGoToPage extends AdminPartnersEvent {
  final int page;

  const AdminPartnersGoToPage({required this.page});

  @override
  List<Object?> get props => [page];
}

class AdminEstablishmentDelete extends AdminPartnersEvent {
  final String establishmentId;
  final String partnerId;

  const AdminEstablishmentDelete({
    required this.establishmentId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [establishmentId, partnerId];
}

// ==================== STATES ====================

abstract class AdminPartnersState extends Equatable {
  const AdminPartnersState();

  @override
  List<Object?> get props => [];
}

class AdminPartnersInitial extends AdminPartnersState {}

class AdminPartnersLoading extends AdminPartnersState {}

class AdminPartnersLoaded extends AdminPartnersState {
  final List<AdminPartner> partners;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? statusFilter;
  final String? searchQuery;
  final bool pendingOnly;
  final bool isUpdating;

  const AdminPartnersLoaded({
    required this.partners,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.statusFilter,
    this.searchQuery,
    this.pendingOnly = false,
    this.isUpdating = false,
  });

  bool get hasMore => page < totalPages;

  AdminPartnersLoaded copyWith({
    List<AdminPartner>? partners,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? statusFilter,
    String? searchQuery,
    bool? pendingOnly,
    bool? isUpdating,
  }) {
    return AdminPartnersLoaded(
      partners: partners ?? this.partners,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      pendingOnly: pendingOnly ?? this.pendingOnly,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [
        partners,
        total,
        page,
        totalPages,
        isLoadingMore,
        statusFilter,
        searchQuery,
        pendingOnly,
        isUpdating,
      ];
}

class AdminPartnersError extends AdminPartnersState {
  final String message;

  const AdminPartnersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminPartnerCreated extends AdminPartnersState {
  final AdminPartner partner;

  const AdminPartnerCreated({required this.partner});

  @override
  List<Object?> get props => [partner];
}

class AdminPartnerDetailsLoading extends AdminPartnersState {}

class AdminPartnerDetailsLoaded extends AdminPartnersState {
  final AdminPartner partner;
  final bool isUpdating;

  const AdminPartnerDetailsLoaded({
    required this.partner,
    this.isUpdating = false,
  });

  AdminPartnerDetailsLoaded copyWith({
    AdminPartner? partner,
    bool? isUpdating,
  }) {
    return AdminPartnerDetailsLoaded(
      partner: partner ?? this.partner,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [partner, isUpdating];
}

// ==================== BLOC ====================

class AdminPartnersBloc extends Bloc<AdminPartnersEvent, AdminPartnersState> {
  final AdminRepository _adminRepository = AdminRepository();

  AdminPartnersBloc() : super(AdminPartnersInitial()) {
    on<AdminPartnersLoad>(_onLoad);
    on<AdminPartnersLoadMore>(_onLoadMore);
    on<AdminPartnersRefresh>(_onRefresh);
    on<AdminPartnersSearch>(_onSearch);
    on<AdminPartnersFilterByStatus>(_onFilterByStatus);
    on<AdminPartnerApprove>(_onApprove);
    on<AdminPartnerReject>(_onReject);
    on<AdminPartnerSuspend>(_onSuspend);
    on<AdminPartnerLoadDetails>(_onLoadDetails);
    on<AdminPartnerCreate>(_onCreate);
    on<AdminEstablishmentDelete>(_onDeleteEstablishment);
    on<AdminPartnersGoToPage>(_onGoToPage);
  }

  Future<void> _onLoad(
    AdminPartnersLoad event,
    Emitter<AdminPartnersState> emit,
  ) async {
    emit(AdminPartnersLoading());
    try {
      final AdminPartnerPagination result;
      if (event.pendingOnly) {
        result = await _adminRepository.getPendingPartners(page: 1);
      } else {
        result = await _adminRepository.getPartners(
          page: 1,
          status: event.status,
          search: event.search,
        );
      }
      emit(AdminPartnersLoaded(
        partners: result.partners,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: event.status,
        searchQuery: event.search,
        pendingOnly: event.pendingOnly,
      ));
    } catch (e) {
      emit(AdminPartnersError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    AdminPartnersLoadMore event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminPartnersLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      try {
        final AdminPartnerPagination result;
        if (currentState.pendingOnly) {
          result = await _adminRepository.getPendingPartners(
            page: currentState.page + 1,
          );
        } else {
          result = await _adminRepository.getPartners(
            page: currentState.page + 1,
            status: currentState.statusFilter,
            search: currentState.searchQuery,
          );
        }
        emit(currentState.copyWith(
          partners: [...currentState.partners, ...result.partners],
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
    AdminPartnersRefresh event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;
    String? status;
    String? search;
    bool pendingOnly = false;

    if (currentState is AdminPartnersLoaded) {
      status = currentState.statusFilter;
      search = currentState.searchQuery;
      pendingOnly = currentState.pendingOnly;
    }

    try {
      final AdminPartnerPagination result;
      if (pendingOnly) {
        result = await _adminRepository.getPendingPartners(page: 1);
      } else {
        result = await _adminRepository.getPartners(
          page: 1,
          status: status,
          search: search,
        );
      }
      emit(AdminPartnersLoaded(
        partners: result.partners,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: status,
        searchQuery: search,
        pendingOnly: pendingOnly,
      ));
    } catch (e) {
      if (state is! AdminPartnersLoaded) {
        emit(AdminPartnersError(message: e.toString()));
      }
    }
  }

  Future<void> _onSearch(
    AdminPartnersSearch event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;
    String? status;

    if (currentState is AdminPartnersLoaded) {
      status = currentState.statusFilter;
    }

    emit(AdminPartnersLoading());
    try {
      final result = await _adminRepository.getPartners(
        page: 1,
        status: status,
        search: event.query.isEmpty ? null : event.query,
      );
      emit(AdminPartnersLoaded(
        partners: result.partners,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: status,
        searchQuery: event.query.isEmpty ? null : event.query,
      ));
    } catch (e) {
      emit(AdminPartnersError(message: e.toString()));
    }
  }

  Future<void> _onFilterByStatus(
    AdminPartnersFilterByStatus event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;
    String? search;

    if (currentState is AdminPartnersLoaded) {
      search = currentState.searchQuery;
    }

    emit(AdminPartnersLoading());
    try {
      final result = await _adminRepository.getPartners(
        page: 1,
        status: event.status,
        search: search,
      );
      emit(AdminPartnersLoaded(
        partners: result.partners,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        statusFilter: event.status,
        searchQuery: search,
      ));
    } catch (e) {
      emit(AdminPartnersError(message: e.toString()));
    }
  }

  Future<void> _onApprove(
    AdminPartnerApprove event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;

    if (currentState is AdminPartnersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedPartner = await _adminRepository.approvePartner(event.partnerId);
        final updatedPartners = currentState.partners.map((partner) {
          if (partner.id == event.partnerId) {
            return updatedPartner;
          }
          return partner;
        }).toList();

        // Si on affiche seulement les pending, on retire le partenaire approuvé
        if (currentState.pendingOnly) {
          updatedPartners.removeWhere((p) => p.id == event.partnerId);
        }

        emit(currentState.copyWith(
          partners: updatedPartners,
          total: currentState.pendingOnly ? currentState.total - 1 : currentState.total,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    } else if (currentState is AdminPartnerDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedPartner = await _adminRepository.approvePartner(event.partnerId);
        emit(currentState.copyWith(
          partner: updatedPartner,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }

  Future<void> _onReject(
    AdminPartnerReject event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;

    if (currentState is AdminPartnersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedPartner = await _adminRepository.rejectPartner(
          event.partnerId,
          event.reason,
        );
        final updatedPartners = currentState.partners.map((partner) {
          if (partner.id == event.partnerId) {
            return updatedPartner;
          }
          return partner;
        }).toList();

        if (currentState.pendingOnly) {
          updatedPartners.removeWhere((p) => p.id == event.partnerId);
        }

        emit(currentState.copyWith(
          partners: updatedPartners,
          total: currentState.pendingOnly ? currentState.total - 1 : currentState.total,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    } else if (currentState is AdminPartnerDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedPartner = await _adminRepository.rejectPartner(
          event.partnerId,
          event.reason,
        );
        emit(currentState.copyWith(
          partner: updatedPartner,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }

  Future<void> _onSuspend(
    AdminPartnerSuspend event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;

    if (currentState is AdminPartnersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedPartner = await _adminRepository.suspendPartner(
          event.partnerId,
          event.reason,
        );
        final updatedPartners = currentState.partners.map((partner) {
          if (partner.id == event.partnerId) {
            return updatedPartner;
          }
          return partner;
        }).toList();
        emit(currentState.copyWith(
          partners: updatedPartners,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    } else if (currentState is AdminPartnerDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedPartner = await _adminRepository.suspendPartner(
          event.partnerId,
          event.reason,
        );
        emit(currentState.copyWith(
          partner: updatedPartner,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }

  Future<void> _onLoadDetails(
    AdminPartnerLoadDetails event,
    Emitter<AdminPartnersState> emit,
  ) async {
    emit(AdminPartnerDetailsLoading());
    try {
      final partner = await _adminRepository.getPartnerById(event.partnerId);
      emit(AdminPartnerDetailsLoaded(partner: partner));
    } catch (e) {
      emit(AdminPartnersError(message: e.toString()));
    }
  }

  Future<void> _onCreate(
    AdminPartnerCreate event,
    Emitter<AdminPartnersState> emit,
  ) async {
    emit(AdminPartnersLoading());
    try {
      final partner = await _adminRepository.createPartner(event.data);
      emit(AdminPartnerCreated(partner: partner));
    } catch (e) {
      emit(AdminPartnersError(message: e.toString()));
    }
  }

  Future<void> _onDeleteEstablishment(
    AdminEstablishmentDelete event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminPartnerDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        await _adminRepository.deleteEstablishment(event.establishmentId);
        final partner = await _adminRepository.getPartnerById(event.partnerId);
        emit(AdminPartnerDetailsLoaded(partner: partner));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }

  Future<void> _onGoToPage(
    AdminPartnersGoToPage event,
    Emitter<AdminPartnersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminPartnersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final result = await _adminRepository.getPartners(
          page: event.page,
          status: currentState.statusFilter,
          search: currentState.searchQuery,
        );
        emit(currentState.copyWith(
          partners: result.partners,
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
}
