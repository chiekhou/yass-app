import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../bloc/admin_payments_bloc.dart';
import '../widgets/admin_drawer.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminPaymentsBloc>().add(const LoadPendingPayments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(context.l10n.pendingPayments),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminPendingPayments),
      body: BlocConsumer<AdminPaymentsBloc, AdminPaymentsState>(
        listener: (context, state) {
          if (state is AdminPaymentValidated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.paymentValidated),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<AdminPaymentsBloc>().add(const LoadPendingPayments());
          } else if (state is AdminPaymentCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.paymentCancelledAdmin),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<AdminPaymentsBloc>().add(const LoadPendingPayments());
          } else if (state is AdminPaymentsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminPaymentsLoading ||
              state is AdminPaymentValidating ||
              state is AdminPaymentCancelling) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is AdminPaymentsError) {
            return _buildError(state.message);
          }

          if (state is AdminPaymentsLoaded) {
            if (state.invoices.isEmpty) return _buildEmpty();

            return Column(
              children: [
                _buildHeader(context, state.invoices.length),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () async {
                      context
                          .read<AdminPaymentsBloc>()
                          .add(const LoadPendingPayments());
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppDimens.paddingL),
                      itemCount: state.invoices.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimens.paddingM),
                      itemBuilder: (context, index) =>
                          _buildPaymentCard(context, state.invoices[index]),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: const Icon(
              Iconsax.money_recive,
              color: AppColors.warning,
              size: AppDimens.iconM,
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count paiement${count > 1 ? 's' : ''} à valider',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  context.l10n.verifyManualPayments,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────────

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> invoice) {
    final invoiceId = invoice['id'] as String? ?? '';
    final invoiceNumber = invoice['invoice_number'] as String? ?? '—';
    final plan = invoice['plan'] as String? ?? 'monthly';
    final isYearly = plan == 'yearly';
    final planLabel = isYearly ? context.l10n.planYearly : context.l10n.planMonthly;
    final amount = invoice['amount'] ?? 0;
    final createdAt = invoice['created_at'] != null
        ? DateTime.tryParse(invoice['created_at'])
        : null;
    final transferRef = invoice['transfer_reference'] as String?;
    final partner = invoice['partner'] as Map<String, dynamic>?;
    final companyName = partner?['company_name'] as String? ?? 'Partenaire';
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'P';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bande supérieure : société + statut ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusM),
              ),
              border: const Border(
                left: BorderSide(color: AppColors.warning, width: 3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey900,
                            ),
                      ),
                      Text(
                        invoiceNumber,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                ),
                // Badge "En attente"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.clock,
                          size: 11, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.statusPending,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Montant + Plan ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingM,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$amount DZD',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey900,
                            ),
                      ),
                      Text(
                        context.l10n.totalAmount,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isYearly
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isYearly ? Iconsax.crown : Iconsax.calendar,
                        size: 14,
                        color: isYearly
                            ? AppColors.primaryGreen
                            : AppColors.grey600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        planLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isYearly
                                  ? AppColors.primaryGreen
                                  : AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Détails ──────────────────────────────────────────────────────
          if ((transferRef != null && transferRef.isNotEmpty) ||
              createdAt != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
              child: Column(
                children: [
                  if (transferRef != null && transferRef.isNotEmpty)
                    _detailRow(context, Iconsax.document_text, context.l10n.refLabel,
                        transferRef),
                  if (createdAt != null)
                    _detailRow(context, Iconsax.calendar, context.l10n.submittedOn,
                        _formatDate(createdAt)),
                ],
              ),
            ),

          const SizedBox(height: AppDimens.paddingM),
          const Divider(height: 1, color: AppColors.grey100),

          // ── Boutons Valider / Annuler ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _confirmCancel(context, invoiceId, companyName),
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      label: Text(context.l10n.cancel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _confirmValidate(context, invoiceId, companyName),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: Text(context.l10n.validate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.scaffoldBackground,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey400),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.grey500),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _confirmValidate(
      BuildContext context, String invoiceId, String companyName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: Text(context.l10n.confirmValidation),
        content: Text(context.l10n.validatePaymentQuestion(companyName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminPaymentsBloc>().add(ValidatePayment(invoiceId));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen),
            child: Text(context.l10n.validate),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(
      BuildContext context, String invoiceId, String companyName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: Text(context.l10n.cancelPaymentTitle),
        content: Text(context.l10n.cancelPaymentQuestion(companyName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.noLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminPaymentsBloc>().add(CancelPayment(invoiceId));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white),
            child: Text(context.l10n.yesCancel),
          ),
        ],
      ),
    );
  }

  // ── États vide / erreur ──────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              context.l10n.allUpToDate,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              context.l10n.noPaymentPending,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<AdminPaymentsBloc>()
                  .add(const LoadPendingPayments()),
              icon: const Icon(Iconsax.refresh),
              label: Text(context.l10n.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              context.l10n.loadingError,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<AdminPaymentsBloc>()
                  .add(const LoadPendingPayments()),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
