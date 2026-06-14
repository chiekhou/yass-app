import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/admin_establishment_model.dart';

class EstablishmentApprovalCard extends StatelessWidget {
  final AdminEstablishment establishment;
  final VoidCallback? onTap;
  final VoidCallback? onApproveTap;
  final VoidCallback? onRejectTap;
  final bool isProcessing;

  const EstablishmentApprovalCard({
    super.key,
    required this.establishment,
    this.onTap,
    this.onApproveTap,
    this.onRejectTap,
    this.isProcessing = false,
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
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstablishmentInfo(context),
                  const SizedBox(height: AppDimens.paddingM),
                  _buildDetails(context),
                  if (establishment.partner != null) ...[
                    const SizedBox(height: AppDimens.paddingM),
                    _buildPartnerInfo(context),
                  ],
                  const SizedBox(height: AppDimens.paddingM),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusM),
          ),
          child: establishment.coverImage != null
              ? CachedNetworkImage(
                  imageUrl: establishment.coverImage!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 120,
                    color: AppColors.grey200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: AppColors.grey200,
                    child: const Icon(Iconsax.image, color: AppColors.grey400),
                  ),
                )
              : Container(
                  height: 120,
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(
                      Iconsax.building,
                      size: 48,
                      color: AppColors.primaryGreen.withValues(alpha: 0.5),
                    ),
                  ),
                ),
        ),
        Positioned(
          top: AppDimens.paddingS,
          right: AppDimens.paddingS,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingS,
              vertical: AppDimens.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(AppDimens.radiusXS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.clock, size: 12, color: AppColors.white),
                const SizedBox(width: AppDimens.paddingXS),
                Text(
                  context.l10n.statusPending,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (establishment.logo != null)
          Positioned(
            bottom: -24,
            left: AppDimens.paddingM,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(color: AppColors.grey200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusS - 2),
                child: CachedNetworkImage(
                  imageUrl: establishment.logo!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Iconsax.building,
                    color: AppColors.grey400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEstablishmentInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: establishment.logo != null ? 60 : 0,
        top: establishment.logo != null ? 0 : AppDimens.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            establishment.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
          ),
          if (establishment.categoryName != null) ...[
            const SizedBox(height: AppDimens.paddingXS),
            Row(
              children: [
                Icon(Iconsax.category, size: 12, color: AppColors.primaryGreen),
                const SizedBox(width: AppDimens.paddingXS),
                Text(
                  establishment.categoryName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      children: [
        if (establishment.description != null) ...[
          Text(
            establishment.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.paddingS),
        ],
        _buildInfoRow(
          context,
          icon: Iconsax.location,
          text: establishment.address ?? 'Adresse non spécifiée',
        ),
        if (establishment.wilayaName != null) ...[
          const SizedBox(height: AppDimens.paddingXS),
          _buildInfoRow(
            context,
            icon: Iconsax.map,
            text:
                '${establishment.communeName ?? ''} - ${establishment.wilayaName}',
          ),
        ],
        if (establishment.phone != null) ...[
          const SizedBox(height: AppDimens.paddingXS),
          _buildInfoRow(
            context,
            icon: Iconsax.call,
            text: establishment.phone!,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.white),
        const SizedBox(width: AppDimens.paddingS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerInfo(BuildContext context) {
    final partner = establishment.partner!;
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingS),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusXS),
            ),
            child: Center(
              child: Icon(
                Iconsax.briefcase,
                size: 16,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partenaire',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                        fontSize: 10,
                      ),
                ),
                Text(
                  partner.companyName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey800,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingXS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: partner.isApproved
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusXS),
            ),
            child: Text(
              partner.statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: partner.isApproved
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.paddingS),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRejectTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
            ),
            icon: const Icon(Iconsax.close_circle, size: 16),
            label: const Text('Rejeter'),
          ),
        ),
        const SizedBox(width: AppDimens.paddingS),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApproveTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
            ),
            icon: const Icon(Iconsax.tick_circle, size: 16),
            label: const Text('Approuver'),
          ),
        ),
      ],
    );
  }
}
