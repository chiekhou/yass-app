import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/admin_user_model.dart';
import '../bloc/admin_users_bloc.dart';

class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminUsersBloc, AdminUsersState>(
      listener: (context, state) {
        if (state is AdminUserDeletedSuccess) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur supprimé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AdminUsersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminUserDetailsLoading) {
          return Scaffold(
            appBar: _buildAppBar(context, null),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        if (state is AdminUserDetailsLoaded) {
          return _UserDetailView(user: state.user, isUpdating: state.isUpdating);
        }

        if (state is AdminUsersError) {
          return Scaffold(
            appBar: _buildAppBar(context, null),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(state.message),
                  const SizedBox(height: AppDimens.paddingM),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, null),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, AdminUser? user) {
    return AppBar(
      title: Text(user?.fullName ?? 'Détail utilisateur'),
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left),
        onPressed: () => context.pop(),
      ),
    );
  }
}

class _UserDetailView extends StatelessWidget {
  final AdminUser user;
  final bool isUpdating;

  const _UserDetailView({required this.user, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(user.fullName),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.more, color: AppColors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Iconsax.trash, size: 16, color: AppColors.error),
                    SizedBox(width: AppDimens.paddingS),
                    Text('Supprimer', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isUpdating
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  _buildContactCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  _buildAccountCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  _buildStatsCard(context),
                  if (user.partnerProfile != null) ...[
                    const SizedBox(height: AppDimens.paddingM),
                    _buildPartnerCard(context),
                  ],
                  const SizedBox(height: AppDimens.paddingM),
                  _buildActionsCard(context),
                  const SizedBox(height: AppDimens.paddingL),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: const BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              backgroundImage:
                  user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(
                      user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  _buildRoleBadge(context),
                  const SizedBox(height: AppDimens.paddingXS),
                  _buildStatusBadge(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    Color color;
    switch (user.role) {
      case 'admin':
      case 'super_admin':
        color = AppColors.primaryGreen;
        break;
      case 'partner':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.grey500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Text(
        user.roleLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData icon;
    switch (user.status) {
      case 'active':
        color = AppColors.success;
        icon = Iconsax.verify5;
        break;
      case 'suspended':
        color = AppColors.error;
        icon = Iconsax.slash;
        break;
      case 'pending':
        color = AppColors.warning;
        icon = Iconsax.clock;
        break;
      default:
        color = AppColors.grey500;
        icon = Iconsax.info_circle;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          user.statusLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return _card(
      context,
      title: 'Contact',
      icon: Iconsax.call,
      children: [
        _infoRow(context, Iconsax.sms, user.email),
        if (user.phone != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          _infoRow(context, Iconsax.call, user.phone!),
        ],
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    return _card(
      context,
      title: 'Compte',
      icon: Iconsax.profile_circle,
      children: [
        _infoRow(
          context,
          Iconsax.global,
          user.language.toUpperCase(),
          label: 'Langue',
        ),
        const SizedBox(height: AppDimens.paddingS),
        _infoRow(
          context,
          user.emailVerified ? Iconsax.verify5 : Iconsax.close_circle,
          user.emailVerified ? 'Email vérifié' : 'Email non vérifié',
          color: user.emailVerified ? AppColors.success : AppColors.error,
        ),
        const SizedBox(height: AppDimens.paddingS),
        _infoRow(
          context,
          Iconsax.calendar_add,
          'Inscrit le ${dateFormatter.format(user.createdAt)}',
        ),
        const SizedBox(height: AppDimens.paddingS),
        _infoRow(
          context,
          Iconsax.refresh,
          'Mis à jour le ${dateFormatter.format(user.updatedAt)}',
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return _card(
      context,
      title: 'Activité',
      icon: Iconsax.chart,
      children: [
        Row(
          children: [
            Expanded(
              child: _statItem(
                context,
                icon: Iconsax.star,
                value: user.reviewsCount.toString(),
                label: 'Avis',
                color: AppColors.warning,
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.grey200),
            Expanded(
              child: _statItem(
                context,
                icon: Iconsax.heart,
                value: user.favoritesCount.toString(),
                label: 'Favoris',
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard(BuildContext context) {
    final p = user.partnerProfile!;
    Color statusColor;
    switch (p.status) {
      case 'approved':
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

    String statusLabel;
    switch (p.status) {
      case 'approved':
        statusLabel = 'Approuvé';
        break;
      case 'pending':
        statusLabel = 'En attente';
        break;
      case 'rejected':
        statusLabel = 'Rejeté';
        break;
      case 'suspended':
        statusLabel = 'Suspendu';
        break;
      default:
        statusLabel = p.status;
    }

    return _card(
      context,
      title: 'Profil Partenaire',
      icon: Iconsax.briefcase,
      trailing: TextButton.icon(
        onPressed: () => context.push(
          AppRoutes.adminPartnerDetails.replaceFirst(':id', p.id),
        ),
        icon: const Icon(Iconsax.arrow_right_3, size: 14),
        label: const Text('Voir détails'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      children: [
        _infoRow(context, Iconsax.building, p.companyName),
        const SizedBox(height: AppDimens.paddingS),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusXS),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Text(
              p.subscriptionPlan.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        if (p.registrationNumber != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          _infoRow(context, Iconsax.document, 'RC: ${p.registrationNumber}'),
        ],
        if (p.taxId != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          _infoRow(context, Iconsax.receipt_2, 'NIF: ${p.taxId}'),
        ],
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return _card(
      context,
      title: 'Actions',
      icon: Iconsax.setting_2,
      children: [
        Text(
          'Modifier le statut',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey600,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        Wrap(
          spacing: AppDimens.paddingS,
          runSpacing: AppDimens.paddingS,
          children: [
            if (!user.isActive)
              _actionButton(
                context,
                label: 'Activer',
                icon: Iconsax.verify5,
                color: AppColors.success,
                onTap: () => _confirmStatusChange(context, 'active', 'Activer'),
              ),
            if (!user.isSuspended)
              _actionButton(
                context,
                label: 'Suspendre',
                icon: Iconsax.slash,
                color: AppColors.error,
                onTap: () =>
                    _confirmStatusChange(context, 'suspended', 'Suspendre'),
              ),
            if (!user.isInactive)
              _actionButton(
                context,
                label: 'Désactiver',
                icon: Iconsax.close_circle,
                color: AppColors.grey600,
                onTap: () =>
                    _confirmStatusChange(context, 'inactive', 'Désactiver'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  void _confirmStatusChange(
      BuildContext context, String status, String label) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$label l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir $label "${user.fullName}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminUsersBloc>().add(
                    AdminUserUpdateStatus(userId: user.id, status: status),
                  );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${user.fullName}" ? '
          'Cette action est irréversible et supprimera également ses avis, favoris et profil partenaire.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AdminUsersBloc>()
                  .add(AdminUserDelete(userId: user.id));
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

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: const BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            const Divider(height: 1, color: AppColors.grey100),
            const SizedBox(height: AppDimens.paddingM),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text,
      {Color? color, String? label}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.grey500),
        const SizedBox(width: AppDimens.paddingS),
        if (label != null) ...[
          Text(
            '$label : ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
        ],
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? AppColors.grey800,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
