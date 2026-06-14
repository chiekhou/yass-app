import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../bloc/partner_dashboard_bloc.dart';
import '../bloc/partner_subscription_bloc.dart';
import '../widgets/partner_drawer.dart';
import '../widgets/partner_stat_card.dart';
import '../widgets/trial_banner_widget.dart';
import '../../../notifications/presentation/widgets/notification_bell_widget.dart';

class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<PartnerDashboardBloc>().add(PartnerDashboardLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(context.l10n.dashboard),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: const [NotificationBellWidget()],
      ),
      drawer: PartnerDrawer(currentRoute: AppRoutes.partnerDashboard),
      body: BlocBuilder<PartnerDashboardBloc, PartnerDashboardState>(
        builder: (context, state) {
          if (state is PartnerDashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is PartnerDashboardError) {
            return _buildErrorState(state.message);
          }

          if (state is PartnerDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<PartnerDashboardBloc>()
                    .add(PartnerDashboardRefresh());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subscription / trial banner
                    BlocBuilder<PartnerSubscriptionBloc,
                        PartnerSubscriptionState>(
                      builder: (context, subState) {
                        if (subState is SubscriptionLoaded) {
                          return TrialBannerWidget(status: subState.status);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(context),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildMainStats(context, state),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildEngagementStats(context, state),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
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
              onPressed: () => context
                  .read<PartnerDashboardBloc>()
                  .add(PartnerDashboardLoad()),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
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
                  'Bienvenue, Partenaire',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  'Gérez vos établissements',
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
              Iconsax.shop,
              color: AppColors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(BuildContext context, PartnerDashboardLoaded state) {
    final stats = state.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes établissements',
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
            PartnerStatCard(
              title: 'Total',
              value: stats.totalEstablishments.toString(),
              icon: Iconsax.building,
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.partnerEstablishments),
            ),
            PartnerStatCard(
              title: 'Actifs',
              value: stats.activeEstablishments.toString(),
              icon: Iconsax.tick_circle,
              color: AppColors.success,
            ),
            PartnerStatCard(
              title: context.l10n.statusPending,
              value: stats.pendingEstablishments.toString(),
              icon: Iconsax.clock,
              color: AppColors.warning,
            ),
            PartnerStatCard(
              title: 'Note moyenne',
              value: stats.averageRating.toStringAsFixed(1),
              icon: Iconsax.star,
              color: AppColors.primaryRed,
              subtitle: '${stats.totalReviews} avis',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngagementStats(
      BuildContext context, PartnerDashboardLoaded state) {
    final stats = state.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        PartnerStatCardCompact(
          title: 'Vues totales',
          value: _formatNumber(stats.totalViews),
          icon: Iconsax.eye,
          color: AppColors.info,
        ),
        const SizedBox(height: AppDimens.paddingS),
        PartnerStatCardCompact(
          title: 'Favoris',
          value: _formatNumber(stats.totalFavorites),
          icon: Iconsax.heart,
          color: AppColors.primaryRed,
        ),
        const SizedBox(height: AppDimens.paddingS),
        PartnerStatCardCompact(
          title: 'Appels téléphone',
          value: _formatNumber(stats.phoneClicks),
          icon: Iconsax.call,
          color: AppColors.success,
        ),
        const SizedBox(height: AppDimens.paddingS),
        PartnerStatCardCompact(
          title: 'Clics WhatsApp',
          value: _formatNumber(stats.whatsappClicks),
          icon: Iconsax.message,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(height: AppDimens.paddingS),
        PartnerStatCardCompact(
          title: 'Prises de contact',
          value: _formatNumber(stats.totalContacts),
          icon: Iconsax.message_edit,
          color: AppColors.warning,
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
                icon: Iconsax.add_circle,
                label: 'Ajouter',
                color: AppColors.primaryGreen,
                onTap: () => context.push(AppRoutes.partnerEstablishmentCreate),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.building,
                label: 'Mes établ.',
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.partnerEstablishments),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.receipt_item,
                label: 'Factures',
                color: AppColors.primaryGreen,
                onTap: () => context.push(AppRoutes.partnerInvoices),
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
