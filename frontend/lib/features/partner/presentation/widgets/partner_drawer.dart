import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';

class PartnerDrawer extends StatelessWidget {
  final String currentRoute;

  const PartnerDrawer({
    super.key,
    required this.currentRoute,
  });

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
                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Iconsax.home_2,
                    title: 'Tableau de bord',
                    route: AppRoutes.partnerDashboard,
                    isSelected: currentRoute == AppRoutes.partnerDashboard,
                  ),
                  _buildSectionTitle(context, 'Mes établissements'),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.building,
                    title: 'Tous les établissements',
                    route: AppRoutes.partnerEstablishments,
                    isSelected: currentRoute == AppRoutes.partnerEstablishments,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.add_circle,
                    title: 'Ajouter un établissement',
                    route: AppRoutes.partnerEstablishmentCreate,
                    isSelected: currentRoute == AppRoutes.partnerEstablishmentCreate,
                  ),
                  _buildSectionTitle(context, 'Statistiques'),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.chart,
                    title: 'Performances',
                    route: AppRoutes.partnerDashboard,
                    isSelected: false,
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
                  'Espace Partenaire',
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppDimens.paddingS),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: const Icon(
            Iconsax.logout,
            color: AppColors.grey600,
            size: AppDimens.iconS,
          ),
        ),
        title: Text(
          'Retour à l\'accueil',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey800,
              ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go(AppRoutes.main);
        },
      ),
    );
  }
}
