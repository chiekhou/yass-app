import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/partner_invoices_bloc.dart';

class PartnerInvoicesPage extends StatefulWidget {
  const PartnerInvoicesPage({super.key});

  @override
  State<PartnerInvoicesPage> createState() => _PartnerInvoicesPageState();
}

class _PartnerInvoicesPageState extends State<PartnerInvoicesPage> {
  @override
  void initState() {
    super.initState();
    context.read<PartnerInvoicesBloc>().add(const LoadInvoices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        title: const Text('Mes factures',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: BlocBuilder<PartnerInvoicesBloc, PartnerInvoicesState>(
        builder: (context, state) {
          if (state is InvoicesLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (state is InvoicesError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.white38, size: 48),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(state.message,
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppDimens.paddingM),
                  TextButton(
                    onPressed: () => context
                        .read<PartnerInvoicesBloc>()
                        .add(const LoadInvoices()),
                    child: const Text('Réessayer',
                        style: TextStyle(color: AppColors.primaryGreen)),
                  ),
                ],
              ),
            );
          }

          if (state is InvoicesLoaded) {
            if (state.invoices.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<PartnerInvoicesBloc>()
                  .add(const LoadInvoices()),
              color: AppColors.primaryGreen,
              backgroundColor: const Color(0xFF1A1A1A),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                itemCount: state.invoices.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimens.paddingM),
                itemBuilder: (context, index) =>
                    _InvoiceCard(invoice: state.invoices[index]),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.receipt_item, color: Colors.white24, size: 64),
          const SizedBox(height: AppDimens.paddingL),
          Text('Aucune facture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: AppDimens.paddingS),
          Text('Vos factures apparaîtront ici après votre premier paiement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
              textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.paddingXL),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.partnerSubscription),
            icon: const Icon(Iconsax.star, size: 18),
            label: const Text('S\'abonner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingXL,
                  vertical: AppDimens.paddingM),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.partnerInvoiceDetail(invoice.id)),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // Icône méthode
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: invoice.isOnline
                    ? AppColors.info.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Icon(
                invoice.isOnline ? Iconsax.card : Iconsax.money_send,
                color: invoice.isOnline ? AppColors.info : AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${invoice.planLabel} · ${invoice.paymentMethodLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(invoice.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white38,
                        ),
                  ),
                ],
              ),
            ),

            // Montant + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${invoice.amount.toStringAsFixed(0)} ${invoice.currency}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: invoice.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'paid':
        color = AppColors.success;
        label = 'Payé';
        break;
      case 'pending_validation':
        color = AppColors.warning;
        label = 'En attente';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Échoué';
        break;
      case 'cancelled':
        color = Colors.white38;
        label = 'Annulé';
        break;
      default:
        color = Colors.white38;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
