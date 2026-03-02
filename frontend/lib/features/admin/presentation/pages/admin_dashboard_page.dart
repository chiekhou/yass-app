import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardBloc>().add(AdminDashboardLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminDashboard),
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        builder: (context, state) {
          if (state is AdminDashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is AdminDashboardError) {
            return _buildErrorState(state.message);
          }

          if (state is AdminDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminDashboardBloc>().add(AdminDashboardRefresh());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(context),
                    const SizedBox(height: AppDimens.paddingL),
                    _buildMainStats(context, state),
                    const SizedBox(height: AppDimens.paddingL),
                    _buildPendingSection(context, state),
                    const SizedBox(height: AppDimens.paddingL),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<AdminDashboardBloc>().add(AdminDashboardLoad()),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, Admin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  'Gérez votre plateforme Win',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: const Icon(
              Iconsax.setting_2,
              color: AppColors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(BuildContext context, AdminDashboardLoaded state) {
    final stats = state.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques générales',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimens.paddingM,
          crossAxisSpacing: AppDimens.paddingM,
          childAspectRatio: 1.2,
          children: [
            AdminStatCard(
              title: 'Utilisateurs',
              value: stats.totalUsers.toString(),
              icon: Iconsax.people,
              color: AppColors.info,
              subtitle: '${stats.activeUsers} actifs',
              onTap: () => context.push(AppRoutes.adminUsers),
            ),
            AdminStatCard(
              title: 'Partenaires',
              value: stats.totalPartners.toString(),
              icon: Iconsax.briefcase,
              color: AppColors.primaryGreen,
              subtitle: '${stats.pendingPartners} en attente',
              onTap: () => context.push(AppRoutes.adminPartners),
            ),
            AdminStatCard(
              title: 'Établissements',
              value: stats.totalEstablishments.toString(),
              icon: Iconsax.building,
              color: AppColors.warning,
              subtitle: '${stats.pendingEstablishments} en attente',
              onTap: () => context.push(AppRoutes.adminPendingEstablishments),
            ),
            AdminStatCard(
              title: 'Avis',
              value: stats.totalReviews.toString(),
              icon: Iconsax.star,
              color: AppColors.primaryRed,
              subtitle: '${stats.pendingReviews} à modérer',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingSection(BuildContext context, AdminDashboardLoaded state) {
    final stats = state.stats;
    final hasPending = stats.pendingPartners > 0 || stats.pendingEstablishments > 0;

    if (!hasPending) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'En attente d\'approbation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: AppDimens.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.clock, size: 14, color: AppColors.warning),
                  const SizedBox(width: AppDimens.paddingXS),
                  Text(
                    '${stats.pendingPartners + stats.pendingEstablishments}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        if (stats.pendingPartners > 0)
          AdminStatCardCompact(
            title: 'Partenaires en attente',
            value: stats.pendingPartners.toString(),
            icon: Iconsax.briefcase,
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.adminPendingPartners),
          ),
        if (stats.pendingPartners > 0 && stats.pendingEstablishments > 0)
          const SizedBox(height: AppDimens.paddingS),
        if (stats.pendingEstablishments > 0)
          AdminStatCardCompact(
            title: 'Établissements en attente',
            value: stats.pendingEstablishments.toString(),
            icon: Iconsax.building,
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.adminPendingEstablishments),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.people,
                label: 'Utilisateurs',
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.adminUsers),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.briefcase,
                label: 'Partenaires',
                color: AppColors.primaryGreen,
                onTap: () => context.push(AppRoutes.adminPartners),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.clock,
                label: 'En attente',
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.adminPendingEstablishments),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.paddingM,
          horizontal: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Icon(icon, color: color, size: AppDimens.iconM),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
