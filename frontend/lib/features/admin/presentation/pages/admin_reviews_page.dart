import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../reviews/data/models/review_model.dart';
import '../bloc/admin_reviews_bloc.dart';
import '../widgets/admin_drawer.dart';

class AdminReviewsPage extends StatefulWidget {
  final String initialTab;
  const AdminReviewsPage({super.key, this.initialTab = 'pending'});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  // 'pending' | 'reported' | 'all'
  late String _activeTab;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadReviews() {
    _searchController.clear();
    if (_activeTab == 'reported') {
      context.read<AdminReviewsBloc>().add(const AdminReviewsLoadReported());
    } else if (_activeTab == 'all') {
      context.read<AdminReviewsBloc>().add(AdminReviewsLoadAll(status: _statusFilter));
    } else {
      context.read<AdminReviewsBloc>().add(const AdminReviewsLoadPending());
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminReviewsBloc>().add(AdminReviewsLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(context.l10n.reviewsManagement),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminReviews),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterChips(context),
          Expanded(child: _buildReviewsList(context)),
        ],
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
          hintText: 'Rechercher un avis...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<AdminReviewsBloc>()
                        .add(const AdminReviewsSearch(query: ''));
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
              .read<AdminReviewsBloc>()
              .add(AdminReviewsSearch(query: value));
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Onglets principaux ──
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'En attente',
                  isSelected: _activeTab == 'pending',
                  color: AppColors.warning,
                  onTap: () {
                    setState(() { _activeTab = 'pending'; });
                    _loadReviews();
                  },
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Signalés',
                  isSelected: _activeTab == 'reported',
                  color: AppColors.error,
                  onTap: () {
                    setState(() { _activeTab = 'reported'; });
                    _loadReviews();
                  },
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Tous',
                  isSelected: _activeTab == 'all',
                  color: AppColors.primaryGreen,
                  onTap: () {
                    setState(() { _activeTab = 'all'; _statusFilter = 'all'; });
                    _loadReviews();
                  },
                ),
              ],
            ),
          ),
        ),
        // ── Sous-filtres statut (onglet "Tous" uniquement) ──
        if (_activeTab == 'all')
          Container(
            padding: const EdgeInsets.only(
              left: AppDimens.paddingM,
              right: AppDimens.paddingM,
              bottom: AppDimens.paddingS,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in {
                    'all': 'Tous les statuts',
                    'pending': 'En attente',
                    'approved': 'Approuvés',
                    'rejected': 'Rejetés',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: AppDimens.paddingS),
                      child: _buildFilterChip(
                        context,
                        label: entry.value,
                        isSelected: _statusFilter == entry.key,
                        color: entry.key == 'approved'
                            ? AppColors.success
                            : entry.key == 'rejected'
                                ? AppColors.error
                                : entry.key == 'pending'
                                    ? AppColors.warning
                                    : AppColors.grey500,
                        onTap: () {
                          setState(() { _statusFilter = entry.key; });
                          context.read<AdminReviewsBloc>().add(
                                AdminReviewsLoadAll(status: entry.key),
                              );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
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

  Widget _buildReviewsList(BuildContext context) {
    return BlocConsumer<AdminReviewsBloc, AdminReviewsState>(
      listener: (context, state) {
        if (state is AdminReviewActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadReviews();
        } else if (state is AdminReviewsError) {
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
        if (state is AdminReviewsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (state is AdminReviewsError) {
          return _buildErrorState(state.message);
        }

        if (state is AdminReviewsLoaded) {
          if (state.filteredReviews.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildCountHeader(context, state.filteredReviews.length),
              Expanded(
                child: RefreshIndicator(
            onRefresh: () async {
              context.read<AdminReviewsBloc>().add(AdminReviewsRefresh());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primaryGreen,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              itemCount:
                  state.filteredReviews.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.filteredReviews.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.paddingM),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final review = state.filteredReviews[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingXS,
                  ),
                  child: _buildReviewCard(review),
                );
              },
            ),
          ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCountHeader(BuildContext context, int count) {
    final isReported = (_activeTab == 'reported');
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: (isReported ? AppColors.error : AppColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Icon(
              isReported ? Iconsax.flag : Iconsax.message_text,
              color: isReported ? AppColors.error : AppColors.warning,
              size: AppDimens.iconM,
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count avis ${isReported ? 'signalé${count > 1 ? 's' : ''}' : 'en attente'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  isReported
                      ? 'Examinez et traitez les signalements'
                      : 'Approuvez ou rejetez les nouveaux avis',
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

  Widget _buildReviewCard(Review review) {
    final userName = review.user != null
        ? '${review.user!.firstName} ${review.user!.lastName}'
        : 'Utilisateur';
    final initials =
        review.user != null ? review.user!.firstName[0].toUpperCase() : 'U';
    final timeAgo = _formatTimeAgo(review.createdAt);

    const subRatingLabels = {
      'quality': 'Qualité',
      'welcome': 'Accueil',
      'information': 'Information',
      'value': 'Rapport qualité/prix',
      'availability': 'Disponibilité',
      'reliability': 'Fiabilité',
      'comfort': 'Confort',
    };

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

            // ── En-tête : avatar + nom + email + note + date ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.greenSurface,
                  backgroundImage: review.user?.avatar != null
                      ? NetworkImage(review.user!.avatar!)
                      : null,
                  child: review.user?.avatar == null
                      ? Text(initials,
                          style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (review.user?.email != null)
                        Text(
                          review.user!.email!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(
                            review.rating,
                            (i) => const Text('🇩🇿',
                                style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${review.rating}/5 · $timeAgo',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge statut
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_activeTab == 'reported')
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Text(
                    (_activeTab == 'reported')
                        ? context.l10n.statusReported
                        : context.l10n.statusPending,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: (_activeTab == 'reported')
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            // ── Établissement ciblé ──
            if (review.establishment != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              Row(
                children: [
                  const Icon(Iconsax.building, size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      review.establishment!.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Date de visite ──
            if (review.visitDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.calendar_1, size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    'Visité le ${_formatDate(review.visitDate!)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ],

            // ── Signalements ──
            if ((_activeTab == 'reported') && review.reportCount > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.flag, size: 13, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    '${review.reportCount} signalement${review.reportCount > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppDimens.paddingM),

            // ── Titre ──
            if (review.title != null && review.title!.isNotEmpty) ...[
              Text(
                review.title!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
            ],

            // ── Commentaire ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Text(
                review.comment,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
              ),
            ),

            // ── Pros ──
            if (review.hasPros) ...[
              const SizedBox(height: AppDimens.paddingS),
              ...review.pros!.map((pro) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            size: 14, color: AppColors.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(pro,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.grey700)),
                        ),
                      ],
                    ),
                  )),
            ],

            // ── Cons ──
            if (review.hasCons) ...[
              SizedBox(height: review.hasPros ? 2 : AppDimens.paddingS),
              ...review.cons!.map((con) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.remove_circle_outline_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(con,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.grey700)),
                        ),
                      ],
                    ),
                  )),
            ],

            // ── Sub-ratings ──
            if (review.hasSubRatings) ...[
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'Notes détaillées',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: AppDimens.paddingS),
              Wrap(
                spacing: AppDimens.paddingS,
                runSpacing: AppDimens.paddingXS,
                children: review.subRatings!.entries
                    .where((e) => e.value != null)
                    .map((e) {
                  final label =
                      subRatingLabels[e.key] ?? e.key;
                  final val = (e.value as num).toInt();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusS),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$val/5',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── Photos ──
            if (review.hasImages) ...[
              const SizedBox(height: AppDimens.paddingM),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusS),
                    child: Image.network(
                      review.images![i],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.grey200,
                        child: const Icon(Iconsax.image,
                            color: AppColors.grey400),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppDimens.paddingM),

            // ── Boutons d'action ──
            Row(
              children: [
                if (!(_activeTab == 'reported')) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<AdminReviewsBloc>().add(
                            AdminReviewApprove(reviewId: review.id),
                          ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Approuver'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(review.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      label: const Text('Rejeter'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<AdminReviewsBloc>().add(
                            AdminReviewDismissReport(reviewId: review.id),
                          ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Ignorer'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(review.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(Iconsax.trash, size: 18),
                      label: const Text('Supprimer'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]}. ${date.year}';
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
              onPressed: _loadReviews,
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
    final isReported = (_activeTab == 'reported');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: isReported
                    ? AppColors.grey200.withValues(alpha: 0.6)
                    : AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReported ? Iconsax.flag : Iconsax.tick_circle,
                size: 64,
                color: isReported ? AppColors.grey400 : AppColors.success,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              isReported ? 'Aucun avis signalé' : 'Tout est à jour !',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              isReported
                  ? 'Aucun avis signalé pour le moment'
                  : 'Aucun avis en attente d\'approbation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            OutlinedButton.icon(
              onPressed: _loadReviews,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(String reviewId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: Text((_activeTab == 'reported') ? 'Supprimer cet avis' : 'Rejeter cet avis'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Raison du rejet (min. 10 caractères)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().length >= 10) {
                context.read<AdminReviewsBloc>().add(
                      AdminReviewReject(
                        reviewId: reviewId,
                        reason: controller.text.trim(),
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text((_activeTab == 'reported') ? 'Supprimer' : 'Rejeter'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'il y a ${difference.inDays ~/ 365} an${difference.inDays ~/ 365 > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'il y a ${difference.inDays ~/ 30} mois';
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else {
      return 'à l\'instant';
    }
  }
}
