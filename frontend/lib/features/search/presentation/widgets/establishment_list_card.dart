import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';

class EstablishmentListCard extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback? onTap;

  const EstablishmentListCard({
    super.key,
    required this.establishment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () => context.push(
              AppRoutes.establishment.replaceFirst(':id', establishment.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppDimens.radiusM),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: establishment.coverImage != null
                    ? Image.network(
                        establishment.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Verified badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            establishment.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (establishment.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: AppDimens.paddingXS),
                            child: Icon(
                              Iconsax.verify5,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.paddingXS),

                    // Category
                    if (establishment.category != null)
                      Text(
                        establishment.category!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: AppDimens.paddingXS),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location,
                          size: 14,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: AppDimens.paddingXS),
                        Expanded(
                          child: Text(
                            establishment.wilaya?.name ?? establishment.address,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.paddingS),

                    // Rating & Price
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.starFilled.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusXS),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.starFilled,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                establishment.displayRating,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.starFilled,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: AppDimens.paddingS),

                        // Reviews count
                        Text(
                          '(${establishment.totalReviews} avis)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey500,
                                  ),
                        ),

                        const Spacer(),

                        // Price range
                        if (establishment.priceRange != null)
                          Text(
                            establishment.priceRange!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(
          Iconsax.image,
          color: AppColors.grey400,
          size: 32,
        ),
      ),
    );
  }
}
