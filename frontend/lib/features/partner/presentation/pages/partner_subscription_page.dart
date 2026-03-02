import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/partner_subscription_bloc.dart';

class PartnerSubscriptionPage extends StatefulWidget {
  const PartnerSubscriptionPage({super.key});

  @override
  State<PartnerSubscriptionPage> createState() =>
      _PartnerSubscriptionPageState();
}

class _PartnerSubscriptionPageState extends State<PartnerSubscriptionPage> {
  String _selectedPlan = 'monthly';
  String _selectedMethod = 'online'; // 'online' | 'manual' | 'cash'
  final TextEditingController _referenceController = TextEditingController();

  static const double _monthlyPrice = 2000;
  static const double _yearlyPrice = 18000;
  static const int _yearlySavingPercent = 25;

  @override
  void initState() {
    super.initState();
    context.read<PartnerSubscriptionBloc>().add(const LoadSubscriptionStatus());
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
          if (state is CheckoutSessionCreated) {
            await _openCheckout(state.checkoutUrl);
          } else if (state is ManualPaymentRequested) {
            if (context.mounted) {
              _showManualConfirmation(state.invoice, state.bankDetails);
            }
          } else if (state is SubscriptionCancelled) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abonnement annulé'),
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
                        onTap: () => Navigator.of(context).pop(),
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
                        'Envie de vous abonner ?',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Text(
                        'Rendez vos établissements visibles et attirez de nouveaux clients.',
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
                      plan: 'monthly',
                      title: '${_monthlyPrice.toStringAsFixed(0)} DA / mois',
                      subtitle: 'sans engagement',
                      badge: null,
                      isSelected: _selectedPlan == 'monthly',
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    _buildPlanCard(
                      plan: 'yearly',
                      title: '${_yearlyPrice.toStringAsFixed(0)} DA / an',
                      subtitle:
                          'soit ${(_yearlyPrice / 12).toStringAsFixed(0)} DA/mois',
                      badge: 'Économisez $_yearlySavingPercent%',
                      isSelected: _selectedPlan == 'yearly',
                    ),

                    const SizedBox(height: AppDimens.paddingXL),

                    // Sélecteur méthode de paiement
                    if ((currentStatus == null || !currentStatus.isActive) &&
                        currentStatus?.hasPendingPayment != true) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Méthode de paiement',
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
                              label: 'En ligne',
                              subtitle: 'CIB / EDAHABIA',
                              isSelected: _selectedMethod == 'online',
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Expanded(
                            child: _buildMethodCard(
                              method: 'manual',
                              icon: Iconsax.money_send,
                              label: 'Virement',
                              subtitle: 'CCP / Banque',
                              isSelected: _selectedMethod == 'manual',
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Expanded(
                            child: _buildMethodCard(
                              method: 'cash',
                              icon: Iconsax.money,
                              label: 'Espèces',
                              subtitle: 'En bureau',
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
                                'Effectuez votre virement puis soumettez votre demande. L\'admin validera dans les 24-48h.',
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
                                  hintText: 'Référence du virement (optionnel)',
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
                                    'Paiement en agence',
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
                                'Soumettez votre demande, puis rendez-vous à notre bureau pour régler en espèces. L\'admin validera votre paiement sur place.',
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
                                        ? 'Soumettre ma demande'
                                        : _selectedMethod == 'cash'
                                            ? 'Je confirme ma visite'
                                            : 'J\'en profite',
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard({
    required String plan,
    required String title,
    required String subtitle,
    required String? badge,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingL,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected
                ? AppColors.greenAccent
                : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          )),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.greenAccent, size: 20),
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
                'Paiement en cours de validation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                'Votre demande a bien été enregistrée. Notre équipe la validera dans les 24–48h. Votre accès sera activé dès confirmation.',
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
            'Actualiser le statut',
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
                      'Abonnement actif — ${status.planLabel}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (status.subscriptionEndsAt != null)
                      Text(
                        'Expire le ${_formatDate(status.subscriptionEndsAt!)}',
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
          'Vos établissements sont visibles sur l\'application.',
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
                  'Annuler l\'abonnement',
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
        title: const Text('Annuler l\'abonnement'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement ?\n\n'
          'Vos établissements ne seront plus visibles sur l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Garder'),
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
            child: const Text('Annuler l\'abonnement'),
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
        const SnackBar(
          content: Text('Impossible d\'ouvrir la page de paiement'),
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
            const Text('Demande soumise',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre demande a été enregistrée (${invoice.invoiceNumber}).',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: AppDimens.paddingM),
            if (isCash) ...[
              const Text('Rendez-vous à notre bureau :',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              _infoRow(Iconsax.buildings, 'N° 12, Rue Didouche Mourad, Alger'),
              _infoRow(Iconsax.clock, 'Lun – Sam : 8h00 – 17h00'),
              _infoRow(Iconsax.call, '0560 000 000'),
              const SizedBox(height: AppDimens.paddingM),
              const Text(
                'Munissez-vous de votre numéro de demande. L\'admin validera votre paiement sur place.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ] else ...[
              const Text('Coordonnées bancaires :',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              _bankRow('CCP', bankDetails.ccp),
              _bankRow('RIB', bankDetails.rib),
              _bankRow('Bénéficiaire', bankDetails.accountName),
              const SizedBox(height: AppDimens.paddingM),
              const Text(
                'L\'admin validera votre paiement sous 24-48h.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen),
            child: const Text('Compris'),
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
