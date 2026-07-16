import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_drawer.dart';
import '../../data/models/admin_stats_model.dart';

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
        title: Text(context.l10n.dashboard),
        backgroundColor: AppColors.scaffoldBackground,
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
              onPressed: () =>
                  context.read<AdminDashboardBloc>().add(AdminDashboardLoad()),
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
                  context.l10n.welcomeAdmin,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  context.l10n.managePlatformWin,
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
          context.l10n.generalStats,
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
              title: context.l10n.users,
              value: stats.totalUsers.toString(),
              icon: Iconsax.people,
              color: AppColors.info,
              subtitle: '${stats.activeUsers} actifs',
              onTap: () => context.push(AppRoutes.adminUsers),
            ),
            AdminStatCard(
              title: context.l10n.partners,
              value: stats.totalPartners.toString(),
              icon: Iconsax.briefcase,
              color: AppColors.primaryGreen,
              subtitle: '${stats.pendingPartners} en attente',
              onTap: () => context.push(AppRoutes.adminPartners),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildDemographicStats(context, state),
        const SizedBox(height: AppDimens.paddingM),
        _buildVisitStats(context, stats.visitStats),
      ],
    );
  }

  Widget _buildDemographicStats(
      BuildContext context, AdminDashboardLoaded state) {
    final d = state.stats.demographicStats;
    final total = d.total > 0 ? d.total : 1;

    final items = [
      _DemoItem(context.l10n.males, d.male, const Color(0xFF3B82F6), Icons.male),
      _DemoItem(context.l10n.females, d.female, const Color(0xFFEC4899), Icons.female),
      _DemoItem(context.l10n.youth, d.young, const Color(0xFFF59E0B), Icons.emoji_people),
      _DemoItem(context.l10n.children, d.child, const Color(0xFF10B981), Icons.child_care),
      if (d.unknown > 0)
        _DemoItem(context.l10n.notProvided, d.unknown, AppColors.grey400, Icons.help_outline),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: const Icon(Iconsax.profile_2user,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.userDemographics,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: Text(
                  'Total : ${d.total}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildAgeRanges(context, d),
          const SizedBox(height: AppDimens.paddingM),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                child: Row(
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: AppDimens.paddingS),
                    SizedBox(
                      width: 90,
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey700,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusRound),
                        child: LinearProgressIndicator(
                          value: item.count / total,
                          minHeight: 8,
                          backgroundColor: AppColors.grey100,
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.count}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey800,
                            ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAgeRanges(BuildContext context, DemographicStats d) {
    final totalWithAge =
        d.ageUnder18 + d.age18to25 + d.age26to35 + d.age36to50 + d.ageOver50;
    if (totalWithAge == 0) return const SizedBox.shrink();

    final ranges = [
      _AgeRange('< 18 ans', d.ageUnder18, const Color(0xFF8B5CF6)),
      _AgeRange('18 – 25 ans', d.age18to25, const Color(0xFF3B82F6)),
      _AgeRange('26 – 35 ans', d.age26to35, const Color(0xFF10B981)),
      _AgeRange('36 – 50 ans', d.age36to50, const Color(0xFFF59E0B)),
      _AgeRange('> 50 ans', d.ageOver50, const Color(0xFFEF4444)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cake_outlined, size: 16, color: AppColors.grey500),
            const SizedBox(width: AppDimens.paddingS),
            Text(
              context.l10n.ageRanges,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700,
                  ),
            ),
            if (d.ageUnknown > 0) ...[
              const Spacer(),
              Text(
                '${d.ageUnknown} non renseigné',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.grey400),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.paddingS),
        ...ranges.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.paddingXS),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      r.label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.grey600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusRound),
                      child: LinearProgressIndicator(
                        value: r.count / totalWithAge,
                        minHeight: 8,
                        backgroundColor: AppColors.grey100,
                        valueColor: AlwaysStoppedAnimation<Color>(r.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${r.count}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey800,
                          ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildVisitStats(BuildContext context, VisitStats visits) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: const Icon(Iconsax.chart_2,
                    color: AppColors.info, size: 20),
              ),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.appVisits,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: Text(
                  'Total : ${visits.total}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Row(
            children: [
              _buildVisitChip(context, context.l10n.today, visits.today),
              const SizedBox(width: AppDimens.paddingS),
              _buildVisitChip(context, context.l10n.thisWeek, visits.thisWeek),
              const SizedBox(width: AppDimens.paddingS),
              _buildVisitChip(context, context.l10n.thisMonth, visits.thisMonth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitChip(BuildContext context, String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection(
      BuildContext context, AdminDashboardLoaded state) {
    final stats = state.stats;
    final hasPending =
        stats.pendingPartners > 0 || stats.pendingEstablishments > 0;

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
              context.l10n.pendingApproval,
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
            title: context.l10n.pendingPartners,
            value: stats.pendingPartners.toString(),
            icon: Iconsax.briefcase,
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.adminPendingPartners),
          ),
        if (stats.pendingPartners > 0 && stats.pendingEstablishments > 0)
          const SizedBox(height: AppDimens.paddingS),
        if (stats.pendingEstablishments > 0)
          AdminStatCardCompact(
            title: context.l10n.pendingEstablishments,
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
                icon: Iconsax.people,
                label: context.l10n.users,
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.adminUsers),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.briefcase,
                label: context.l10n.partners,
                color: AppColors.primaryGreen,
                onTap: () => context.push(AppRoutes.adminPartners),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Iconsax.buildings,
                label: context.l10n.establishments,
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.adminEstablishments),
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

class _DemoItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _DemoItem(this.label, this.count, this.color, this.icon);
}

class _AgeRange {
  final String label;
  final int count;
  final Color color;

  const _AgeRange(this.label, this.count, this.color);
}
