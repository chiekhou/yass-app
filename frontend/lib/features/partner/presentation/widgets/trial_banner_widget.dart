import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/subscription_model.dart';

class TrialBannerWidget extends StatelessWidget {
  final SubscriptionStatus status;

  const TrialBannerWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status.isActive) {
      return _buildActiveBanner(context);
    }
    if (status.isInTrial) {
      return _buildTrialBanner(context);
    }
    if (status.trialExpired) {
      return _buildExpiredBanner(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildActiveBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      decoration: BoxDecoration(
        color: AppColors.greenDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.tick_circle, color: AppColors.white, size: 18),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Text(
              'Abonnement actif — ${status.planLabel} · ${status.daysRemaining}j restants',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.partnerSubscription),
            child: Text(
              'Gérer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(BuildContext context) {
    final isUrgent = status.daysRemaining <= 3;
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.warning.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: isUrgent
              ? AppColors.warning.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Iconsax.warning_2 : Iconsax.timer_1,
            color: isUrgent ? AppColors.warning : AppColors.white,
            size: 18,
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Text(
              isUrgent
                  ? 'Essai expire dans ${status.daysRemaining}j — Abonnez-vous !'
                  : 'Période d\'essai — ${status.daysRemaining} jour${status.daysRemaining > 1 ? 's' : ''} restant${status.daysRemaining > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUrgent ? AppColors.warning : AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          GestureDetector(
            onTap: () => context.push(AppRoutes.partnerSubscription),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Text(
                'S\'abonner',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.close_circle, color: AppColors.error, size: 18),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Text(
              'Essai expiré — Vos établissements ne sont plus visibles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.redDark,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          GestureDetector(
            onTap: () => context.push(AppRoutes.partnerSubscription),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Text(
                'S\'abonner',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
