import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/pagination_bar.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../bloc/partner_establishments_bloc.dart';
import '../widgets/partner_drawer.dart';
import '../widgets/partner_establishment_card.dart';

class PartnerEstablishmentsPage extends StatefulWidget {
  const PartnerEstablishmentsPage({super.key});

  @override
  State<PartnerEstablishmentsPage> createState() =>
      _PartnerEstablishmentsPageState();
}

class _PartnerEstablishmentsPageState extends State<PartnerEstablishmentsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context
        .read<PartnerEstablishmentsBloc>()
        .add(const PartnerEstablishmentsLoad());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Mes établissements'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      drawer: PartnerDrawer(currentRoute: AppRoutes.partnerEstablishments),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 10.0,
        onPressed: () => context.push(AppRoutes.partnerEstablishmentCreate),
        backgroundColor: AppColors.primaryGreen,
        label: const Text('+'),
      ),
      body: Column(
        children: [
          _buildFilterChips(context),
          Expanded(child: _buildEstablishmentsList(context)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<PartnerEstablishmentsBloc, PartnerEstablishmentsState>(
      builder: (context, state) {
        String? statusFilter;

        if (state is PartnerEstablishmentsLoaded) {
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
                  onTap: () => context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(status: null)),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Actifs',
                  isSelected: statusFilter == 'active',
                  color: AppColors.success,
                  onTap: () => context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'active')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: context.l10n.statusPending,
                  isSelected: statusFilter == 'pending',
                  color: AppColors.warning,
                  onTap: () => context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'pending')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Inactifs',
                  isSelected: statusFilter == 'inactive',
                  color: AppColors.grey500,
                  onTap: () => context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'inactive')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Rejetés',
                  isSelected: statusFilter == 'rejected',
                  color: AppColors.error,
                  onTap: () => context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'rejected')),
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

  Widget _buildEstablishmentsList(BuildContext context) {
    return BlocConsumer<PartnerEstablishmentsBloc, PartnerEstablishmentsState>(
      listener: (context, state) {
        if (state is PartnerEstablishmentDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Établissement supprimé'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PartnerEstablishmentsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (state is PartnerEstablishmentsError) {
          return _buildErrorState(state.message);
        }

        if (state is PartnerEstablishmentsLoaded) {
          if (state.establishments.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<PartnerEstablishmentsBloc>()
                  .add(PartnerEstablishmentsRefresh());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primaryGreen,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: AppDimens.paddingM,
                      bottom: AppDimens.paddingM,
                    ),
                    itemCount: state.establishments.length,
                    itemBuilder: (context, index) {
                      final establishment = state.establishments[index];
                      return PartnerEstablishmentCard(
                        establishment: establishment,
                        isProcessing: state.processingId == establishment.id,
                        onTap: () => context.push(
                          AppRoutes.partnerEstablishmentDetails
                              .replaceFirst(':id', establishment.id),
                        ),
                        onEditTap: () => context.push(
                          AppRoutes.partnerEstablishmentEdit
                              .replaceFirst(':id', establishment.id),
                        ),
                        onDeleteTap: () => _showDeleteDialog(context, establishment),
                        onStatusTap: () => _showStatusDialog(context, establishment),
                      );
                    },
                  ),
                ),
                PaginationBar(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages,
                  total: state.total,
                  isLoading: state.isUpdating,
                  onPageChanged: (page) {
                    context.read<PartnerEstablishmentsBloc>().add(
                          PartnerEstablishmentsGoToPage(page: page),
                        );
                    _scrollController.jumpTo(0);
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
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
              onPressed: () => context
                  .read<PartnerEstablishmentsBloc>()
                  .add(const PartnerEstablishmentsLoad()),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.building,
                size: 64,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              'Aucun établissement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Ajoutez votre premier établissement pour commencer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.partnerEstablishmentCreate),
              icon: const Icon(Iconsax.add),
              label: const Text('Ajouter un établissement'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final bloc = context.read<PartnerEstablishmentsBloc>();
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

  void _showDeleteDialog(BuildContext context, Establishment establishment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'établissement'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${establishment.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PartnerEstablishmentsBloc>().add(
                    PartnerEstablishmentDelete(id: establishment.id),
                  );
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

  void _showStatusDialog(BuildContext context, Establishment establishment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (establishment.status != 'active')
              ListTile(
                leading:
                    const Icon(Iconsax.tick_circle, color: AppColors.success),
                title: const Text('Activer'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  context.read<PartnerEstablishmentsBloc>().add(
                        PartnerEstablishmentUpdateStatus(
                          id: establishment.id,
                          status: 'active',
                        ),
                      );
                },
              ),
            if (establishment.status != 'inactive')
              ListTile(
                leading:
                    const Icon(Iconsax.minus_cirlce, color: AppColors.grey500),
                title: const Text('Désactiver'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  context.read<PartnerEstablishmentsBloc>().add(
                        PartnerEstablishmentUpdateStatus(
                          id: establishment.id,
                          status: 'inactive',
                        ),
                      );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
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
                      .read<PartnerEstablishmentsBloc>()
                      .add(const PartnerEstablishmentsLoad());
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
                  context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(status: null));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusActive),
                selected: false,
                onSelected: (_) {
                  context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'active'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusPending),
                selected: false,
                onSelected: (_) {
                  context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'pending'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Inactif'),
                selected: false,
                onSelected: (_) {
                  context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'inactive'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text(context.l10n.statusRejected),
                selected: false,
                onSelected: (_) {
                  context.read<PartnerEstablishmentsBloc>().add(
                      const PartnerEstablishmentsFilterByStatus(
                          status: 'rejected'));
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
