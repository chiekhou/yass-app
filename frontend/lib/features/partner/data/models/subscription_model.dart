import 'package:equatable/equatable.dart';

class SubscriptionStatus extends Equatable {
  final String plan; // free | premium | gold
  final String planLabel; // Gratuit | Mensuel | Annuel
  final bool isInTrial;
  final bool isActive;
  final bool trialExpired;
  final bool isVisible; // isInTrial || isActive
  final int daysRemaining;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final String? chargilyCheckoutId;
  final bool hasPendingPayment;

  const SubscriptionStatus({
    required this.plan,
    required this.planLabel,
    required this.isInTrial,
    required this.isActive,
    required this.trialExpired,
    required this.isVisible,
    required this.daysRemaining,
    this.trialEndsAt,
    this.subscriptionEndsAt,
    this.chargilyCheckoutId,
    this.hasPendingPayment = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan'] ?? 'free',
      planLabel: json['plan_label'] ?? 'Gratuit',
      isInTrial: json['is_in_trial'] ?? false,
      isActive: json['is_active'] ?? false,
      trialExpired: json['trial_expired'] ?? true,
      isVisible: json['is_visible'] ?? false,
      daysRemaining: json['days_remaining'] ?? 0,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'])
          : null,
      subscriptionEndsAt: json['subscription_ends_at'] != null
          ? DateTime.parse(json['subscription_ends_at'])
          : null,
      chargilyCheckoutId: json['chargily_checkout_id'],
      hasPendingPayment: json['has_pending_payment'] ?? false,
    );
  }

  @override
  List<Object?> get props => [plan, isInTrial, isActive, daysRemaining, hasPendingPayment];
}
