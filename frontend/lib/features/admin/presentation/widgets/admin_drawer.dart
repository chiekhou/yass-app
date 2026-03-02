import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/repositories/admin_repository.dart';

class AdminDrawer extends StatefulWidget {
  final String currentRoute;

  const AdminDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  int _pendingPartners = 0;
  int _pendingEstablishments = 0;
  int _pendingReviews = 0;
  int _reportedReviews = 0;
  int _pendingPayments = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final repo = AdminRepository();
      final stats = await repo.getDashboardStats();
      final payments = await repo.getPendingPayments();
      if (mounted) {
        setState(() {
          _pendingPartners = stats.pendingPartners;
          _pendingEstablishments = stats.pendingEstablishments;
          _pendingReviews = stats.pendingReviews;
          _reportedReviews = stats.reportedReviews;
          _pendingPayments = payments.length;
        });
      }
    } catch (_) {}
  }

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
                    title: 'Tableau de bord',
                    route: AppRoutes.adminDashboard,
                    isSelected: widget.currentRoute == AppRoutes.adminDashboard,
                  ),
                  _buildSectionTitle(context, 'Gestion'),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.people,
                    title: 'Gestion Utilisateurs',
                    route: AppRoutes.adminUsers,
                    isSelected: widget.currentRoute == AppRoutes.adminUsers,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.briefcase,
                    title: 'Gestion Partenaires',
                    route: AppRoutes.adminPartners,
                    isSelected: widget.currentRoute == AppRoutes.adminPartners,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.user_add,
                    title: 'Ajouter un partenaire',
                    route: AppRoutes.adminCreatePartner,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminCreatePartner,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.clock,
                    title: 'Partenaires en attente',
                    route: AppRoutes.adminPendingPartners,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminPendingPartners,
                    badgeCount: _pendingPartners,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.building,
                    title: 'Établissements en attente',
                    route: AppRoutes.adminPendingEstablishments,
                    isSelected: widget.currentRoute ==
                        AppRoutes.adminPendingEstablishments,
                    badgeCount: _pendingEstablishments,
                  ),
                  _buildSectionTitle(context, 'Modération'),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.message_text,
                    title: 'Avis en attente',
                    route: AppRoutes.adminPendingReviews,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminPendingReviews,
                    badgeCount: _pendingReviews,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.flag,
                    title: 'Avis signalés',
                    route: AppRoutes.adminReportedReviews,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminReportedReviews,
                    badgeCount: _reportedReviews,
                  ),
                  _buildSectionTitle(context, 'Paiements'),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.money_recive,
                    title: 'Paiements en attente',
                    route: AppRoutes.adminPendingPayments,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminPendingPayments,
                    badgeCount: _pendingPayments,
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
                'A',
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
                  'Administration',
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
