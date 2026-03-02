import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';

class FeaturedSection extends StatelessWidget {
  final List<Establishment>? establishments;
  const FeaturedSection({super.key, this.establishments});

  @override
  Widget build(BuildContext context) {
    if (establishments == null || establishments!.isEmpty) {
      return SizedBox(
          height: 220,
          child: Center(
              child: Text('Aucun établissement à la une',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.white))));
    }
    return SizedBox(
      height: 230,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
        scrollDirection: Axis.horizontal,
        itemCount: establishments!.length,
        itemBuilder: (context, index) {
          final e = establishments![index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < establishments!.length - 1
                    ? AppDimens.paddingM
                    : 0),
            child: GestureDetector(
              onTap: () => context
                  .push(AppRoutes.establishment.replaceFirst(':id', e.id)),
              child: Container(
                width: 260,
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image + rank badge overlay
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimens.radiusL)),
                          child: e.coverImage != null
                              ? Image.network(e.coverImage!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Container(
                                      height: 120,
                                      color: AppColors.grey200,
                                      child: const Icon(Iconsax.image,
                                          color: AppColors.grey400, size: 40)))
                              : Container(
                                  height: 120,
                                  color: AppColors.grey200,
                                  child: const Icon(Iconsax.image,
                                      color: AppColors.grey400, size: 40)),
                        ),
                        // Rank badge (top 3 get medal colors)
                        Positioned(
                          top: AppDimens.paddingS,
                          left: AppDimens.paddingS,
                          child: _RankBadge(rank: index + 1),
                        ),
                        // Rating overlay (bottom right of image)
                        Positioned(
                          bottom: AppDimens.paddingS,
                          right: AppDimens.paddingS,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.starFilled, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  e.displayRating,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '(${e.totalReviews})',
                                  style: TextStyle(
                                    color: AppColors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Info section
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(e.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            if (e.isVerified)
                              const Icon(Iconsax.verify5,
                                  color: AppColors.primaryGreen, size: 18)
                          ]),
                          const SizedBox(height: AppDimens.paddingXS),
                          Row(children: [
                            const Icon(Iconsax.location,
                                color: AppColors.grey500, size: 14),
                            const SizedBox(width: AppDimens.paddingXS),
                            Expanded(
                              child: Text(
                                e.wilaya?.name ?? e.address,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.grey600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (e.category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.category!.name,
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rank badge widget — gold/silver/bronze for top 3, white for others
class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      const medals = ['🥇', '🥈', '🥉'];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(medals[rank - 1], style: const TextStyle(fontSize: 14)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
