import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/admin_partner_model.dart';

class PartnerListItem extends StatelessWidget {
  final AdminPartner partner;
  final VoidCallback? onTap;
  final VoidCallback? onApproveTap;
  final VoidCallback? onRejectTap;
  final VoidCallback? onSuspendTap;
  final bool isProcessing;

  const PartnerListItem({
    super.key,
    required this.partner,
    this.onTap,
    this.onApproveTap,
    this.onRejectTap,
    this.onSuspendTap,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.scaffoldBackground,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingXS,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(child: _buildPartnerInfo(context)),
                  _buildStatusBadge(context),
                ],
              ),
              if (partner.user != null) ...[
                const SizedBox(height: AppDimens.paddingM),
                _buildUserInfo(context),
              ],
              if (partner.isPending || onSuspendTap != null) ...[
                const SizedBox(height: AppDimens.paddingM),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Center(
        child: Text(
          partner.companyName.isNotEmpty
              ? partner.companyName[0].toUpperCase()
              : 'P',
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partner.companyName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.paddingXS),
        Row(
          children: [
            Icon(Iconsax.building, size: 12, color: AppColors.grey500),
            const SizedBox(width: AppDimens.paddingXS),
            Text(
              '${partner.establishmentsCount} établissement(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                  ),
            ),
          ],
        ),
        if (partner.registrationNumber != null) ...[
          const SizedBox(height: AppDimens.paddingXS),
          Row(
            children: [
              Icon(Iconsax.document, size: 12, color: AppColors.grey500),
              const SizedBox(width: AppDimens.paddingXS),
              Text(
                'RC: ${partner.registrationNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData icon;
    switch (partner.status) {
      case 'approved':
        color = AppColors.success;
        icon = Iconsax.verify5;
        break;
      case 'pending':
        color = AppColors.warning;
        icon = Iconsax.clock;
        break;
      case 'rejected':
        color = AppColors.error;
        icon = Iconsax.close_circle;
        break;
      case 'suspended':
        color = AppColors.grey600;
        icon = Iconsax.slash;
        break;
      default:
        color = AppColors.grey500;
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppDimens.paddingXS),
          Text(
            partner.statusLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final user = partner.user!;
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingS),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.grey200,
            backgroundImage:
                user.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user.avatar == null
                ? Text(
                    user.firstName.isNotEmpty
                        ? user.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey800,
                      ),
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          if (user.phone != null)
            Icon(Iconsax.call, size: 14, color: AppColors.grey400),
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

    // Partenaire en attente → Rejeter / Approuver
    if (partner.isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRejectTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
              ),
              icon: const Icon(Iconsax.close_circle, size: 16),
              label: Text(context.l10n.reject),
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onApproveTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
              ),
              icon: const Icon(Iconsax.tick_circle, size: 16),
              label: Text(context.l10n.approve),
            ),
          ),
        ],
      );
    }

    // Partenaire approuvé → Suspendre
    if (onSuspendTap != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onSuspendTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
            padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
          ),
          icon: const Icon(Iconsax.slash, size: 16),
          label: Text(context.l10n.suspendPartner),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
