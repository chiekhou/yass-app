import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/invoice_model.dart';
import '../../data/repositories/partner_repository.dart';

// ==================== EVENTS ====================

abstract class PartnerInvoicesEvent extends Equatable {
  const PartnerInvoicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvoices extends PartnerInvoicesEvent {
  const LoadInvoices();
}

class LoadInvoiceDetail extends PartnerInvoicesEvent {
  final String invoiceId;

  const LoadInvoiceDetail(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

// ==================== STATES ====================

abstract class PartnerInvoicesState extends Equatable {
  const PartnerInvoicesState();

  @override
  List<Object?> get props => [];
}

class InvoicesInitial extends PartnerInvoicesState {}

class InvoicesLoading extends PartnerInvoicesState {}

class InvoicesLoaded extends PartnerInvoicesState {
  final List<Invoice> invoices;

  const InvoicesLoaded(this.invoices);

  @override
  List<Object?> get props => [invoices];
}

class InvoiceDetailLoaded extends PartnerInvoicesState {
  final Invoice invoice;

  const InvoiceDetailLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class InvoicesError extends PartnerInvoicesState {
  final String message;

  const InvoicesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class PartnerInvoicesBloc
    extends Bloc<PartnerInvoicesEvent, PartnerInvoicesState> {
  final PartnerRepository _repository = PartnerRepository();

  PartnerInvoicesBloc() : super(InvoicesInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<LoadInvoiceDetail>(_onLoadDetail);
  }

  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<PartnerInvoicesState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      final invoices = await _repository.getInvoices();
      emit(InvoicesLoaded(invoices));
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }

  Future<void> _onLoadDetail(
    LoadInvoiceDetail event,
    Emitter<PartnerInvoicesState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      final invoice = await _repository.getInvoice(event.invoiceId);
      emit(InvoiceDetailLoaded(invoice));
    } catch (e) {
      emit(InvoicesError(e.toString()));
    }
  }
}
