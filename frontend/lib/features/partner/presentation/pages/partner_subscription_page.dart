import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/partner_subscription_bloc.dart';

class PartnerSubscriptionPage extends StatefulWidget {
  final String? paymentResult; // 'success' | 'failed' | null

  const PartnerSubscriptionPage({super.key, this.paymentResult});

  @override
  State<PartnerSubscriptionPage> createState() =>
      _PartnerSubscriptionPageState();
}

class _PartnerSubscriptionPageState extends State<PartnerSubscriptionPage> {
  String _selectedPlan = 'basic';
  String _selectedMethod = 'online'; // 'online' | 'manual' | 'cash'
  final TextEditingController _referenceController = TextEditingController();

  static const double _monthlyPrice = 5000;
  static const double _yearlyPrice = 50000;
  static const int _yearlySavingPercent = 17;

  @override
  void initState() {
    super.initState();
    context.read<PartnerSubscriptionBloc>().add(const LoadSubscriptionStatus());
    if (widget.paymentResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.paymentResult == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.paymentAccepted),
              backgroundColor: Colors.green,
            ),
          );
        } else if (widget.paymentResult == 'failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.paymentFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PartnerSubscriptionBloc, PartnerSubscriptionState>(
        listener: (context, state) async {
          if (state is SubscriptionLoaded && state.status.isActive) {
            setState(() => _selectedPlan = _planToKey(state.status.plan));
          } else if (state is CheckoutSessionCreated) {
            await _openCheckout(state.checkoutUrl);
          } else if (state is ManualPaymentRequested) {
            if (context.mounted) {
              _showManualConfirmation(state.invoice, state.bankDetails);
            }
          } else if (state is SubscriptionCancelled) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.subscriptionCancelled),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
              context
                  .read<PartnerSubscriptionBloc>()
                  .add(const LoadSubscriptionStatus());
            }
          } else if (state is SubscriptionError) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is SubscriptionLoading;
          final currentStatus =
              state is SubscriptionLoaded ? state.status : null;

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                    vertical: AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bouton fermer
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/partner');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppDimens.paddingS),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusS),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.paddingXL),

                    if (currentStatus != null && currentStatus.isActive) ...[
                      _buildActiveStatus(currentStatus),
                    ] else if (currentStatus?.hasPendingPayment == true) ...[
                      _buildPendingPaymentBanner(),
                    ] else ...[
                      Text(
                        context.l10n.chooseYourOffer,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Text(
                        context.l10n.subscriptionPageSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: AppDimens.paddingXL),

                    // Cards de plan
                    _buildPlanCard(
                      plan: 'basic',
                      planLabel: 'Basic',
                      title: context.l10n.freePlan,
                      subtitle: context.l10n.alwaysFree,
                      badge: null,
                      isSelected: _selectedPlan == 'basic',
                      isLocked: currentStatus?.isActive ?? false,
                      features: [
                        context.l10n.featureEstablishmentProfile,
                        context.l10n.featureContactLocation,
                      ],
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    _buildPlanCard(
                      plan: 'monthly',
                      planLabel: 'Premium',
                      title: context.l10n.pricePerMonth(_monthlyPrice.toStringAsFixed(0)),
                      subtitle: context.l10n.noCommitment,
                      badge: null,
                      isSelected: _selectedPlan == 'monthly',
                      isLocked: currentStatus?.isActive ?? false,
                      features: [
                        context.l10n.featureAllBasicIncluded,
                        context.l10n.featureWhatsappButton,
                        context.l10n.featureSocialNetworks,
                        context.l10n.featurePhotoGallery,
                        context.l10n.featureCustomerReviews,
                      ],
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    _buildPlanCard(
                      plan: 'yearly',
                      planLabel: 'Gold',
                      title: context.l10n.pricePerYear(_yearlyPrice.toStringAsFixed(0)),
                      subtitle: context.l10n.monthlyEquivalent((_yearlyPrice / 12).toStringAsFixed(0)),
                      badge: context.l10n.savingPercent(_yearlySavingPercent),
                      isSelected: _selectedPlan == 'yearly',
                      isLocked: currentStatus?.isActive ?? false,
                      features: [
                        context.l10n.featureAllPremiumIncluded,
                        context.l10n.featureFeaturedListing,
                        context.l10n.featurePriorityResults,
                        context.l10n.featureGoldBadge,
                      ],
                    ),

                    const SizedBox(height: AppDimens.paddingXL),

                    // Sélecteur méthode de paiement
                    if ((currentStatus == null || !currentStatus.isActive) &&
                        currentStatus?.hasPendingPayment != true &&
                        _selectedPlan != 'basic') ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.paymentMethodLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMethodCard(
                              method: 'online',
                              icon: Iconsax.card,
                              label: context.l10n.paymentOnline,
                              subtitle: 'CIB / EDAHABIA',
                              isSelected: _selectedMethod == 'online',
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Expanded(
                            child: _buildMethodCard(
                              method: 'manual',
                              icon: Iconsax.money_send,
                              label: context.l10n.paymentTransfer,
                              subtitle: 'CCP / Banque',
                              isSelected: _selectedMethod == 'manual',
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Expanded(
                            child: _buildMethodCard(
                              method: 'cash',
                              icon: Iconsax.money,
                              label: context.l10n.paymentCash,
                              subtitle: context.l10n.inOffice,
                              isSelected: _selectedMethod == 'cash',
                            ),
                          ),
                        ],
                      ),

                      // Infos selon méthode de paiement
                      if (_selectedMethod == 'manual') ...[
                        const SizedBox(height: AppDimens.paddingL),
                        Container(
                          padding: const EdgeInsets.all(AppDimens.paddingM),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.transferInstructions,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: AppDimens.paddingM),
                              TextField(
                                controller: _referenceController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: context.l10n.transferRefHint,
                                  hintStyle: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.35)),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusS),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Iconsax.document_text,
                                      color: Colors.white38, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_selectedMethod == 'cash') ...[
                        const SizedBox(height: AppDimens.paddingL),
                        Container(
                          padding: const EdgeInsets.all(AppDimens.paddingM),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Iconsax.location,
                                      color: AppColors.greenAccent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.l10n.inAgencyPayment,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimens.paddingS),
                              Text(
                                context.l10n.cashInstructions,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: AppDimens.paddingM),
                              _infoRow(Iconsax.buildings,
                                  'N° 12, Rue Didouche Mourad, Alger'),
                              _infoRow(
                                  Iconsax.clock, 'Lun – Sam : 8h00 – 17h00'),
                              _infoRow(Iconsax.call, '0560 000 000'),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppDimens.paddingXL),

                      // Bouton CTA
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryGreen,
                                      AppColors.greenLight,
                                      AppColors.primaryRed,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusL),
                                ),
                                child: ElevatedButton(
                                  onPressed: _onSubscribeTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppDimens.radiusL),
                                    ),
                                  ),
                                  child: Text(
                                    _selectedMethod == 'manual'
                                        ? context.l10n.submitMyRequest
                                        : _selectedMethod == 'cash'
                                            ? context.l10n.confirmMyVisit
                                            : context.l10n.takeAdvantage,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.paddingXL),

                    // ─── Toutes les fonctionnalités ───────────────────────
                    _buildAllFeatures(
                      context,
                      currentPlan: currentStatus?.plan ?? 'free',
                    ),

                    const SizedBox(height: AppDimens.paddingXL),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getAllFeatures(BuildContext context) => [
    {
      'label': context.l10n.featureEstablishmentProfile,
      'icon': Iconsax.building,
      'plan': 'basic',
    },
    {
      'label': context.l10n.featureContactLocation,
      'icon': Iconsax.location,
      'plan': 'basic',
    },
    {
      'label': context.l10n.featureAppointmentBooking,
      'icon': Iconsax.calendar,
      'plan': 'basic',
    },
    {
      'label': context.l10n.featureWhatsappButton,
      'icon': Iconsax.message,
      'plan': 'premium',
    },
    {
      'label': context.l10n.featureSocialNetworks,
      'icon': Iconsax.share,
      'plan': 'premium',
    },
    {
      'label': context.l10n.featurePhotoGallery,
      'icon': Iconsax.gallery,
      'plan': 'premium',
    },
    {
      'label': context.l10n.featureCustomerReviews,
      'icon': Iconsax.star,
      'plan': 'premium',
    },
    {
      'label': context.l10n.featureFeaturedListing,
      'icon': Iconsax.award,
      'plan': 'gold',
    },
    {
      'label': context.l10n.featurePriorityResults,
      'icon': Iconsax.ranking,
      'plan': 'gold',
    },
    {
      'label': context.l10n.featureGoldBadge,
      'icon': Iconsax.medal,
      'plan': 'gold',
    },
  ];

  String _planToKey(String plan) {
    switch (plan) {
      case 'premium':
        return 'monthly';
      case 'gold':
        return 'yearly';
      default:
        return 'basic';
    }
  }

  int _planLevel(String plan) {
    switch (plan) {
      case 'premium':
        return 1;
      case 'gold':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildAllFeatures(BuildContext context,
      {required String currentPlan}) {
    final currentLevel = _planLevel(currentPlan);

    // tri: disponible d'abord, verrouillé ensuite
    final sorted = [..._getAllFeatures(context)]..sort((a, b) {
        final aLocked = _planLevel(a['plan'] as String) > currentLevel ? 1 : 0;
        final bLocked = _planLevel(b['plan'] as String) > currentLevel ? 1 : 0;
        return aLocked.compareTo(bLocked);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.allFeatures,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              final featurePlan = f['plan'] as String;
              final isLocked = _planLevel(featurePlan) > currentLevel;
              final isLast = i == sorted.length - 1;

              final planBadge = featurePlan == 'gold'
                  ? 'Gold'
                  : featurePlan == 'premium'
                      ? 'Premium'
                      : null;

              return Column(
                children: [
                  InkWell(
                    onTap: isLocked
                        ? () => _showLockedFeatureDialog(
                              context,
                              featureName: f['label'] as String,
                              requiredPlan: featurePlan,
                            )
                        : null,
                    borderRadius: BorderRadius.vertical(
                      top: i == 0
                          ? const Radius.circular(AppDimens.radiusM)
                          : Radius.zero,
                      bottom: isLast
                          ? const Radius.circular(AppDimens.radiusM)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingM,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            f['icon'] as IconData,
                            size: 18,
                            color: isLocked
                                ? Colors.white24
                                : featurePlan == 'gold'
                                    ? const Color(0xFFFFD700)
                                    : AppColors.greenAccent,
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          Expanded(
                            child: Text(
                              f['label'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isLocked
                                        ? Colors.white38
                                        : Colors.white,
                                  ),
                            ),
                          ),
                          if (planBadge != null && isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: featurePlan == 'gold'
                                    ? const Color(0xFFFFD700)
                                        .withValues(alpha: 0.15)
                                    : AppColors.primaryGreen
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                planBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: featurePlan == 'gold'
                                      ? const Color(0xFFFFD700)
                                      : AppColors.greenAccent,
                                ),
                              ),
                            )
                          else if (!isLocked)
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: AppColors.greenAccent)
                          else
                            const Icon(Icons.lock_rounded,
                                size: 14, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showLockedFeatureDialog(
    BuildContext context, {
    required String featureName,
    required String requiredPlan,
  }) {
    final planLabel = requiredPlan == 'gold' ? 'Gold' : 'Premium';
    final planColor = requiredPlan == 'gold'
        ? const Color(0xFFFFD700)
        : AppColors.greenAccent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: planColor, size: 20),
            const SizedBox(width: 8),
            Text(
              context.l10n.featureOfPlan(planLabel),
              style: TextStyle(
                color: planColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '« $featureName »',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              context.l10n.featureAvailableFromPlan(planLabel),
              style: const TextStyle(
                color: Colors.white60,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(context.l10n.close, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedPlan = requiredPlan == 'gold' ? 'yearly' : 'monthly';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: planColor,
              foregroundColor: Colors.black,
            ),
            child: Text(context.l10n.seePlan(planLabel)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String plan,
    required String planLabel,
    required String title,
    required String subtitle,
    required String? badge,
    required bool isSelected,
    required bool isLocked,
    required List<String> features,
  }) {
    final accentColor =
        plan == 'yearly' ? const Color(0xFFFFD700) : AppColors.greenAccent;

    return GestureDetector(
      onTap: isLocked ? null : () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingL,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color:
                isSelected ? accentColor : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  )),
                      Text(subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  )),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: Text(badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )),
                  )
                else if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: accentColor, size: 20),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String method,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            vertical: AppDimens.paddingM, horizontal: AppDimens.paddingS),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected
                ? AppColors.greenAccent
                : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.greenAccent : Colors.white38,
                size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )),
            Text(subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentBanner() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.paddingL),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Iconsax.clock, color: AppColors.warning, size: 40),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                context.l10n.paymentPendingValidation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                context.l10n.paymentPendingDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingL),
        TextButton.icon(
          onPressed: () => context
              .read<PartnerSubscriptionBloc>()
              .add(const LoadSubscriptionStatus()),
          icon: const Icon(Iconsax.refresh, color: Colors.white54, size: 16),
          label: Text(
            context.l10n.refreshStatus,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveStatus(SubscriptionStatus status) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.tick_circle,
                  color: AppColors.primaryGreen, size: 32),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.activeSubscriptionPlan(status.planLabel),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (status.subscriptionEndsAt != null)
                      Text(
                        context.l10n.expiresOn(_formatDate(status.subscriptionEndsAt!)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        Text(
          context.l10n.establishmentsVisibleOnApp,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.paddingL),
        GestureDetector(
          onTap: _confirmCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.close_circle, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  context.l10n.cancelSubscription,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: Text(context.l10n.cancelSubscription),
        content: Text(context.l10n.confirmCancelSubscriptionContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.keepSubscription),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<PartnerSubscriptionBloc>()
                  .add(const CancelSubscription());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.cancelSubscription),
          ),
        ],
      ),
    );
  }

  void _onSubscribeTap() {
    if (_selectedMethod == 'online') {
      context.read<PartnerSubscriptionBloc>().add(
            CreateCheckout(plan: _selectedPlan),
          );
    } else {
      context.read<PartnerSubscriptionBloc>().add(
            RequestManualPayment(
              plan: _selectedPlan,
              transferReference: _selectedMethod == 'manual' &&
                      _referenceController.text.trim().isNotEmpty
                  ? _referenceController.text.trim()
                  : null,
            ),
          );
    }
  }

  Future<void> _openCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cannotOpenPaymentPage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showManualConfirmation(Invoice invoice, BankDetails bankDetails) {
    final isCash = _selectedMethod == 'cash';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.greenDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(context.l10n.requestSubmitted,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.requestRegisteredWithNumber(invoice.invoiceNumber),
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: AppDimens.paddingM),
            if (isCash) ...[
              Text(context.l10n.visitOurOffice,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              _infoRow(Iconsax.buildings, 'N° 12, Rue Didouche Mourad, Alger'),
              _infoRow(Iconsax.clock, 'Lun – Sam : 8h00 – 17h00'),
              _infoRow(Iconsax.call, '0560 000 000'),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                context.l10n.bringRequestNumber,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ] else ...[
              Text(context.l10n.bankDetailsColon,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              _bankRow('CCP', bankDetails.ccp),
              _bankRow('RIB', bankDetails.rib),
              _bankRow(context.l10n.beneficiary, bankDetails.accountName),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                context.l10n.adminValidates24_48h,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen),
            child: Text(context.l10n.understood),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.greenAccent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
