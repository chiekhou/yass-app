import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000)
    return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}k';
  return count.toString();
}

class FeaturedSection extends StatelessWidget {
  final List<Establishment>? establishments;
  const FeaturedSection({super.key, this.establishments});

  @override
  Widget build(BuildContext context) {
    if (establishments == null || establishments!.isEmpty) {
      return SizedBox(
          height: 220,
          child: Center(
              child: Text(context.l10n.noFeatured,
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
                        // Badge "À la une"
                        Positioned(
                          top: AppDimens.paddingS,
                          left: AppDimens.paddingS,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'À la une',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                const Text('🇩🇿',
                                    style: TextStyle(fontSize: 12)),
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
                                    color:
                                        AppColors.white.withValues(alpha: 0.8),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: AppColors.grey600),
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
                          const SizedBox(height: AppDimens.paddingXS),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 13, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  e.totalReviews > 0
                                      ? '${e.displayRating} sur ${_formatCount(e.totalReviews)} avis'
                                      : 'Aucun avis',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.grey700,
                                          fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppDimens.paddingS),
                              const Icon(Iconsax.eye,
                                  size: 13, color: AppColors.grey400),
                              const SizedBox(width: 3),
                              Text(
                                _formatCount(e.totalViews),
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
