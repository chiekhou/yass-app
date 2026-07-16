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
                          _buildEngagementFunnel(context, state),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildRatingDistribution(context, state),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildRatingTrend(context, state),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildTopWilayas(context, state),
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
              context.l10n.loadingError,
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
                  context.l10n.welcomePartner,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  context.l10n.manageYourEstablishments,
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
          context.l10n.myEstablishments,
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
              title: context.l10n.totalLabel,
              value: stats.totalEstablishments.toString(),
              icon: Iconsax.building,
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.partnerEstablishments),
            ),
            PartnerStatCard(
              title: context.l10n.statusActive,
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
              title: context.l10n.averageRating,
              value: stats.averageRating.toStringAsFixed(1),
              icon: Iconsax.star,
              color: AppColors.primaryRed,
              subtitle: context.l10n.reviewsN(stats.totalReviews),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.quickActions,
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
                label: context.l10n.add,
                color: AppColors.primaryGreen,
                onTap: () => context.push(AppRoutes.partnerEstablishmentCreate),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.building,
                label: context.l10n.myEstablishmentsShort,
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.partnerEstablishments),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.receipt_item,
                label: context.l10n.invoicesLabel,
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

  // ── Funnel d'engagement ────────────────────────────────────────────────────
  Widget _buildEngagementFunnel(
      BuildContext context, PartnerDashboardLoaded state) {
    final s = state.stats;
    final steps = [
      _FunnelStep(context.l10n.views, s.totalViews, AppColors.info, Iconsax.eye),
      _FunnelStep(context.l10n.favorites, s.totalFavorites, AppColors.primaryRed, Iconsax.heart),
      _FunnelStep(context.l10n.calls, s.phoneClicks, AppColors.success, Iconsax.call),
      _FunnelStep('WhatsApp', s.whatsappClicks, AppColors.primaryGreen, Iconsax.message),
      _FunnelStep(context.l10n.contact, s.totalContacts, AppColors.warning, Iconsax.message_edit),
    ];
    final maxVal = steps.map((e) => e.value).fold(1, (a, b) => a > b ? a : b);

    return _buildSection(
      context,
      title: context.l10n.engagementFunnel,
      icon: Iconsax.chart_2,
      child: Column(
        children: steps.map((step) {
          final ratio = maxVal > 0 ? step.value / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(step.icon, size: 16, color: step.color),
                const SizedBox(width: 8),
                SizedBox(
                  width: 68,
                  child: Text(
                    step.label,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.grey700),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.toDouble(),
                      minHeight: 10,
                      backgroundColor: AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(step.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    _formatNumber(step.value),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: step.color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Distribution des notes ─────────────────────────────────────────────────
  Widget _buildRatingDistribution(
      BuildContext context, PartnerDashboardLoaded state) {
    final dist = state.stats.ratingDistribution;
    final total = dist.values.fold(0, (a, b) => a + b);

    if (total == 0) return const SizedBox.shrink();

    return _buildSection(
      context,
      title: context.l10n.ratingDistributionTitle,
      icon: Iconsax.star,
      child: Column(
        children: List.generate(5, (i) {
          final star = 5 - i;
          final count = dist[star] ?? 0;
          final ratio = total > 0 ? count / total : 0.0;
          const starColor = Color(0xFFFFC107);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '$star',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, size: 14, color: starColor),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.toDouble(),
                      minHeight: 10,
                      backgroundColor: AppColors.grey100,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(starColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Tendance de la note sur 6 mois ─────────────────────────────────────────
  Widget _buildRatingTrend(BuildContext context, PartnerDashboardLoaded state) {
    final trend = state.stats.ratingTrend;
    if (trend.isEmpty) return const SizedBox.shrink();

    const maxRating = 5.0;
    const chartHeight = 80.0;

    return _buildSection(
      context,
      title: context.l10n.ratingTrend6Months,
      icon: Iconsax.trend_up,
      child: SizedBox(
        height: chartHeight + 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: trend.map((t) {
            final barH = (t.average / maxRating) * chartHeight;
            final isHigh = t.average >= 4.0;
            final barColor =
                isHigh ? AppColors.primaryGreen : AppColors.warning;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      t.average > 0 ? t.average.toStringAsFixed(1) : '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: barH.clamp(4.0, chartHeight),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.month,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Top 5 wilayas des clients ──────────────────────────────────────────────
  Widget _buildTopWilayas(BuildContext context, PartnerDashboardLoaded state) {
    final wilayas = state.stats.topWilayas;
    if (wilayas.isEmpty) return const SizedBox.shrink();

    final maxCount =
        wilayas.map((w) => w.count).fold(1, (a, b) => a > b ? a : b);
    final colors = [
      AppColors.primaryGreen,
      AppColors.info,
      AppColors.warning,
      AppColors.primaryRed,
      AppColors.grey500,
    ];

    return _buildSection(
      context,
      title: context.l10n.topCustomerWilayas,
      icon: Iconsax.location,
      child: Column(
        children: wilayas.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          final ratio = w.count / maxCount;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    w.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${w.count}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helper section wrapper ─────────────────────────────────────────────────
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          child,
        ],
      ),
    );
  }
}

class _FunnelStep {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _FunnelStep(this.label, this.value, this.color, this.icon);
}
