import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
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
          Text('Aucun établissement trouvé dans votre wilaya',
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
        return Padding(
          padding: EdgeInsets.only(
              bottom:
                  index < establishments!.length - 1 ? AppDimens.paddingM : 0),
          child: GestureDetector(
            onTap: () =>
                context.push(AppRoutes.establishment.replaceFirst(':id', e.id)),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]),
              child: Row(
                children: [
                  ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppDimens.radiusM)),
                      child: e.logo != null
                          ? Image.network(e.logo!,
                              width: 100, height: 100, fit: BoxFit.cover)
                          : Container(
                              width: 100,
                              height: 100,
                              color: AppColors.grey200,
                              child: const Icon(Iconsax.image,
                                  color: AppColors.grey400))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: AppDimens.paddingXS),
                          Text(e.address,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.grey600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: AppDimens.paddingS),
                          Row(children: [
                            const Text('🇩🇿', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 2),
                            Text(e.displayRating,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            if (e.distance != null) ...[
                              const Spacer(),
                              Text('${e.distance!.toStringAsFixed(1)} km',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.grey500))
                            ]
                          ]),
                        ],
                      ),
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
}
