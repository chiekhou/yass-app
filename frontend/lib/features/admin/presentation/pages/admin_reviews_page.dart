import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../reviews/data/models/review_model.dart';
import '../bloc/admin_reviews_bloc.dart';
import '../widgets/admin_drawer.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isReportedTab = false;

  @override
  void initState() {
    super.initState();
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
    if (_isReportedTab) {
      context.read<AdminReviewsBloc>().add(const AdminReviewsLoadReported());
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
        title: const Text('Gestion des avis'),
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
    return Container(
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
              isSelected: !_isReportedTab,
              color: AppColors.warning,
              onTap: () {
                setState(() => _isReportedTab = false);
                _searchController.clear();
                context
                    .read<AdminReviewsBloc>()
                    .add(const AdminReviewsLoadPending());
              },
            ),
            const SizedBox(width: AppDimens.paddingS),
            _buildFilterChip(
              context,
              label: 'Signalés',
              isSelected: _isReportedTab,
              color: AppColors.error,
              onTap: () {
                setState(() => _isReportedTab = true);
                _searchController.clear();
                context
                    .read<AdminReviewsBloc>()
                    .add(const AdminReviewsLoadReported());
              },
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
    final isReported = _isReportedTab;
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
            // User info + rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.greenSurface,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: Theme.of(context).textTheme.titleSmall),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: i < review.rating
                                  ? AppColors.starFilled
                                  : AppColors.starEmpty,
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Text(
                            timeAgo,
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
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isReportedTab
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Text(
                    _isReportedTab ? 'Signalé' : 'En attente',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _isReportedTab
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.paddingM),

            // Comment
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

            // Action buttons
            Row(
              children: [
                if (!_isReportedTab) ...[
                  // Approve
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AdminReviewsBloc>().add(
                              AdminReviewApprove(reviewId: review.id),
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Approuver'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  // Reject
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
                  // Dismiss report
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AdminReviewsBloc>().add(
                              AdminReviewDismissReport(reviewId: review.id),
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Ignorer'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  // Delete the review
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
              label: const Text(AppStrings.retry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isReported = _isReportedTab;
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
        title: Text(_isReportedTab ? 'Supprimer cet avis' : 'Rejeter cet avis'),
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
            child: Text(_isReportedTab ? 'Supprimer' : 'Rejeter'),
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
