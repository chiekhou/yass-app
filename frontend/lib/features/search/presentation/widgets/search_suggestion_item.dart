import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';

class SearchSuggestionItem extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback? onTap;

  const SearchSuggestionItem({
    super.key,
    required this.establishment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ??
          () => context.push(
              AppRoutes.establishment.replaceFirst(':id', establishment.id)),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        clipBehavior: Clip.antiAlias,
        child: establishment.logo != null
            ? Image.network(
                establishment.logo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Iconsax.shop,
                  color: AppColors.grey400,
                ),
              )
            : const Icon(
                Iconsax.shop,
                color: AppColors.grey400,
              ),
      ),
      title: Text(
        establishment.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (establishment.category != null) ...[
            Text(
              establishment.category!.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(width: AppDimens.paddingXS),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.grey400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimens.paddingXS),
          ],
          Expanded(
            child: Text(
              establishment.wilaya?.name ?? establishment.address,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (establishment.isVerified)
            const Icon(
              Iconsax.verify5,
              color: AppColors.primaryGreen,
              size: 16,
            ),
          const SizedBox(width: AppDimens.paddingXS),
          const Icon(
            Iconsax.arrow_right_3,
            color: AppColors.grey400,
            size: 16,
          ),
        ],
      ),
    );
  }
}
