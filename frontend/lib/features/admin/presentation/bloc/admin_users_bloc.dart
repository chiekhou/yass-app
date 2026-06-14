import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_repository.dart';

// ==================== EVENTS ====================

abstract class AdminUsersEvent extends Equatable {
  const AdminUsersEvent();

  @override
  List<Object?> get props => [];
}

class AdminUsersLoad extends AdminUsersEvent {
  final String? role;
  final String? status;
  final String? search;

  const AdminUsersLoad({this.role, this.status, this.search});

  @override
  List<Object?> get props => [role, status, search];
}

class AdminUsersLoadMore extends AdminUsersEvent {}

class AdminUsersRefresh extends AdminUsersEvent {}

class AdminUsersSearch extends AdminUsersEvent {
  final String query;

  const AdminUsersSearch({required this.query});

  @override
  List<Object?> get props => [query];
}

class AdminUsersFilterByRole extends AdminUsersEvent {
  final String? role;

  const AdminUsersFilterByRole({this.role});

  @override
  List<Object?> get props => [role];
}

class AdminUsersFilterByStatus extends AdminUsersEvent {
  final String? status;

  const AdminUsersFilterByStatus({this.status});

  @override
  List<Object?> get props => [status];
}

class AdminUserUpdateStatus extends AdminUsersEvent {
  final String userId;
  final String status;

  const AdminUserUpdateStatus({required this.userId, required this.status});

  @override
  List<Object?> get props => [userId, status];
}

class AdminUserDelete extends AdminUsersEvent {
  final String userId;

  const AdminUserDelete({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AdminUserToggleElite extends AdminUsersEvent {
  final String userId;

  const AdminUserToggleElite({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AdminUsersGoToPage extends AdminUsersEvent {
  final int page;

  const AdminUsersGoToPage({required this.page});

  @override
  List<Object?> get props => [page];
}

class AdminUserLoadDetails extends AdminUsersEvent {
  final String userId;

  const AdminUserLoadDetails({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ==================== STATES ====================

abstract class AdminUsersState extends Equatable {
  const AdminUsersState();

  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<AdminUser> users;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? roleFilter;
  final String? statusFilter;
  final String? searchQuery;
  final AdminUser? selectedUser;
  final bool isUpdating;

  const AdminUsersLoaded({
    required this.users,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.roleFilter,
    this.statusFilter,
    this.searchQuery,
    this.selectedUser,
    this.isUpdating = false,
  });

  bool get hasMore => page < totalPages;

  AdminUsersLoaded copyWith({
    List<AdminUser>? users,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? roleFilter,
    String? statusFilter,
    String? searchQuery,
    AdminUser? selectedUser,
    bool? isUpdating,
  }) {
    return AdminUsersLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUser: selectedUser ?? this.selectedUser,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [
        users,
        total,
        page,
        totalPages,
        isLoadingMore,
        roleFilter,
        statusFilter,
        searchQuery,
        selectedUser,
        isUpdating,
      ];
}

class AdminUsersError extends AdminUsersState {
  final String message;

  const AdminUsersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminUserDetailsLoading extends AdminUsersState {}

class AdminUserDetailsLoaded extends AdminUsersState {
  final AdminUser user;
  final bool isUpdating;

  const AdminUserDetailsLoaded({required this.user, this.isUpdating = false});

  AdminUserDetailsLoaded copyWith({AdminUser? user, bool? isUpdating}) {
    return AdminUserDetailsLoaded(
      user: user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [user, isUpdating];
}

class AdminUserDeletedSuccess extends AdminUsersState {}

// ==================== BLOC ====================

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final AdminRepository _adminRepository = AdminRepository();

  AdminUsersBloc() : super(AdminUsersInitial()) {
    on<AdminUsersLoad>(_onLoad);
    on<AdminUsersLoadMore>(_onLoadMore);
    on<AdminUsersRefresh>(_onRefresh);
    on<AdminUsersSearch>(_onSearch);
    on<AdminUsersFilterByRole>(_onFilterByRole);
    on<AdminUsersFilterByStatus>(_onFilterByStatus);
    on<AdminUserUpdateStatus>(_onUpdateStatus);
    on<AdminUserDelete>(_onDelete);
    on<AdminUserLoadDetails>(_onLoadDetails);
    on<AdminUsersGoToPage>(_onGoToPage);
    on<AdminUserToggleElite>(_onToggleElite);
  }

  Future<void> _onLoad(
    AdminUsersLoad event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(AdminUsersLoading());
    try {
      final result = await _adminRepository.getUsers(
        page: 1,
        role: event.role,
        status: event.status,
        search: event.search,
      );
      emit(AdminUsersLoaded(
        users: result.users,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        roleFilter: event.role,
        statusFilter: event.status,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(AdminUsersError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    AdminUsersLoadMore event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminUsersLoaded && !currentState.isLoadingMore && currentState.hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      try {
        final result = await _adminRepository.getUsers(
          page: currentState.page + 1,
          role: currentState.roleFilter,
          status: currentState.statusFilter,
          search: currentState.searchQuery,
        );
        emit(currentState.copyWith(
          users: [...currentState.users, ...result.users],
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
    AdminUsersRefresh event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    String? role;
    String? status;
    String? search;

    if (currentState is AdminUsersLoaded) {
      role = currentState.roleFilter;
      status = currentState.statusFilter;
      search = currentState.searchQuery;
    }

    try {
      final result = await _adminRepository.getUsers(
        page: 1,
        role: role,
        status: status,
        search: search,
      );
      emit(AdminUsersLoaded(
        users: result.users,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        roleFilter: role,
        statusFilter: status,
        searchQuery: search,
      ));
    } catch (e) {
      if (state is! AdminUsersLoaded) {
        emit(AdminUsersError(message: e.toString()));
      }
    }
  }

  Future<void> _onSearch(
    AdminUsersSearch event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    String? role;
    String? status;

    if (currentState is AdminUsersLoaded) {
      role = currentState.roleFilter;
      status = currentState.statusFilter;
    }

    emit(AdminUsersLoading());
    try {
      final result = await _adminRepository.getUsers(
        page: 1,
        role: role,
        status: status,
        search: event.query.isEmpty ? null : event.query,
      );
      emit(AdminUsersLoaded(
        users: result.users,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        roleFilter: role,
        statusFilter: status,
        searchQuery: event.query.isEmpty ? null : event.query,
      ));
    } catch (e) {
      emit(AdminUsersError(message: e.toString()));
    }
  }

  Future<void> _onFilterByRole(
    AdminUsersFilterByRole event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    String? status;
    String? search;

    if (currentState is AdminUsersLoaded) {
      status = currentState.statusFilter;
      search = currentState.searchQuery;
    }

    emit(AdminUsersLoading());
    try {
      final result = await _adminRepository.getUsers(
        page: 1,
        role: event.role,
        status: status,
        search: search,
      );
      emit(AdminUsersLoaded(
        users: result.users,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        roleFilter: event.role,
        statusFilter: status,
        searchQuery: search,
      ));
    } catch (e) {
      emit(AdminUsersError(message: e.toString()));
    }
  }

  Future<void> _onFilterByStatus(
    AdminUsersFilterByStatus event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    String? role;
    String? search;

    if (currentState is AdminUsersLoaded) {
      role = currentState.roleFilter;
      search = currentState.searchQuery;
    }

    emit(AdminUsersLoading());
    try {
      final result = await _adminRepository.getUsers(
        page: 1,
        role: role,
        status: event.status,
        search: search,
      );
      emit(AdminUsersLoaded(
        users: result.users,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        roleFilter: role,
        statusFilter: event.status,
        searchQuery: search,
      ));
    } catch (e) {
      emit(AdminUsersError(message: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    AdminUserUpdateStatus event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminUsersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedUser = await _adminRepository.updateUserStatus(
          event.userId,
          event.status,
        );
        final updatedUsers = currentState.users.map((user) {
          if (user.id == event.userId) {
            return AdminUser.fromJson({
              ...user.toJson(),
              'status': updatedUser.status,
            });
          }
          return user;
        }).toList();
        emit(currentState.copyWith(
          users: updatedUsers,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    } else if (currentState is AdminUserDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedUser = await _adminRepository.updateUserStatus(
          event.userId,
          event.status,
        );
        emit(AdminUserDetailsLoaded(user: updatedUser));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }

  Future<void> _onDelete(
    AdminUserDelete event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminUsersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        await _adminRepository.deleteUser(event.userId);
        final updatedUsers = currentState.users
            .where((user) => user.id != event.userId)
            .toList();
        emit(currentState.copyWith(
          users: updatedUsers,
          total: currentState.total - 1,
          isUpdating: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    } else if (currentState is AdminUserDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        await _adminRepository.deleteUser(event.userId);
        emit(AdminUserDeletedSuccess());
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }

  Future<void> _onLoadDetails(
    AdminUserLoadDetails event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(AdminUserDetailsLoading());
    try {
      final user = await _adminRepository.getUserById(event.userId);
      emit(AdminUserDetailsLoaded(user: user));
    } catch (e) {
      emit(AdminUsersError(message: e.toString()));
    }
  }

  Future<void> _onGoToPage(
    AdminUsersGoToPage event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminUsersLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final result = await _adminRepository.getUsers(
          page: event.page,
          role: currentState.roleFilter,
          status: currentState.statusFilter,
          search: currentState.searchQuery,
        );
        emit(currentState.copyWith(
          users: result.users,
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

  Future<void> _onToggleElite(
    AdminUserToggleElite event,
    Emitter<AdminUsersState> emit,
  ) async {
    final currentState = state;
    if (currentState is AdminUserDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        final updatedUser = await _adminRepository.toggleEliteStatus(event.userId);
        emit(AdminUserDetailsLoaded(user: updatedUser));
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        rethrow;
      }
    }
  }
}

extension AdminUserExtension on AdminUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'status': status,
      'language': language,
      'email_verified': emailVerified,
      'wilaya_id': wilayaId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reviews_count': reviewsCount,
      'favorites_count': favoritesCount,
      'age': age,
      'gender': gender,
      'last_login': lastLogin?.toIso8601String(),
      'login_count': loginCount,
      'is_elite': isElite,
    };
  }
}
