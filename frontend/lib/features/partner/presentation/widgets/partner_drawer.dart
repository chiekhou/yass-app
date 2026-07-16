import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class PartnerDrawer extends StatefulWidget {
  final String currentRoute;

  const PartnerDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  State<PartnerDrawer> createState() => _PartnerDrawerState();
}

class _PartnerDrawerState extends State<PartnerDrawer> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Iconsax.home_2,
                    title: context.l10n.dashboard,
                    route: AppRoutes.partnerDashboard,
                    isSelected:
                        widget.currentRoute == AppRoutes.partnerDashboard,
                  ),
                  _buildSectionTitle(context, context.l10n.myEstablishments),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.building,
                    title: context.l10n.allEstablishments,
                    route: AppRoutes.partnerEstablishments,
                    isSelected:
                        widget.currentRoute == AppRoutes.partnerEstablishments,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.add_circle,
                    title: context.l10n.addEstablishment,
                    route: AppRoutes.partnerEstablishmentCreate,
                    isSelected: widget.currentRoute ==
                        AppRoutes.partnerEstablishmentCreate,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.star,
                    title: context.l10n.myReviews,
                    route: AppRoutes.partnerReviews,
                    isSelected: widget.currentRoute == AppRoutes.partnerReviews,
                  ),
                  _buildSectionTitle(context, context.l10n.statistics),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.chart,
                    title: context.l10n.performances,
                    route: AppRoutes.partnerDashboard,
                    isSelected: false,
                  ),
                  _buildSectionTitle(context, context.l10n.myAccount),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.award,
                    title: context.l10n.mySubscription,
                    route: AppRoutes.partnerSubscription,
                    isSelected:
                        widget.currentRoute == AppRoutes.partnerSubscription,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.receipt,
                    title: context.l10n.myInvoices,
                    route: AppRoutes.partnerInvoices,
                    isSelected:
                        widget.currentRoute == AppRoutes.partnerInvoices,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.partnerSpace,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                ),
                Text(
                  'Win - وِين',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingL,
        AppDimens.paddingM,
        AppDimens.paddingL,
        AppDimens.paddingS,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.grey500,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimens.paddingS),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primaryGreen : AppColors.grey600,
          size: AppDimens.iconS,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? AppColors.primaryGreen : AppColors.grey800,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: AppDimens.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: AppColors.primaryGreen.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingXS,
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: const Icon(
                  Iconsax.home_2,
                  color: AppColors.grey600,
                  size: AppDimens.iconS,
                ),
              ),
              title: Text(
                context.l10n.home,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey800,
                    ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
              ),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.main);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.logout, color: AppColors.error),
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ),
        ],
      ),
    );
  }
}
