import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_stats_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

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
  int _pendingSuggestions = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    if (!mounted) return;
    final repo = AdminRepository();

    // Chaque appel est indépendant — une erreur n'annule pas les autres
    final statsFuture = repo
        .getDashboardStats()
        .then<AdminStats?>((v) => v)
        .catchError((_) => null);
    final paymentsFuture =
        repo.getPendingPayments().catchError((_) => <Map<String, dynamic>>[]);
    final suggestionsFuture =
        repo.getPendingSuggestionsCount().catchError((_) => 0);

    final results =
        await Future.wait([statsFuture, paymentsFuture, suggestionsFuture]);

    if (!mounted) return;
    setState(() {
      final stats = results[0] as AdminStats?;
      final payments = results[1] as List<Map<String, dynamic>>;
      final suggestions = results[2] as int;
      if (stats != null) {
        _pendingPartners = stats.pendingPartners;
        _pendingEstablishments = stats.pendingEstablishments;
        _pendingReviews = stats.pendingReviews;
        _reportedReviews = stats.reportedReviews;
      }
      _pendingPayments = payments.length;
      _pendingSuggestions = suggestions;
    });
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
                    title: context.l10n.dashboard,
                    route: AppRoutes.adminDashboard,
                    isSelected: widget.currentRoute == AppRoutes.adminDashboard,
                  ),
                  _buildSectionTitle(context, context.l10n.management),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.people,
                    title: context.l10n.managementUsers,
                    route: AppRoutes.adminUsers,
                    isSelected: widget.currentRoute == AppRoutes.adminUsers,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.briefcase,
                    title: context.l10n.managementPartners,
                    route: AppRoutes.adminPartners,
                    isSelected: widget.currentRoute == AppRoutes.adminPartners,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.user_add,
                    title: context.l10n.addPartner,
                    route: AppRoutes.adminCreatePartner,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminCreatePartner,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.clock,
                    title: context.l10n.pendingPartners,
                    route: AppRoutes.adminPendingPartners,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminPendingPartners,
                    badgeCount: _pendingPartners,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.buildings,
                    title: context.l10n.managementEstablishments,
                    route: AppRoutes.adminEstablishments,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminEstablishments,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.building_4,
                    title: context.l10n.addEstablishment,
                    route: AppRoutes.adminCreateEstablishment,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminCreateEstablishment,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        AppRoutes.adminCreateEstablishment,
                        extra: {'partnerId': '', 'partnerName': ''},
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.building,
                    title: context.l10n.pendingEstablishments,
                    route: AppRoutes.adminPendingEstablishments,
                    isSelected: widget.currentRoute ==
                        AppRoutes.adminPendingEstablishments,
                    badgeCount: _pendingEstablishments,
                  ),
                  _buildSectionTitle(context, context.l10n.moderation),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.star,
                    title: context.l10n.allReviews,
                    route: AppRoutes.adminReviews,
                    isSelected: widget.currentRoute == AppRoutes.adminReviews,
                    badgeCount: _pendingReviews,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.flag,
                    title: context.l10n.reportedReviews,
                    route: AppRoutes.adminReportedReviews,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminReportedReviews,
                    badgeCount: _reportedReviews,
                  ),
                  _buildSectionTitle(context, context.l10n.paymentsSection),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.money_recive,
                    title: context.l10n.pendingPayments,
                    route: AppRoutes.adminPendingPayments,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminPendingPayments,
                    badgeCount: _pendingPayments,
                  ),
                  _buildSectionTitle(context, context.l10n.community),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.shop_add,
                    title: context.l10n.suggestionsMenu,
                    route: AppRoutes.adminSuggestions,
                    isSelected:
                        widget.currentRoute == AppRoutes.adminSuggestions,
                    badgeCount: _pendingSuggestions,
                  ),
                  _buildSectionTitle(context, context.l10n.deployment),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.location,
                    title: context.l10n.wilayasAvailable,
                    route: AppRoutes.adminWilayas,
                    isSelected: widget.currentRoute == AppRoutes.adminWilayas,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Iconsax.category,
                    title: context.l10n.categoriesAvailable,
                    route: AppRoutes.adminCategoriesAvailability,
                    isSelected: widget.currentRoute == AppRoutes.adminCategoriesAvailability,
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
                  color: AppColors.grey300,
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
                  context.l10n.administration,
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
    VoidCallback? onTap,
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
                  color: AppColors.grey300,
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
      onTap: onTap ?? () {
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
