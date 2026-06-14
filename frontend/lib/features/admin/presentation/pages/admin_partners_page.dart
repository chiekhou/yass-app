import 'dart:async';

import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/pagination_bar.dart';
import '../../../../app_router.dart';
import '../../data/models/admin_partner_model.dart';
import '../bloc/admin_partners_bloc.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/partner_list_item.dart';

class AdminPartnersPage extends StatefulWidget {
  final bool pendingOnly;

  const AdminPartnersPage({
    super.key,
    this.pendingOnly = false,
  });

  @override
  State<AdminPartnersPage> createState() => _AdminPartnersPageState();
}

class _AdminPartnersPageState extends State<AdminPartnersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<AdminPartnersBloc>().add(
          AdminPartnersLoad(pendingOnly: widget.pendingOnly),
        );
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminPartnersBloc, AdminPartnersState>(
      listenWhen: (previous, current) =>
          current is AdminPartnersError && previous is AdminPartnersLoaded,
      listener: (context, state) {
        if (state is AdminPartnersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(widget.pendingOnly
            ? 'Partenaires en attente'
            : 'Gestion des partenaires'),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (!widget.pendingOnly)
            IconButton(
              icon: const Icon(Iconsax.filter),
              onPressed: () => _showFilterSheet(context),
            ),
        ],
      ),
      drawer: AdminDrawer(
        currentRoute: widget.pendingOnly
            ? AppRoutes.adminPendingPartners
            : AppRoutes.adminPartners,
      ),
      body: Column(
        children: [
          if (!widget.pendingOnly) _buildSearchBar(context),
          if (!widget.pendingOnly) _buildFilterChips(context),
          Expanded(child: _buildPartnersList(context)),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: TextField(
        style: TextStyle(color: AppColors.grey700),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un partenaire...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchDebounce?.cancel();
                    context
                        .read<AdminPartnersBloc>()
                        .add(const AdminPartnersSearch(query: ''));
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
        ),
        onChanged: (value) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 400), () {
            context
                .read<AdminPartnersBloc>()
                .add(AdminPartnersSearch(query: value));
          });
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<AdminPartnersBloc, AdminPartnersState>(
      builder: (context, state) {
        String? statusFilter;

        if (state is AdminPartnersLoaded) {
          statusFilter = state.statusFilter;
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          color: AppColors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'Tous',
                  isSelected: statusFilter == null,
                  onTap: () => context
                      .read<AdminPartnersBloc>()
                      .add(const AdminPartnersFilterByStatus(status: null)),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Approuvés',
                  isSelected: statusFilter == 'approved',
                  color: AppColors.success,
                  onTap: () => context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'approved')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: context.l10n.statusPending,
                  isSelected: statusFilter == 'pending',
                  color: AppColors.warning,
                  onTap: () => context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'pending')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Rejetés',
                  isSelected: statusFilter == 'rejected',
                  color: AppColors.error,
                  onTap: () => context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'rejected')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Suspendus',
                  isSelected: statusFilter == 'suspended',
                  color: AppColors.grey600,
                  onTap: () => context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'suspended')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? chipColor.withValues(alpha: 0.1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? chipColor : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildPartnersList(BuildContext context) {
    return BlocBuilder<AdminPartnersBloc, AdminPartnersState>(
      buildWhen: (previous, current) =>
          !(current is AdminPartnersError && previous is AdminPartnersLoaded),
      builder: (context, state) {
        if (state is AdminPartnersLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (state is AdminPartnersError) {
          return _buildErrorState(state.message);
        }

        if (state is AdminPartnersLoaded) {
          if (state.partners.isEmpty) {
            return _buildEmptyState();
          }

          final list = RefreshIndicator(
            onRefresh: () async {
              context.read<AdminPartnersBloc>().add(AdminPartnersRefresh());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primaryGreen,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingM),
                    itemCount: state.partners.length,
                    itemBuilder: (context, index) {
                      final partner = state.partners[index];
                      return PartnerListItem(
                        partner: partner,
                        isProcessing: state.isUpdating &&
                            state.partners[index].id == partner.id,
                        onTap: () => context.push(
                          AppRoutes.adminPartnerDetails
                              .replaceFirst(':id', partner.id),
                        ),
                        onApproveTap: partner.isPending
                            ? () => _approvePartner(context, partner)
                            : null,
                        onRejectTap: partner.isPending
                            ? () => _showRejectDialog(context, partner)
                            : null,
                        onSuspendTap: partner.isApproved
                            ? () => _showSuspendDialog(context, partner)
                            : null,
                      );
                    },
                  ),
                ),
                PaginationBar(
                  currentPage: state.page,
                  totalPages: state.totalPages,
                  total: state.total,
                  isLoading: state.isUpdating,
                  onPageChanged: (page) {
                    context
                        .read<AdminPartnersBloc>()
                        .add(AdminPartnersGoToPage(page: page));
                    _scrollController.jumpTo(0);
                  },
                ),
              ],
            ),
          );

          // En mode "En attente", afficher le header de compteur
          if (widget.pendingOnly) {
            return Column(
              children: [
                _buildPendingHeader(context, state.partners.length),
                Expanded(child: list),
              ],
            );
          }

          return list;
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPendingHeader(BuildContext context, int count) {
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
              Iconsax.briefcase,
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
                  '$count partenaire${count > 1 ? 's' : ''} en attente',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  'Vérifiez et approuvez les nouveaux partenaires',
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

  Widget _buildErrorState(String message) {
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
              child: const Icon(Iconsax.warning_2,
                  size: 64, color: AppColors.error),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () => context.read<AdminPartnersBloc>().add(
                    AdminPartnersLoad(pendingOnly: widget.pendingOnly),
                  ),
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

  Widget _buildEmptyState() {
    final isPending = widget.pendingOnly;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: isPending
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.grey200.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Iconsax.tick_circle : Iconsax.briefcase,
                size: 64,
                color: isPending ? AppColors.success : AppColors.grey400,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              isPending ? 'Tout est à jour !' : 'Aucun partenaire trouvé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              isPending
                  ? 'Aucun partenaire en attente d\'approbation'
                  : 'Essayez de modifier vos filtres de recherche',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isPending) ...[
              const SizedBox(height: AppDimens.paddingXL),
              OutlinedButton.icon(
                onPressed: () => context.read<AdminPartnersBloc>().add(
                      AdminPartnersLoad(pendingOnly: true),
                    ),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Actualiser'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final bloc = context.read<AdminPartnersBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: _FilterBottomSheet(),
      ),
    );
  }

  void _approvePartner(BuildContext context, AdminPartner partner) {
    context.read<AdminPartnersBloc>().add(
          AdminPartnerApprove(partnerId: partner.id),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${partner.companyName} a été approuvé'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminPartner partner) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter le partenaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir rejeter ${partner.companyName} ?'),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet',
                hintText: 'Entrez la raison du rejet...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer une raison'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<AdminPartnersBloc>().add(
                    AdminPartnerReject(
                      partnerId: partner.id,
                      reason: reasonController.text.trim(),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminPartner partner) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suspendre le partenaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir suspendre ${partner.companyName} ?'),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de la suspension',
                hintText: 'Entrez la raison...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La raison doit faire au moins 10 caractères'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<AdminPartnersBloc>().add(
                    AdminPartnerSuspend(
                      partnerId: partner.id,
                      reason: reason,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  context
                      .read<AdminPartnersBloc>()
                      .add(const AdminPartnersLoad());
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'Statut',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Wrap(
            spacing: AppDimens.paddingS,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminPartnersBloc>()
                      .add(const AdminPartnersFilterByStatus(status: null));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusApproved),
                selected: false,
                onSelected: (_) {
                  context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'approved'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusPending),
                selected: false,
                onSelected: (_) {
                  context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'pending'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusRejected),
                selected: false,
                onSelected: (_) {
                  context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'rejected'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusSuspended),
                selected: false,
                onSelected: (_) {
                  context.read<AdminPartnersBloc>().add(
                      const AdminPartnersFilterByStatus(status: 'suspended'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),
        ],
      ),
    );
  }
}
