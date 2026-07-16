import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';

class NearbySection extends StatelessWidget {
  final List<Establishment>? establishments;
  final bool isLoading;
  const NearbySection({super.key, this.establishments, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.paddingL),
        child: Center(child: CircularProgressIndicator(color: AppColors.white)),
      );
    }

    if (establishments == null || establishments!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Center(
            child: Column(children: [
          const Icon(Iconsax.building_3, size: 48, color: AppColors.white),
          const SizedBox(height: AppDimens.paddingM),
          Text(context.l10n.noNearbyEstablishments,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.white),
              textAlign: TextAlign.center)
        ])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: establishments!.length,
      itemBuilder: (context, index) {
        final e = establishments![index];
        final imageUrl = e.coverImage ?? e.logo;

        return Padding(
          padding: EdgeInsets.only(
              bottom:
                  index < establishments!.length - 1 ? AppDimens.paddingM : 0),
          child: GestureDetector(
            onTap: () =>
                context.push(AppRoutes.establishment.replaceFirst(':id', e.id)),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Grande image ──
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimens.radiusM),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),

                  // ── Infos établissement ──
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom
                        Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Étoiles + note + avis
                        Row(
                          children: [
                            _StarRating(rating: e.averageRating),
                            const SizedBox(width: 6),
                            Text(
                              e.displayRating,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${e.totalReviews} avis)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Adresse + distance
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                e.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A8A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (e.distance != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${e.distance!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(Iconsax.image, color: AppColors.grey400, size: 40),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating && (rating - i) >= 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 14,
          color: const Color(0xFFFF8C00),
        );
      }),
    );
  }
}
