import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/admin_stats_model.dart';
import '../../data/repositories/admin_repository.dart';

// ==================== EVENTS ====================

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

class AdminDashboardLoad extends AdminDashboardEvent {}

class AdminDashboardRefresh extends AdminDashboardEvent {}

// ==================== STATES ====================

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminStats stats;

  const AdminDashboardLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminRepository _adminRepository = AdminRepository();

  AdminDashboardBloc() : super(AdminDashboardInitial()) {
    on<AdminDashboardLoad>(_onLoad);
    on<AdminDashboardRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
    AdminDashboardLoad event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      final stats = await _adminRepository.getDashboardStats();
      emit(AdminDashboardLoaded(stats: stats));
    } catch (e) {
      emit(AdminDashboardError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    AdminDashboardRefresh event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      final stats = await _adminRepository.getDashboardStats();
      emit(AdminDashboardLoaded(stats: stats));
    } catch (e) {
      if (state is! AdminDashboardLoaded) {
        emit(AdminDashboardError(message: e.toString()));
      }
    }
  }
}
