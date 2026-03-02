import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/partner_stats_model.dart';
import '../../data/repositories/partner_repository.dart';

// Events
abstract class PartnerDashboardEvent extends Equatable {
  const PartnerDashboardEvent();

  @override
  List<Object?> get props => [];
}

class PartnerDashboardLoad extends PartnerDashboardEvent {}

class PartnerDashboardRefresh extends PartnerDashboardEvent {}

// States
abstract class PartnerDashboardState extends Equatable {
  const PartnerDashboardState();

  @override
  List<Object?> get props => [];
}

class PartnerDashboardInitial extends PartnerDashboardState {}

class PartnerDashboardLoading extends PartnerDashboardState {}

class PartnerDashboardLoaded extends PartnerDashboardState {
  final PartnerStats stats;

  const PartnerDashboardLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class PartnerDashboardError extends PartnerDashboardState {
  final String message;

  const PartnerDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class PartnerDashboardBloc extends Bloc<PartnerDashboardEvent, PartnerDashboardState> {
  final PartnerRepository _repository = PartnerRepository();

  PartnerDashboardBloc() : super(PartnerDashboardInitial()) {
    on<PartnerDashboardLoad>(_onLoad);
    on<PartnerDashboardRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
    PartnerDashboardLoad event,
    Emitter<PartnerDashboardState> emit,
  ) async {
    emit(PartnerDashboardLoading());
    try {
      final stats = await _repository.getStats();
      emit(PartnerDashboardLoaded(stats: stats));
    } catch (e) {
      emit(PartnerDashboardError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    PartnerDashboardRefresh event,
    Emitter<PartnerDashboardState> emit,
  ) async {
    try {
      final stats = await _repository.getStats();
      emit(PartnerDashboardLoaded(stats: stats));
    } catch (e) {
      emit(PartnerDashboardError(message: e.toString()));
    }
  }
}
