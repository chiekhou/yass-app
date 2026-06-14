import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../establishment/data/models/establishment_model.dart';

class PartnerEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final bool isProcessing;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onStatusTap;

  const PartnerEstablishmentCard({
    super.key,
    required this.establishment,
    this.isProcessing = false,
    this.onTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.scaffoldBackground,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusM),
              ),
              child: Stack(
                children: [
                  establishment.coverImage != null
                      ? Image.network(
                          establishment.coverImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  Positioned(
                    top: AppDimens.paddingS,
                    right: AppDimens.paddingS,
                    child: _buildStatusBadge(context),
                  ),
                  if (isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          establishment.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (establishment.isVerified)
                        const Icon(
                          Iconsax.verify5,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        size: 14,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: AppDimens.paddingXS),
                      Expanded(
                        child: Text(
                          establishment.address,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.white,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        icon: Iconsax.eye,
                        value: establishment.totalViews.toString(),
                        label: 'Vues',
                      ),
                      const SizedBox(width: AppDimens.paddingL),
                      _buildStatItem(
                        context,
                        icon: Iconsax.heart,
                        value: establishment.totalFavorites.toString(),
                        label: 'Favoris',
                      ),
                      const SizedBox(width: AppDimens.paddingL),
                      _buildStatItem(
                        context,
                        icon: Iconsax.star,
                        value: establishment.displayRating,
                        label: '(${establishment.totalReviews})',
                      ),
                      const Spacer(),
                      _buildActions(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.grey200,
      child: const Center(
        child: Icon(
          Iconsax.building,
          size: 40,
          color: AppColors.grey400,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String label;

    switch (establishment.status) {
      case 'active':
        color = AppColors.success;
        label = context.l10n.statusActive;
        break;
      case 'pending':
        color = AppColors.warning;
        label = context.l10n.statusPending;
        break;
      case 'rejected':
        color = AppColors.error;
        label = context.l10n.statusRejected;
        break;
      case 'inactive':
        color = AppColors.grey500;
        label = 'Inactif';
        break;
      default:
        color = AppColors.grey500;
        label = establishment.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.white),
        const SizedBox(width: AppDimens.paddingXS),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Iconsax.more, color: AppColors.greenAccent, size: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Iconsax.edit, size: 18),
              SizedBox(width: AppDimens.paddingS),
              Text('Modifier'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(Iconsax.toggle_on_circle, size: 18),
              SizedBox(width: AppDimens.paddingS),
              Text('Changer statut'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Iconsax.trash, size: 18, color: AppColors.error),
              const SizedBox(width: AppDimens.paddingS),
              Text('Supprimer', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEditTap?.call();
            break;
          case 'status':
            onStatusTap?.call();
            break;
          case 'delete':
            onDeleteTap?.call();
            break;
        }
      },
    );
  }
}
