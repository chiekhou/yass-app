import 'dart:async';

import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/pagination_bar.dart';
import '../../../../app_router.dart';
import '../../../reviews/data/models/review_model.dart';
import '../bloc/admin_reviews_bloc.dart';
import '../widgets/admin_drawer.dart';

class AdminAllReviewsPage extends StatefulWidget {
  const AdminAllReviewsPage({super.key});

  @override
  State<AdminAllReviewsPage> createState() => _AdminAllReviewsPageState();
}

class _AdminAllReviewsPageState extends State<AdminAllReviewsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _statusFilter = 'all';

  static const _statusOptions = {
    'all': 'Tous',
    'pending': 'En attente',
    'approved': 'Approuvés',
    'rejected': 'Rejetés',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _load({String? status}) {
    final s = status ?? _statusFilter;
    context.read<AdminReviewsBloc>().add(AdminReviewsLoadAll(status: s));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Tous les avis'),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminReviews),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingM,
        AppDimens.paddingM,
        AppDimens.paddingM,
        AppDimens.paddingS,
      ),
      color: AppColors.white,
      child: TextField(
        style: TextStyle(color: AppColors.scaffoldBackground),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un avis...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchDebounce?.cancel();
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
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 400), () {
            context
                .read<AdminReviewsBloc>()
                .add(AdminReviewsSearch(query: value));
          });
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.grey200),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
            ),
            child: Row(
              children: [
                const Icon(Iconsax.filter, size: 14, color: AppColors.grey500),
                const SizedBox(width: 6),
                Text(
                  'Statut :',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusOptions.entries.map((entry) {
                        final isSelected = _statusFilter == entry.key;
                        final color = switch (entry.key) {
                          'approved' => AppColors.success,
                          'rejected' => AppColors.error,
                          'pending' => AppColors.warning,
                          _ => AppColors.primaryGreen,
                        };
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: AppDimens.paddingS),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _statusFilter = entry.key);
                              _load(status: entry.key);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingM,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? color : AppColors.grey100,
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusRound),
                                border: Border.all(
                                  color: isSelected ? color : AppColors.grey300,
                                ),
                              ),
                              child: Text(
                                entry.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.grey700,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey200),
        ],
      ),
    );
  }

  Widget _buildList() {
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
          _load();
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
          return _buildError(state.message);
        }
        if (state is AdminReviewsLoaded) {
          if (state.filteredReviews.isEmpty) return _buildEmpty();
          return Column(
            children: [
              _buildHeader(state.totalCount),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<AdminReviewsBloc>().add(AdminReviewsRefresh());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.primaryGreen,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingM),
                    itemCount: state.filteredReviews.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingM,
                        vertical: AppDimens.paddingXS,
                      ),
                      child: _buildCard(state.filteredReviews[index]),
                    ),
                  ),
                ),
              ),
              PaginationBar(
                currentPage: state.currentPage,
                totalPages: state.totalPages,
                total: state.totalCount,
                isLoading: state.isPageLoading,
                onPageChanged: (page) {
                  context
                      .read<AdminReviewsBloc>()
                      .add(AdminReviewsGoToPage(page: page));
                  _scrollController.jumpTo(0);
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: const Icon(Iconsax.star,
                color: AppColors.primaryGreen, size: AppDimens.iconM),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count avis trouvé${count > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  'Gérez l\'ensemble des avis de la plateforme',
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

  Widget _buildCard(Review review) {
    final userName = review.user != null
        ? '${review.user!.firstName} ${review.user!.lastName}'
        : 'Utilisateur';
    final initials =
        review.user != null ? review.user!.firstName[0].toUpperCase() : 'U';
    final timeAgo = _formatTimeAgo(review.createdAt);

    final (badgeLabel, badgeColor) = switch (review.status) {
      'approved' => ('Approuvé', AppColors.success),
      'rejected' => ('Rejeté', AppColors.error),
      _ => ('En attente', AppColors.warning),
    };

    return Card(
      color: AppColors.scaffoldBackground,
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
            // ── En-tête ──
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
                          review.user!.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.white),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(
                              review.rating,
                              (i) => const Text('🇩🇿',
                                  style: TextStyle(fontSize: 11))),
                          const SizedBox(width: 4),
                          Text(
                            '${review.rating}/5 · $timeAgo',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Text(
                    badgeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            if (review.establishment != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              Row(
                children: [
                  const Icon(Iconsax.building,
                      size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(review.establishment!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            )),
                  ),
                ],
              ),
            ],

            if (review.visitDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.calendar_1,
                      size: 13, color: AppColors.grey400),
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

            if (review.reportCount > 0) ...[
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

            if (review.title != null && review.title!.isNotEmpty) ...[
              Text(review.title!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
            ],

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

            const SizedBox(height: AppDimens.paddingM),

            // ── Actions selon le statut ──
            if (review.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context
                          .read<AdminReviewsBloc>()
                          .add(AdminReviewApprove(reviewId: review.id)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Approuver'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(review.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      label: const Text('Rejeter'),
                    ),
                  ),
                ],
              )
            else if (review.status == 'approved')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context
                      .read<AdminReviewsBloc>()
                      .add(AdminReviewRevoke(reviewId: review.id)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey600,
                    side: const BorderSide(color: AppColors.grey300),
                  ),
                  icon: const Icon(Iconsax.minus_cirlce, size: 18),
                  label: const Text('Révoquer'),
                ),
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
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: const Text('Rejeter cet avis'),
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
                context.read<AdminReviewsBloc>().add(AdminReviewReject(
                      reviewId: reviewId,
                      reason: controller.text.trim(),
                    ));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rejeter'),
          ),
        ],
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
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingL),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: _load,
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.star, size: 64, color: AppColors.grey300),
            const SizedBox(height: AppDimens.paddingL),
            Text('Aucun avis trouvé',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    )),
            const SizedBox(height: AppDimens.paddingS),
            Text('Aucun avis ne correspond à ce filtre',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${date.day} ${months[date.month - 1]}. ${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) {
      return 'il y a ${diff.inDays ~/ 365} an${diff.inDays ~/ 365 > 1 ? 's' : ''}';
    } else if (diff.inDays > 30) {
      return 'il y a ${diff.inDays ~/ 30} mois';
    } else if (diff.inDays > 0) {
      return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'il y a ${diff.inHours}h';
    }
    return 'à l\'instant';
  }
}
