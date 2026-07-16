import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
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
            SnackBar(
              content: Text(context.l10n.userDeleted),
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
          return _UserDetailView(
              user: state.user, isUpdating: state.isUpdating);
        }

        if (state is AdminUsersError) {
          return Scaffold(
            appBar: _buildAppBar(context, null),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(state.message),
                  const SizedBox(height: AppDimens.paddingM),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.back),
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
      backgroundColor: AppColors.scaffoldBackground,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left),
        onPressed: () => context.pop(),
      ),
    );
  }
}

class _UserDetailView extends StatefulWidget {
  final AdminUser user;
  final bool isUpdating;

  const _UserDetailView({required this.user, required this.isUpdating});

  @override
  State<_UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<_UserDetailView> {
  static const int _estPageSize = 5;
  int _estPage = 0;

  AdminUser get user => widget.user;
  bool get isUpdating => widget.isUpdating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(user.fullName),
        backgroundColor: AppColors.scaffoldBackground,
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
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Iconsax.trash, size: 16, color: AppColors.error),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(context.l10n.delete, style: const TextStyle(color: AppColors.error)),
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
                  _buildProfileCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  _buildAccountCard(context),
                  const SizedBox(height: AppDimens.paddingM),
                  if (user.partnerProfile != null) ...[
                    _buildPartnerCard(context),
                    if (user.partnerProfile!.establishments != null &&
                        user.partnerProfile!.establishments!.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.paddingM),
                      _buildPartnerEstablishmentsCard(context),
                    ],
                    const SizedBox(height: AppDimens.paddingM),
                  ],
                  _buildStatsCard(context),
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
      color: AppColors.scaffoldBackground,
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
              backgroundColor: AppColors.white,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                        ),
                      ),
                      if (user.isElite)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.medal_star,
                                  size: 10, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                'Élite',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

  Widget _buildProfileCard(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    return _card(
      context,
      title: 'Profil',
      icon: Iconsax.profile_2user,
      children: [
        _infoRow(
          context,
          Iconsax.man,
          user.genderLabel,
          label: 'Sexe',
        ),
        const SizedBox(height: AppDimens.paddingS),
        _infoRow(
          context,
          Iconsax.calendar_1,
          user.age != null ? '${user.age} ans' : 'Non renseigné',
          label: 'Âge',
        ),
        const SizedBox(height: AppDimens.paddingS),
        _infoRow(
          context,
          Iconsax.chart_21,
          user.ageCategory,
          label: 'Tranche',
        ),
        if (user.lastLogin != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          _infoRow(
            context,
            Iconsax.login,
            dateFormatter.format(user.lastLogin!),
            label: 'Dernière connexion',
          ),
        ],
        const SizedBox(height: AppDimens.paddingS),
        _infoRow(
          context,
          Iconsax.mobile,
          '${user.loginCount} session${user.loginCount > 1 ? 's' : ''}',
          label: 'Connexions',
        ),
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
            Container(width: 1, height: 48, color: AppColors.grey200),
            Expanded(
              child: _statItem(
                context,
                icon: Iconsax.mobile,
                value: user.loginCount.toString(),
                label: 'Connexions',
                color: AppColors.primaryGreen,
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
                color: AppColors.white,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
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
        statusLabel = context.l10n.statusApproved;
        break;
      case 'pending':
        statusLabel = context.l10n.statusPending;
        break;
      case 'rejected':
        statusLabel = context.l10n.statusRejected;
        break;
      case 'suspended':
        statusLabel = context.l10n.statusSuspended;
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
        label: Text(context.l10n.seeDetails),
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

  Widget _buildPartnerEstablishmentsCard(BuildContext context) {
    final all = user.partnerProfile!.establishments!;
    final totalPages = (all.length / _estPageSize).ceil();
    final start = _estPage * _estPageSize;
    final end = (start + _estPageSize).clamp(0, all.length);
    final page = all.sublist(start, end);

    return _card(
      context,
      title: 'Établissements & Interlocuteurs',
      icon: Iconsax.building,
      trailing: all.length > _estPageSize
          ? Text(
              '${_estPage + 1}/$totalPages',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            )
          : null,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: page.length,
          separatorBuilder: (_, __) =>
              const Divider(height: AppDimens.paddingM),
          itemBuilder: (context, index) {
            final est = page[index];
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        est.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                        est.statusLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Container(
                  padding: const EdgeInsets.all(AppDimens.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.interlocutor,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppDimens.paddingXS),
                      _estInfoRow(context, Iconsax.user, context.l10n.firstName,
                          est.contactFirstName ?? context.l10n.notProvided),
                      _estInfoRow(context, Iconsax.user, context.l10n.lastName,
                          est.contactLastName ?? context.l10n.notProvided),
                      _estInfoRow(context, Iconsax.briefcase, context.l10n.positionLabel,
                          est.contactPosition ?? context.l10n.notProvided),
                      _estInfoRow(context, Iconsax.call, context.l10n.phoneShort,
                          est.contactPhone ?? context.l10n.notProvided),
                      _estInfoRow(context, Iconsax.sms, context.l10n.email,
                          est.contactEmail ?? context.l10n.notProvided),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppDimens.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed:
                    _estPage > 0 ? () => setState(() => _estPage--) : null,
                icon: const Icon(Iconsax.arrow_left_2, size: 14),
                label: Text(context.l10n.previousShort),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  disabledForegroundColor: AppColors.grey300,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS),
                ),
              ),
              Text(
                '${_estPage + 1} / $totalPages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton.icon(
                onPressed: _estPage < totalPages - 1
                    ? () => setState(() => _estPage++)
                    : null,
                icon: const Icon(Iconsax.arrow_right_3, size: 14),
                label: Text(context.l10n.nextShort),
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  disabledForegroundColor: AppColors.grey300,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _estInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.grey500),
          const SizedBox(width: AppDimens.paddingS),
          Text(
            '$label : ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                  fontSize: 11,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
                color: AppColors.white,
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
        const Divider(height: AppDimens.paddingL),
        Text(
          'Statut Élite',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
              ),
        ),
        const SizedBox(height: AppDimens.paddingS),
        Wrap(
          spacing: AppDimens.paddingM,
          runSpacing: AppDimens.paddingS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    user.isElite ? const Color(0xFFFFF8E1) : AppColors.grey50,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(
                  color: user.isElite
                      ? const Color(0xFFFFB300)
                      : AppColors.grey200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.medal_star,
                    size: 14,
                    color: user.isElite
                        ? const Color(0xFFFFB300)
                        : AppColors.grey400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isElite ? 'Membre Élite' : 'Utilisateur standard',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: user.isElite
                              ? const Color(0xFFFFB300)
                              : AppColors.grey400,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _confirmToggleElite(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    user.isElite ? AppColors.grey600 : const Color(0xFFFFB300),
                side: BorderSide(
                  color: user.isElite
                      ? AppColors.grey300
                      : const Color(0xFFFFB300),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingS,
                ),
              ),
              icon: Icon(
                user.isElite ? Iconsax.minus_cirlce : Iconsax.medal_star,
                size: 14,
              ),
              label: Text(
                user.isElite ? 'Révoquer' : 'Promouvoir',
                style: const TextStyle(fontSize: 13),
              ),
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
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
      ),
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13),
        selectionColor: AppColors.white,
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, String status, String label) {
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
            child: Text(context.l10n.cancel),
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

  void _confirmToggleElite(BuildContext context) {
    final promote = !user.isElite;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(promote ? 'Promouvoir en Élite' : 'Révoquer le statut Élite'),
        content: Text(
          promote
              ? 'Voulez-vous promouvoir "${user.fullName}" au statut Élite ?'
              : 'Voulez-vous révoquer le statut Élite de "${user.fullName}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminUsersBloc>().add(
                    AdminUserToggleElite(userId: user.id),
                  );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  promote ? const Color(0xFFFFB300) : AppColors.grey600,
              foregroundColor: Colors.white,
            ),
            child: Text(promote ? 'Promouvoir' : 'Révoquer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteUser),
        content: Text(context.l10n.deleteUserQuestion(user.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
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
            child: Text(context.l10n.delete),
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
      color: AppColors.scaffoldBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: const BorderSide(color: AppColors.white),
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
            const Divider(height: 1, color: AppColors.white),
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
        Icon(icon, size: 14, color: color ?? AppColors.white),
        const SizedBox(width: AppDimens.paddingS),
        if (label != null) ...[
          Text(
            '$label : ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white,
                ),
          ),
        ],
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
