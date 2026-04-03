import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/admin_partner_model.dart';
import '../bloc/admin_partners_bloc.dart';

class AdminPartnerDetailPage extends StatelessWidget {
  const AdminPartnerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPartnersBloc, AdminPartnersState>(
      listener: (context, state) {
        if (state is AdminPartnersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminPartnerDetailsLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left),
                onPressed: () => context.go(AppRoutes.adminPartners),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AdminPartnerDetailsLoaded) {
          return _PartnerDetailView(
            partner: state.partner,
            isUpdating: state.isUpdating,
          );
        }

        if (state is AdminPartnersError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left),
                onPressed: () => context.go(AppRoutes.adminPartners),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey600)),
                ],
              ),
            ),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class _PartnerDetailView extends StatelessWidget {
  final AdminPartner partner;
  final bool isUpdating;

  const _PartnerDetailView({
    required this.partner,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(
          partner.companyName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.go(AppRoutes.adminPartners),
        ),
        actions: [
          _StatusBadgeChip(status: partner.status),
          const SizedBox(width: AppDimens.paddingS),
        ],
      ),
      body: isUpdating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartnerInfoCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  if (partner.user != null) ...[
                    _buildUserInfoCard(context),
                    const SizedBox(height: AppDimens.paddingM),
                  ],
                  _buildActionCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  _buildEstablishmentsSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildPartnerInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: Center(
                    child: Text(
                      partner.companyName.isNotEmpty
                          ? partner.companyName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.companyName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                ),
                      ),
                      const SizedBox(height: AppDimens.paddingXS),
                      Text(
                        'Plan: ${partner.subscriptionPlan}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            const Divider(),
            const SizedBox(height: AppDimens.paddingS),
            _infoRow(context, Iconsax.building,
                '${partner.establishmentsCount} établissement(s)'),
            if (partner.registrationNumber != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              _infoRow(context, Iconsax.document,
                  'RC: ${partner.registrationNumber}'),
            ],
            if (partner.taxId != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              _infoRow(context, Iconsax.receipt, 'NIF: ${partner.taxId}'),
            ],
            const SizedBox(height: AppDimens.paddingS),
            _infoRow(
              context,
              Iconsax.calendar,
              'Créé le ${_formatDate(partner.createdAt)}',
            ),
            if (partner.verifiedAt != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              _infoRow(
                context,
                Iconsax.verify5,
                'Vérifié le ${_formatDate(partner.verifiedAt!)}',
                color: AppColors.success,
              ),
            ],
            if (partner.rejectionReason != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.close_circle,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: AppDimens.paddingXS),
                    Expanded(
                      child: Text(
                        'Motif de rejet: ${partner.rejectionReason}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (partner.suspensionReason != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.slash, size: 14, color: AppColors.warning),
                    const SizedBox(width: AppDimens.paddingXS),
                    Expanded(
                      child: Text(
                        'Motif de suspension: ${partner.suspensionReason}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final user = partner.user!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Responsable du compte',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey200,
                  backgroundImage: user.avatar != null
                      ? NetworkImage(user.avatar!)
                      : null,
                  child: user.avatar == null
                      ? Text(
                          user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey900,
                                ),
                      ),
                      const SizedBox(height: AppDimens.paddingXS),
                      _infoRow(context, Iconsax.sms, user.email),
                      if (user.phone != null) ...[
                        const SizedBox(height: AppDimens.paddingXS),
                        _infoRow(context, Iconsax.call, user.phone!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            // Approve button for any non-approved status
            if (!partner.isApproved) ...[
              Row(
                children: [
                  if (partner.isPending)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showRejectDialog(context, partner.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDimens.paddingS),
                        ),
                        icon: const Icon(Iconsax.close_circle, size: 16),
                        label: const Text('Rejeter'),
                      ),
                    ),
                  if (partner.isPending)
                    const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<AdminPartnersBloc>().add(
                            AdminPartnerApprove(partnerId: partner.id),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingS),
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 16),
                      label: const Text('Approuver'),
                    ),
                  ),
                ],
              ),
            ],
            // Actions for approved partners
            if (partner.isApproved) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showSuspendDialog(context, partner.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingS),
                      ),
                      icon: const Icon(Iconsax.slash, size: 16),
                      label: const Text('Suspendre'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.adminCreateEstablishment,
                        extra: {
                          'partnerId': partner.id,
                          'partnerName': partner.companyName,
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.paddingS),
                      ),
                      icon: const Icon(Iconsax.add_square, size: 16),
                      label: const Text('Ajouter établ.'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentsSection(BuildContext context) {
    final establishments = partner.establishments;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Établissements',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  child: Text(
                    '${partner.establishmentsCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            if (establishments == null || establishments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.paddingL),
                  child: Column(
                    children: [
                      Icon(Iconsax.building,
                          size: 40, color: AppColors.grey300),
                      const SizedBox(height: AppDimens.paddingS),
                      Text(
                        'Aucun établissement',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: establishments.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: AppDimens.paddingM),
                itemBuilder: (context, index) {
                  final est = establishments[index];
                  return _buildEstablishmentItem(context, est);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentItem(
      BuildContext context, PartnerEstablishmentSummary est) {
    Color statusColor;
    switch (est.status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey500;
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: const Icon(Iconsax.building, size: 20, color: AppColors.grey600),
        ),
        const SizedBox(width: AppDimens.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                est.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              if (est.categoryName != null || est.communeName != null)
                Text(
                  [est.categoryName, est.communeName]
                      .where((e) => e != null)
                      .join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.paddingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingS,
            vertical: AppDimens.paddingXS,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusXS),
          ),
          child: Text(
            est.statusLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
          ),
        ),
        const SizedBox(width: AppDimens.paddingXS),
        IconButton(
          icon: const Icon(Iconsax.trash, size: 18, color: AppColors.error),
          tooltip: 'Supprimer',
          onPressed: () => _showDeleteEstablishmentDialog(context, est),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _showDeleteEstablishmentDialog(
      BuildContext context, PartnerEstablishmentSummary est) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'établissement'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${est.name}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminPartnersBloc>().add(
                    AdminEstablishmentDelete(
                      establishmentId: est.id,
                      partnerId: partner.id,
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.grey500),
        const SizedBox(width: AppDimens.paddingXS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? AppColors.grey600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showRejectDialog(BuildContext context, String partnerId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter le partenaire'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Motif du rejet',
            hintText: 'Expliquez la raison du rejet...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().length >= 10) {
                context.read<AdminPartnersBloc>().add(
                      AdminPartnerReject(
                        partnerId: partnerId,
                        reason: reasonCtrl.text.trim(),
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, String partnerId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suspendre le partenaire'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Motif de suspension',
            hintText: 'Expliquez la raison de la suspension...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().length >= 10) {
                context.read<AdminPartnersBloc>().add(
                      AdminPartnerSuspend(
                        partnerId: partnerId,
                        reason: reasonCtrl.text.trim(),
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.white),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeChip extends StatelessWidget {
  final String status;

  const _StatusBadgeChip({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    switch (status) {
      case 'approved':
        icon = Iconsax.verify5;
        label = context.l10n.statusApproved;
        break;
      case 'pending':
        icon = Iconsax.clock;
        label = context.l10n.statusPending;
        break;
      case 'rejected':
        icon = Iconsax.close_circle;
        label = context.l10n.statusRejected;
        break;
      case 'suspended':
        icon = Iconsax.slash;
        label = context.l10n.statusSuspended;
        break;
      default:
        icon = Iconsax.info_circle;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: AppDimens.paddingXS),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
