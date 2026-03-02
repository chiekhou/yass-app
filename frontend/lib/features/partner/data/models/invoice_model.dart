import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final String plan;
  final String planLabel;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? chargilyCheckoutUrl;
  final String? transferReference;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? paidAt;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.plan,
    required this.planLabel,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.chargilyCheckoutUrl,
    this.transferReference,
    this.periodStart,
    this.periodEnd,
    this.paidAt,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending_validation';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isOnline => paymentMethod == 'chargily';

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending_validation':
        return 'En attente de validation';
      case 'failed':
        return 'Échoué';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'chargily':
        return 'CIB / EDAHABIA';
      case 'manual':
        return 'Virement manuel';
      default:
        return paymentMethod;
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    const planLabels = {
      'monthly': 'Mensuel',
      'yearly': 'Annuel',
    };

    return Invoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      plan: json['plan'] ?? 'monthly',
      planLabel: planLabels[json['plan']] ?? json['plan'] ?? 'Mensuel',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'DZD',
      paymentMethod: json['payment_method'] ?? 'manual',
      status: json['status'] ?? 'pending_validation',
      chargilyCheckoutUrl: json['chargily_checkout_url'],
      transferReference: json['transfer_reference'],
      periodStart: json['period_start'] != null
          ? DateTime.tryParse(json['period_start'])
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.tryParse(json['period_end'])
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        status,
        amount,
        plan,
        paymentMethod,
      ];
}

class ManualPaymentResult extends Equatable {
  final Invoice invoice;
  final BankDetails bankDetails;

  const ManualPaymentResult({
    required this.invoice,
    required this.bankDetails,
  });

  factory ManualPaymentResult.fromJson(Map<String, dynamic> json) {
    return ManualPaymentResult(
      invoice: Invoice.fromJson(json['invoice']),
      bankDetails: BankDetails.fromJson(json['bank_details']),
    );
  }

  @override
  List<Object?> get props => [invoice, bankDetails];
}

class BankDetails extends Equatable {
  final String ccp;
  final String rib;
  final String accountName;

  const BankDetails({
    required this.ccp,
    required this.rib,
    required this.accountName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      ccp: json['ccp'] ?? '',
      rib: json['rib'] ?? '',
      accountName: json['account_name'] ?? 'Win-وين',
    );
  }

  @override
  List<Object?> get props => [ccp, rib, accountName];
}
