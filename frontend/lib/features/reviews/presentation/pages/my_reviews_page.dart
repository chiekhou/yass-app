import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/review_model.dart';
import '../bloc/review_bloc.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReviewBloc>().add(const ReviewLoadMine());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.myReviews),
      ),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avis supprimé'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<ReviewBloc>().add(const ReviewLoadMine());
          } else if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is ReviewMyListLoaded) {
            if (state.reviews.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReviewBloc>().add(const ReviewLoadMine());
              },
              color: AppColors.primaryGreen,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                itemCount: state.reviews.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimens.paddingM),
                itemBuilder: (context, index) {
                  return _buildMyReviewCard(state.reviews[index]);
                },
              ),
            );
          }

          if (state is ReviewError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2,
                      size: 48, color: AppColors.grey400),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReviewBloc>().add(const ReviewLoadMine());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.message_text, size: 64, color: AppColors.white),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'Vous n\'avez pas encore d\'avis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Vos avis apparaîtront ici',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReviewCard(Review review) {
    final timeAgo = _formatTimeAgo(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Establishment name
          if (review.establishment != null) ...[
            GestureDetector(
              onTap: () {
                final slug = review.establishment!.slug;
                if (slug != null && slug.isNotEmpty) {
                  context.push('/e/$slug');
                } else {
                  context.push('/establishment/${review.establishment!.id}');
                }
              },
              child: Row(
                children: [
                  const Icon(Iconsax.building_3,
                      size: 14, color: AppColors.primaryGreen),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      review.establishment!.name,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Iconsax.arrow_right_3,
                      size: 12, color: AppColors.primaryGreen),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            const Divider(height: 1, color: AppColors.grey100),
            const SizedBox(height: AppDimens.paddingS),
          ],

          // Header with rating and status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: i < review.rating
                            ? AppColors.starFilled
                            : AppColors.starEmpty,
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey500,
                          ),
                    ),
                  ],
                ),
              ),
              // Status badge
              _buildStatusBadge(review.status),
              // More options
              PopupMenuButton<String>(
                icon: const Icon(Iconsax.more,
                    size: 20, color: AppColors.grey500),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(review.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Supprimer',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingS),

          // Comment
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                  height: 1.4,
                ),
          ),

          // Rejection reason
          if (review.isRejected && review.hasRejectionReason) ...[
            const SizedBox(height: AppDimens.paddingS),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.info_circle,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: AppDimens.paddingXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raison du rejet',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.rejectionReason!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Partner reply
          if (review.hasPartnerReply) ...[
            const SizedBox(height: AppDimens.paddingS),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.message_text_1,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: AppDimens.paddingXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réponse du propriétaire',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.partnerReply!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Helpful count
          if (review.helpfulCount > 0) ...[
            const SizedBox(height: AppDimens.paddingS),
            Row(
              children: [
                const Icon(Iconsax.like_1, size: 14, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(
                  '${review.helpfulCount} personne${review.helpfulCount > 1 ? 's' : ''} ${review.helpfulCount > 1 ? 'ont' : 'a'} trouvé cet avis utile',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'Publié';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'En attente';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Rejeté';
        break;
      default:
        color = AppColors.grey500;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  void _showDeleteDialog(String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: const Text('Supprimer cet avis ?'),
        content: const Text(
          'Cette action est irréversible. Votre avis sera définitivement supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ReviewBloc>().add(ReviewDelete(reviewId: reviewId));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
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
