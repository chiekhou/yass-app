import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/admin_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AdminPaymentsEvent extends Equatable {
  const AdminPaymentsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPendingPayments extends AdminPaymentsEvent {
  const LoadPendingPayments();
}

class ValidatePayment extends AdminPaymentsEvent {
  final String invoiceId;
  const ValidatePayment(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AdminPaymentsState extends Equatable {
  const AdminPaymentsState();
  @override
  List<Object?> get props => [];
}

class AdminPaymentsInitial extends AdminPaymentsState {}

class AdminPaymentsLoading extends AdminPaymentsState {}

class AdminPaymentsLoaded extends AdminPaymentsState {
  final List<Map<String, dynamic>> invoices;
  const AdminPaymentsLoaded(this.invoices);
  @override
  List<Object?> get props => [invoices];
}

class AdminPaymentValidating extends AdminPaymentsState {
  final String invoiceId;
  const AdminPaymentValidating(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class AdminPaymentValidated extends AdminPaymentsState {
  final String invoiceId;
  const AdminPaymentValidated(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class AdminPaymentsError extends AdminPaymentsState {
  final String message;
  const AdminPaymentsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AdminPaymentsBloc
    extends Bloc<AdminPaymentsEvent, AdminPaymentsState> {
  final AdminRepository _repository;

  AdminPaymentsBloc({AdminRepository? repository})
      : _repository = repository ?? AdminRepository(),
        super(AdminPaymentsInitial()) {
    on<LoadPendingPayments>(_onLoad);
    on<ValidatePayment>(_onValidate);
  }

  Future<void> _onLoad(
    LoadPendingPayments event,
    Emitter<AdminPaymentsState> emit,
  ) async {
    emit(AdminPaymentsLoading());
    try {
      final invoices = await _repository.getPendingPayments();
      emit(AdminPaymentsLoaded(invoices));
    } catch (e) {
      emit(AdminPaymentsError(e.toString()));
    }
  }

  Future<void> _onValidate(
    ValidatePayment event,
    Emitter<AdminPaymentsState> emit,
  ) async {
    final current = state;
    if (current is! AdminPaymentsLoaded) return;

    emit(AdminPaymentValidating(event.invoiceId));
    try {
      await _repository.validatePayment(event.invoiceId);
      emit(AdminPaymentValidated(event.invoiceId));
      // Reload list after validation
      final invoices = await _repository.getPendingPayments();
      emit(AdminPaymentsLoaded(invoices));
    } catch (e) {
      emit(AdminPaymentsError(e.toString()));
    }
  }
}
