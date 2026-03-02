import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../bloc/home_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/categories_grid.dart';
import '../widgets/featured_section.dart';
import '../widgets/nearby_section.dart';
import '../../../notifications/presentation/widgets/notification_bell_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<HomeBloc>().state;
    if (state is HomeInitial || state is HomeError) {
      context.read<HomeBloc>().add(HomeLoadData());
    } else if (state is HomeLoaded && state.nearby.isEmpty) {
      _fetchByWilaya();
    }
  }

  void _fetchByWilaya() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final wilayaId = authState.user.wilayaId;
      if (wilayaId != null) {
        context.read<HomeBloc>().add(HomeLoadByWilaya(wilayaId: wilayaId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocListener<HomeBloc, HomeState>(
          // Déclenche le chargement par wilaya dès que les données principales sont chargées
          listenWhen: (prev, curr) => prev is! HomeLoaded && curr is HomeLoaded,
          listener: (context, state) => _fetchByWilaya(),
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                );
              }

              if (state is HomeError) {
                return _buildErrorState(state.message);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(HomeRefresh());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppColors.primaryGreen,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingM),
                        child: SearchBarWidget(
                            onTap: () => context.push(AppRoutes.search)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppDimens.paddingL),
                        child: _buildSectionHeader(context,
                            title: AppStrings.categories, onSeeAll: () {}),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: state is HomeLoaded
                          ? CategoriesGrid(categories: state.categories)
                          : const CategoriesGrid(),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppDimens.paddingL),
                        child: _buildSectionHeader(context,
                            title: AppStrings.featured,
                            onSeeAll: () => context
                                .push('${AppRoutes.search}?featured=true')),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: state is HomeLoaded
                          ? FeaturedSection(establishments: state.featured)
                          : const FeaturedSection(),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppDimens.paddingL),
                        child: _buildSectionHeader(context,
                            title: AppStrings.nearMe,
                            onSeeAll: () => context.push(AppRoutes.search)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: state is HomeLoaded
                          ? NearbySection(
                              establishments: state.nearby,
                              isLoading: state.isLoadingNearby,
                            )
                          : const NearbySection(),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppDimens.paddingXL)),
                  ],
                ),
              );
            },
          ),
        ),
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
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.white),
            const SizedBox(height: AppDimens.paddingM),
            Text('Erreur de chargement',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                    )),
            const SizedBox(height: AppDimens.paddingS),
            Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeBloc>().add(HomeLoadData()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryGreen,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child: Text('W',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white))),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Win',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: AppDimens.paddingXS),
                    Text('وِين',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(AppStrings.appTagline,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.white)),
              ],
            ),
          ),
          const NotificationBellWidget(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context,
      {required String title, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.white)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(AppStrings.seeAll),
                const SizedBox(width: AppDimens.paddingXS),
                const Icon(Iconsax.arrow_right_3, size: 16)
              ]),
            ),
        ],
      ),
    );
  }
}
