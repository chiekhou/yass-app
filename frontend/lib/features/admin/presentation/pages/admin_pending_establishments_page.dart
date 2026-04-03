import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/admin_establishment_model.dart';
import '../bloc/admin_establishments_bloc.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/establishment_approval_card.dart';

class AdminPendingEstablishmentsPage extends StatefulWidget {
  const AdminPendingEstablishmentsPage({super.key});

  @override
  State<AdminPendingEstablishmentsPage> createState() =>
      _AdminPendingEstablishmentsPageState();
}

class _AdminPendingEstablishmentsPageState
    extends State<AdminPendingEstablishmentsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminEstablishmentsBloc>().add(AdminEstablishmentsLoadPending());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminEstablishmentsBloc>().add(AdminEstablishmentsLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Établissements en attente'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminPendingEstablishments),
      body: BlocBuilder<AdminEstablishmentsBloc, AdminEstablishmentsState>(
        builder: (context, state) {
          if (state is AdminEstablishmentsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is AdminEstablishmentsError) {
            return _buildErrorState(state.message);
          }

          if (state is AdminEstablishmentsLoaded) {
            if (state.establishments.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<AdminEstablishmentsBloc>()
                    .add(AdminEstablishmentsRefresh());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primaryGreen,
              child: Column(
                children: [
                  _buildHeader(context, state),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                      itemCount: state.establishments.length +
                          (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.establishments.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimens.paddingM),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final establishment = state.establishments[index];
                        return EstablishmentApprovalCard(
                          establishment: establishment,
                          isProcessing: state.processingId == establishment.id,
                          onTap: () {
                            // Optionally navigate to establishment details
                          },
                          onApproveTap: () =>
                              _approveEstablishment(context, establishment),
                          onRejectTap: () =>
                              _showRejectDialog(context, establishment),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminEstablishmentsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: const Icon(
              Iconsax.clock,
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
                  '${state.total} établissement(s) en attente',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  'Vérifiez et approuvez les nouveaux établissements',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
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
              child: const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
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
              onPressed: () => context
                  .read<AdminEstablishmentsBloc>()
                  .add(AdminEstablishmentsLoadPending()),
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
              'Tout est à jour !',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Aucun établissement en attente d\'approbation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<AdminEstablishmentsBloc>()
                  .add(AdminEstablishmentsRefresh()),
              icon: const Icon(Iconsax.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  void _approveEstablishment(
      BuildContext context, AdminEstablishment establishment) {
    context.read<AdminEstablishmentsBloc>().add(
          AdminEstablishmentApprove(establishmentId: establishment.id),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${establishment.name} a été approuvé'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminEstablishment establishment) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter l\'établissement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir rejeter "${establishment.name}" ?'),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
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
              context.read<AdminEstablishmentsBloc>().add(
                    AdminEstablishmentReject(
                      establishmentId: establishment.id,
                      reason: reasonController.text.trim(),
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${establishment.name} a été rejeté'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
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
}
