import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/subscription_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/partner_repository.dart';

// ==================== EVENTS ====================

abstract class PartnerSubscriptionEvent extends Equatable {
  const PartnerSubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionStatus extends PartnerSubscriptionEvent {
  const LoadSubscriptionStatus();
}

class CreateCheckout extends PartnerSubscriptionEvent {
  final String plan; // "monthly" | "yearly"

  const CreateCheckout({required this.plan});

  @override
  List<Object?> get props => [plan];
}

class RequestManualPayment extends PartnerSubscriptionEvent {
  final String plan;
  final String? transferReference;

  const RequestManualPayment({required this.plan, this.transferReference});

  @override
  List<Object?> get props => [plan, transferReference];
}

class CancelSubscription extends PartnerSubscriptionEvent {
  const CancelSubscription();
}

// ==================== STATES ====================

abstract class PartnerSubscriptionState extends Equatable {
  const PartnerSubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends PartnerSubscriptionState {}

class SubscriptionLoading extends PartnerSubscriptionState {}

class SubscriptionLoaded extends PartnerSubscriptionState {
  final SubscriptionStatus status;

  const SubscriptionLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class CheckoutSessionCreated extends PartnerSubscriptionState {
  final String checkoutUrl;

  const CheckoutSessionCreated(this.checkoutUrl);

  @override
  List<Object?> get props => [checkoutUrl];
}

class ManualPaymentRequested extends PartnerSubscriptionState {
  final Invoice invoice;
  final BankDetails bankDetails;

  const ManualPaymentRequested({
    required this.invoice,
    required this.bankDetails,
  });

  @override
  List<Object?> get props => [invoice, bankDetails];
}

class SubscriptionCancelled extends PartnerSubscriptionState {}

class SubscriptionError extends PartnerSubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class PartnerSubscriptionBloc
    extends Bloc<PartnerSubscriptionEvent, PartnerSubscriptionState> {
  final PartnerRepository _repository = PartnerRepository();

  PartnerSubscriptionBloc() : super(SubscriptionInitial()) {
    on<LoadSubscriptionStatus>(_onLoadStatus);
    on<CreateCheckout>(_onCreateCheckout);
    on<RequestManualPayment>(_onRequestManual);
    on<CancelSubscription>(_onCancelSubscription);
  }

  Future<void> _onLoadStatus(
    LoadSubscriptionStatus event,
    Emitter<PartnerSubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final status = await _repository.getSubscriptionStatus();
      emit(SubscriptionLoaded(status));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onCreateCheckout(
    CreateCheckout event,
    Emitter<PartnerSubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final url = await _repository.createCheckoutSession(event.plan);
      emit(CheckoutSessionCreated(url));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRequestManual(
    RequestManualPayment event,
    Emitter<PartnerSubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final result = await _repository.requestManualPayment(
        event.plan,
        transferReference: event.transferReference,
      );
      emit(ManualPaymentRequested(
        invoice: result.invoice,
        bankDetails: result.bankDetails,
      ));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<PartnerSubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      await _repository.cancelSubscription();
      emit(SubscriptionCancelled());
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
