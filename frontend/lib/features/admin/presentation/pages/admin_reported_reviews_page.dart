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

class AdminReportedReviewsPage extends StatefulWidget {
  const AdminReportedReviewsPage({super.key});

  @override
  State<AdminReportedReviewsPage> createState() =>
      _AdminReportedReviewsPageState();
}

class _AdminReportedReviewsPageState extends State<AdminReportedReviewsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    _searchController.clear();
    context.read<AdminReviewsBloc>().add(const AdminReviewsLoadReported());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Avis signalés'),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminReportedReviews),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: TextField(
        style: TextStyle(color: AppColors.scaffoldBackground),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un avis signalé...',
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
        onChanged: (value) => context
            .read<AdminReviewsBloc>()
            .add(AdminReviewsSearch(query: value)),
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
            child: CircularProgressIndicator(color: AppColors.error),
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
                  color: AppColors.error,
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
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: const Icon(Iconsax.flag,
                color: AppColors.error, size: AppDimens.iconM),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count avis signalé${count > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  'Examinez et traitez les signalements',
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

    return Card(
      color: AppColors.scaffoldBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
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
                // Badge signalements
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.flag,
                          size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '${review.reportCount} signalement${review.reportCount > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
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

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context
                        .read<AdminReviewsBloc>()
                        .add(AdminReviewDismissReport(reviewId: review.id)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                    icon: const Icon(Iconsax.tick_circle, size: 18),
                    label: const Text('Ignorer'),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(review.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Iconsax.trash, size: 18),
                    label: const Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String reviewId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: const Text('Supprimer cet avis'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Raison de la suppression (min. 10 caractères)',
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
            child: const Text('Supprimer'),
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
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              decoration: BoxDecoration(
                color: AppColors.grey200.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Iconsax.flag, size: 64, color: AppColors.grey400),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text('Aucun avis signalé',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    )),
            const SizedBox(height: AppDimens.paddingS),
            Text('Aucun avis n\'a été signalé pour le moment',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.grey600),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.paddingXL),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Actualiser'),
            ),
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
