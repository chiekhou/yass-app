import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/partner_invoices_bloc.dart';

class PartnerInvoiceDetailPage extends StatefulWidget {
  final String invoiceId;

  const PartnerInvoiceDetailPage({super.key, required this.invoiceId});

  @override
  State<PartnerInvoiceDetailPage> createState() =>
      _PartnerInvoiceDetailPageState();
}

class _PartnerInvoiceDetailPageState extends State<PartnerInvoiceDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<PartnerInvoicesBloc>()
        .add(LoadInvoiceDetail(widget.invoiceId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text('Reçu de paiement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: BlocBuilder<PartnerInvoicesBloc, PartnerInvoicesState>(
        builder: (context, state) {
          if (state is InvoicesLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (state is InvoicesError) {
            return Center(
              child: Text(state.message,
                  style: const TextStyle(color: Colors.white54)),
            );
          }
          if (state is InvoiceDetailLoaded) {
            return _buildReceipt(state.invoice);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildReceipt(Invoice invoice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        children: [
          // Carte reçu
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: Column(
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  decoration: const BoxDecoration(
                    color: Color(0xFF006233),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppDimens.radiusL),
                      topRight: Radius.circular(AppDimens.radiusL),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Win-وين',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                          ),
                          _buildStatusBadgeLight(invoice.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Reçu de paiement',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ),

                // Corps du reçu
                Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Column(
                    children: [
                      // Numéro de facture + date
                      _buildReceiptRow(
                        label: 'N° Facture',
                        value: invoice.invoiceNumber,
                        bold: true,
                      ),
                      _buildDivider(),
                      _buildReceiptRow(
                        label: 'Date',
                        value: _formatDate(invoice.createdAt),
                      ),
                      if (invoice.paidAt != null) ...[
                        _buildDivider(),
                        _buildReceiptRow(
                          label: 'Payé le',
                          value: _formatDate(invoice.paidAt!),
                        ),
                      ],
                      _buildDivider(),
                      _buildReceiptRow(
                        label: 'Plan',
                        value: invoice.planLabel,
                      ),
                      _buildDivider(),
                      _buildReceiptRow(
                        label: 'Méthode',
                        value: invoice.paymentMethodLabel,
                      ),
                      if (invoice.transferReference != null) ...[
                        _buildDivider(),
                        _buildReceiptRow(
                          label: 'Référence',
                          value: invoice.transferReference!,
                        ),
                      ],
                      if (invoice.periodStart != null &&
                          invoice.periodEnd != null) ...[
                        _buildDivider(),
                        _buildReceiptRow(
                          label: 'Période',
                          value:
                              '${_formatDateShort(invoice.periodStart!)} → ${_formatDateShort(invoice.periodEnd!)}',
                        ),
                      ],

                      // Séparateur pointillé
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                        child: _DottedDivider(),
                      ),

                      // Montant total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '${invoice.amount.toStringAsFixed(0)} ${invoice.currency}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF006233),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pied du reçu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.paddingM,
                      horizontal: AppDimens.paddingL),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimens.radiusL),
                      bottomRight: Radius.circular(AppDimens.radiusL),
                    ),
                  ),
                  child: Text(
                    'Merci de faire confiance à Win-وين',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black45,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Message si en attente
          if (invoice.isPending) ...[
            const SizedBox(height: AppDimens.paddingL),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.clock, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: Text(
                      'Votre paiement est en cours de validation. L\'admin activera votre abonnement sous 24-48h.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1);
  }

  Widget _buildStatusBadgeLight(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid':
        color = Colors.greenAccent;
        label = '✓ Payé';
        break;
      case 'pending_validation':
        color = Colors.orangeAccent;
        label = '⏳ En attente';
        break;
      case 'failed':
        color = Colors.redAccent;
        label = '✗ Échoué';
        break;
      default:
        color = Colors.white54;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(
              width: dashWidth,
              height: 1,
              color: const Color(0xFFDDDDDD),
            ),
          ),
        );
      },
    );
  }
}
