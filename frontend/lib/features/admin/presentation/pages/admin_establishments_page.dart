import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../app_router.dart';
import '../../../../core/widgets/pagination_bar.dart';
import '../../data/models/admin_establishment_model.dart';
import '../../data/models/admin_partner_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../bloc/admin_establishments_bloc.dart';
import '../widgets/admin_drawer.dart';

class AdminEstablishmentsPage extends StatefulWidget {
  const AdminEstablishmentsPage({super.key});

  @override
  State<AdminEstablishmentsPage> createState() =>
      _AdminEstablishmentsPageState();
}

class _AdminEstablishmentsPageState extends State<AdminEstablishmentsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // État local synchronisé via BlocListener
  List<AdminEstablishment> _establishments = [];
  String? _processingId;
  String? _statusFilter;
  String? _searchQuery;
  bool _isInitialLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _isPageLoading = false;

  @override
  void initState() {
    super.initState();
    context
        .read<AdminEstablishmentsBloc>()
        .add(const AdminEstablishmentsLoad());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onBlocState(BuildContext context, AdminEstablishmentsState state) {
    if (state is AdminEstablishmentsLoaded) {
      final bool resetScroll = state.statusFilter != _statusFilter ||
          state.searchQuery != _searchQuery;
      setState(() {
        _establishments = state.establishments;
        _processingId = state.processingId;
        _statusFilter = state.statusFilter;
        _searchQuery = state.searchQuery;
        _isInitialLoading = false;
        _errorMessage = null;
        _currentPage = state.page;
        _totalPages = state.totalPages;
        _total = state.total;
        _isPageLoading = state.isUpdating;
      });
      if (resetScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    } else if (state is AdminEstablishmentsError) {
      setState(() {
        _isInitialLoading = false;
        _errorMessage = state.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminEstablishmentsBloc, AdminEstablishmentsState>(
      listener: _onBlocState,
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          title: const Text('Gestion des établissements'),
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
        drawer: AdminDrawer(currentRoute: AppRoutes.adminEstablishments),
        body: Column(
          children: [
            _buildSearchBar(context),
            _buildFilterChips(context),
            Expanded(child: _buildList(context)),
            PaginationBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              total: _total,
              isLoading: _isPageLoading,
              onPageChanged: (page) {
                context.read<AdminEstablishmentsBloc>().add(
                      AdminEstablishmentsGoToPage(page: page),
                    );
                _scrollController.jumpTo(0);
              },
            ),
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom ou adresse...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<AdminEstablishmentsBloc>()
                        .add(const AdminEstablishmentsSearch(query: ''));
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
          context
              .read<AdminEstablishmentsBloc>()
              .add(AdminEstablishmentsSearch(query: value));
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
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
              isSelected: _statusFilter == null,
              onTap: () => context
                  .read<AdminEstablishmentsBloc>()
                  .add(const AdminEstablishmentsFilterByStatus(status: null)),
            ),
            const SizedBox(width: AppDimens.paddingS),
            _buildFilterChip(
              context,
              label: 'Actifs',
              isSelected: _statusFilter == 'active',
              color: AppColors.success,
              onTap: () => context.read<AdminEstablishmentsBloc>().add(
                  const AdminEstablishmentsFilterByStatus(status: 'active')),
            ),
            const SizedBox(width: AppDimens.paddingS),
            _buildFilterChip(
              context,
              label: 'En attente',
              isSelected: _statusFilter == 'pending',
              color: AppColors.warning,
              onTap: () => context.read<AdminEstablishmentsBloc>().add(
                  const AdminEstablishmentsFilterByStatus(status: 'pending')),
            ),
            const SizedBox(width: AppDimens.paddingS),
            _buildFilterChip(
              context,
              label: 'Rejetés',
              isSelected: _statusFilter == 'rejected',
              color: AppColors.error,
              onTap: () => context.read<AdminEstablishmentsBloc>().add(
                  const AdminEstablishmentsFilterByStatus(status: 'rejected')),
            ),
            const SizedBox(width: AppDimens.paddingS),
            _buildFilterChip(
              context,
              label: 'Suspendus',
              isSelected: _statusFilter == 'suspended',
              color: AppColors.grey500,
              onTap: () => context.read<AdminEstablishmentsBloc>().add(
                  const AdminEstablishmentsFilterByStatus(status: 'suspended')),
            ),
          ],
        ),
      ),
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

  Widget _buildList(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_establishments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminEstablishmentsBloc>().add(
              AdminEstablishmentsLoad(
                status: _statusFilter,
                search: _searchQuery,
              ),
            );
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primaryGreen,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        itemCount: _establishments.length,
        itemBuilder: (context, index) {
          final e = _establishments[index];
          return Padding(
            key: ValueKey(e.id),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingXS,
            ),
            child: _EstablishmentCard(
              establishment: e,
              isProcessing: _processingId == e.id,
              onApprove:
                  e.isPending ? () => _showApproveDialog(context, e) : null,
              onReject:
                  e.isPending ? () => _showRejectDialog(context, e) : null,
              onDelete: () => _showDeleteDialog(context, e),
              onToggleFeatured:
                  e.isActive ? () => _showFeatureDialog(context, e) : null,
              onAssignPartner: () => _showAssignPartnerDialog(context, e),
            ),
          );
        },
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
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
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
                  .read<AdminEstablishmentsBloc>()
                  .add(const AdminEstablishmentsLoad()),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
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
            Icon(Iconsax.building, size: 64, color: AppColors.grey400),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Aucun établissement trouvé',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Essayez de modifier vos filtres de recherche',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final bloc = context.read<AdminEstablishmentsBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: const _FilterBottomSheet(),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, AdminEstablishment e) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approuver l\'établissement'),
        content:
            Text('Approuver « ${e.name} » ? Il sera visible sur l\'annuaire.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminEstablishmentsBloc>().add(
                    AdminEstablishmentApprove(establishmentId: e.id),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminEstablishment e) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter l\'établissement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejeter « ${e.name} » ?'),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
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
            child: const Text('Annuler'),
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
                      establishmentId: e.id,
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

  void _showFeatureDialog(BuildContext context, AdminEstablishment e) {
    final isCurrentlyFeatured = e.isFeatured;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(isCurrentlyFeatured ? 'Retirer de la une' : 'Mettre à la une'),
        content: isCurrentlyFeatured
            ? Text('Retirer « ${e.name} » de la mise en avant ?')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mettre « ${e.name} » à la une.'),
                  const SizedBox(height: AppDimens.paddingM),
                  const Text('Durée :',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppDimens.paddingS),
                  Wrap(
                    spacing: AppDimens.paddingS,
                    runSpacing: AppDimens.paddingS,
                    children: [
                      _DurationChip(
                          label: '7 jours',
                          days: 7,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.read<AdminEstablishmentsBloc>().add(
                                AdminEstablishmentSetFeatured(
                                    establishmentId: e.id, durationDays: 7));
                          }),
                      _DurationChip(
                          label: '30 jours',
                          days: 30,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.read<AdminEstablishmentsBloc>().add(
                                AdminEstablishmentSetFeatured(
                                    establishmentId: e.id, durationDays: 30));
                          }),
                      _DurationChip(
                          label: '90 jours',
                          days: 90,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.read<AdminEstablishmentsBloc>().add(
                                AdminEstablishmentSetFeatured(
                                    establishmentId: e.id, durationDays: 90));
                          }),
                      _DurationChip(
                          label: 'Sans limite',
                          days: null,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.read<AdminEstablishmentsBloc>().add(
                                AdminEstablishmentSetFeatured(
                                    establishmentId: e.id, durationDays: null));
                          }),
                    ],
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          if (isCurrentlyFeatured)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AdminEstablishmentsBloc>().add(
                      AdminEstablishmentSetFeatured(
                        establishmentId: e.id,
                        durationDays: 0,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retirer'),
            ),
        ],
      ),
    );
  }

  static const _featuredPlans = [
    {'key': 'featured_7', 'label': '7 jours', 'price': '500 DZD'},
    {'key': 'featured_15', 'label': '15 jours', 'price': '800 DZD'},
    {'key': 'featured_30', 'label': '30 jours', 'price': '1 400 DZD'},
  ];

  /*void _showFeaturedPaymentDialog(BuildContext context, AdminEstablishment e) {
    String selectedPlan = 'featured_7';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusL)),
          title: const Row(
            children: [
              Icon(Iconsax.star5, color: Color(0xFFFFCA28)),
              SizedBox(width: 8),
              Text('Mise à la une payante'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '« ${e.name} »',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.grey700),
              ),
              const SizedBox(height: AppDimens.paddingM),
              const Text('Durée & tarif :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppDimens.paddingS),
              ..._featuredPlans.map((p) {
                final isSelected = selectedPlan == p['key'];
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedPlan = p['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.08)
                          : AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.grey200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.grey400,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(p['label']!,
                                style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal))),
                        Text(p['price']!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : AppColors.grey700)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _adminFeaturedManual(context, e.id, selectedPlan);
              },
              icon: const Icon(Iconsax.bank, size: 16),
              label: const Text('Facture manuelle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _adminFeaturedCheckout(context, e.id, selectedPlan);
              },
              icon: const Icon(Iconsax.card, size: 16),
              label: const Text('Lien Chargily'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  /*Future<void> _adminFeaturedCheckout(
      BuildContext ctx, String establishmentId, String plan) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.adminFeaturedCheckout(establishmentId),
        data: {'plan': plan},
      );
      final url = response.data['data']['checkout_url'] as String?;
      if (url != null && ctx.mounted) {
        // Afficher le lien pour le copier/envoyer au partenaire
        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Lien de paiement généré'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Envoyez ce lien au partenaire pour qu\'il finalise le paiement.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimens.paddingM),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: SelectableText(
                    url,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('Ouvrir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _adminFeaturedManual(
      BuildContext ctx, String establishmentId, String plan) async {
    try {
      await ApiClient.instance.post(
        ApiConfig.adminFeaturedManual(establishmentId),
        data: {'plan': plan},
      );
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Facture manuelle créée — en attente de validation.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }*/

  void _showAssignPartnerDialog(BuildContext context, AdminEstablishment e) {
    final bloc = context.read<AdminEstablishmentsBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (_) => _AssignPartnerSheet(
        establishment: e,
        onAssign: (partnerId) {
          bloc.add(AdminEstablishmentAssignPartner(
            establishmentId: e.id,
            partnerId: partnerId,
          ));
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AdminEstablishment e) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'établissement'),
        content: Text(
          'Supprimer « ${e.name} » ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminEstablishmentsBloc>().add(
                    AdminEstablishmentDelete(establishmentId: e.id),
                  );
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
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

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
                      .read<AdminEstablishmentsBloc>()
                      .add(const AdminEstablishmentsLoad());
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
            runSpacing: AppDimens.paddingS,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: false,
                onSelected: (_) {
                  context.read<AdminEstablishmentsBloc>().add(
                      const AdminEstablishmentsFilterByStatus(status: null));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('En attente'),
                selected: false,
                onSelected: (_) {
                  context.read<AdminEstablishmentsBloc>().add(
                      const AdminEstablishmentsFilterByStatus(
                          status: 'pending'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Actifs'),
                selected: false,
                onSelected: (_) {
                  context.read<AdminEstablishmentsBloc>().add(
                      const AdminEstablishmentsFilterByStatus(
                          status: 'active'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Rejetés'),
                selected: false,
                onSelected: (_) {
                  context.read<AdminEstablishmentsBloc>().add(
                      const AdminEstablishmentsFilterByStatus(
                          status: 'rejected'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Suspendus'),
                selected: false,
                onSelected: (_) {
                  context.read<AdminEstablishmentsBloc>().add(
                      const AdminEstablishmentsFilterByStatus(
                          status: 'suspended'));
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

// ── Card ─────────────────────────────────────────────────────────────────────

class _EstablishmentCard extends StatelessWidget {
  final AdminEstablishment establishment;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onDelete;
  final VoidCallback? onToggleFeatured;
  final VoidCallback? onFeaturedPayment;
  final VoidCallback? onAssignPartner;

  const _EstablishmentCard({
    required this.establishment,
    this.isProcessing = false,
    this.onApprove,
    this.onReject,
    required this.onDelete,
    this.onToggleFeatured,
    this.onFeaturedPayment,
    this.onAssignPartner,
  });

  Color get _statusColor {
    switch (establishment.status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'suspended':
        return AppColors.grey500;
      default:
        return AppColors.grey400;
    }
  }

  IconData get _statusIcon {
    switch (establishment.status) {
      case 'active':
        return Iconsax.tick_circle;
      case 'pending':
        return Iconsax.clock;
      case 'rejected':
        return Iconsax.close_circle;
      case 'suspended':
        return Iconsax.pause_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = establishment;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isProcessing
          ? const Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.categoryName != null)
                              Text(
                                e.categoryName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              e.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingS, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon, size: 12, color: _statusColor),
                            const SizedBox(width: 4),
                            Text(
                              e.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  if (e.partner != null)
                    Row(
                      children: [
                        const Icon(Iconsax.briefcase,
                            size: 13, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.partner!.companyName,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grey600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (e.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.location,
                            size: 13, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${e.address!}${e.wilayaName != null ? ' · ${e.wilayaName}' : ''}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grey600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (e.reviewsCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.star1,
                            size: 13, color: AppColors.starFilled),
                        const SizedBox(width: 4),
                        Text(
                          '${e.averageRating.toStringAsFixed(1)} · ${e.reviewsCount} avis',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey600),
                        ),
                      ],
                    ),
                  ],
                  if (e.rejectionReason != null &&
                      e.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingS),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Iconsax.info_circle,
                              size: 13, color: AppColors.error),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e.rejectionReason!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimens.paddingM),
                  const Divider(height: 1),
                  const SizedBox(height: AppDimens.paddingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Iconsax.trash, size: 18),
                            color: AppColors.error,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.errorLight,
                              minimumSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          if (onAssignPartner != null) ...[
                            const SizedBox(width: AppDimens.paddingS),
                            IconButton(
                              onPressed: onAssignPartner,
                              icon: const Icon(Iconsax.link, size: 18),
                              color: AppColors.primaryGreen,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                                minimumSize: const Size(36, 36),
                                padding: EdgeInsets.zero,
                              ),
                              tooltip: establishment.partner != null
                                  ? 'Changer de partenaire'
                                  : 'Associer un partenaire',
                            ),
                          ],
                          if (onToggleFeatured != null) ...[
                            const SizedBox(width: AppDimens.paddingS),
                            IconButton(
                              onPressed: onToggleFeatured,
                              icon: Icon(
                                establishment.isFeatured
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 18,
                              ),
                              color: establishment.isFeatured
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.grey500,
                              style: IconButton.styleFrom(
                                backgroundColor: establishment.isFeatured
                                    ? const Color(0xFFFEF3C7)
                                    : AppColors.grey100,
                                minimumSize: const Size(36, 36),
                                padding: EdgeInsets.zero,
                              ),
                              tooltip: establishment.isFeatured
                                  ? 'Retirer de la une'
                                  : 'Mettre à la une',
                            ),
                          ],
                          if (onFeaturedPayment != null) ...[
                            const SizedBox(width: AppDimens.paddingS),
                            IconButton(
                              onPressed: onFeaturedPayment,
                              icon: const Icon(Iconsax.card, size: 16),
                              color: AppColors.primaryGreen,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen
                                    .withValues(alpha: 0.1),
                                minimumSize: const Size(36, 36),
                                padding: EdgeInsets.zero,
                              ),
                              tooltip: 'Mise à la une payante',
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onReject != null) ...[
                            OutlinedButton(
                              onPressed: onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingM,
                                  vertical: AppDimens.paddingXS,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.close_circle, size: 15),
                                  SizedBox(width: 4),
                                  Text('Rejeter'),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimens.paddingS),
                          ],
                          if (onApprove != null)
                            ElevatedButton(
                              onPressed: onApprove,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingM,
                                  vertical: AppDimens.paddingXS,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.tick_circle, size: 15),
                                  SizedBox(width: 4),
                                  Text('Approuver'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Assign partner sheet ──────────────────────────────────────────────────────

class _AssignPartnerSheet extends StatefulWidget {
  final AdminEstablishment establishment;
  final void Function(String? partnerId) onAssign;

  const _AssignPartnerSheet({
    required this.establishment,
    required this.onAssign,
  });

  @override
  State<_AssignPartnerSheet> createState() => _AssignPartnerSheetState();
}

class _AssignPartnerSheetState extends State<_AssignPartnerSheet> {
  final _searchController = TextEditingController();
  final AdminRepository _repo = AdminRepository();

  List<AdminPartner> _partners = [];
  bool _isLoading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.establishment.partnerId;
    _load('');
    _searchController.addListener(() => _load(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() => _isLoading = true);
    try {
      final result = await _repo.getPartners(
        limit: 30,
        status: 'approved',
        search: query.isEmpty ? null : query,
      );
      if (mounted) setState(() { _partners = result.partners; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: AppDimens.paddingS),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Associer un partenaire',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.establishment.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un partenaire...',
                    prefixIcon: const Icon(Iconsax.search_normal, size: 18),
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
                ),
              ],
            ),
          ),
          if (widget.establishment.partner != null)
            ListTile(
              leading: const Icon(Icons.link_off, color: AppColors.error),
              title: const Text('Détacher le partenaire actuel'),
              textColor: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                widget.onAssign(null);
              },
            ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _partners.isEmpty
                    ? const Center(child: Text('Aucun partenaire trouvé'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: _partners.length,
                        itemBuilder: (_, i) {
                          final p = _partners[i];
                          final isSelected = p.id == _selectedId;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                              child: Text(
                                p.companyName.isNotEmpty ? p.companyName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(p.companyName),
                            subtitle: p.user?.email != null ? Text(p.user!.email) : null,
                            trailing: isSelected
                                ? const Icon(Iconsax.tick_circle, color: AppColors.primaryGreen)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onAssign(p.id);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Duration chip ─────────────────────────────────────────────────────────────

class _DurationChip extends StatelessWidget {
  final String label;
  final int? days;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.days,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF92400E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
