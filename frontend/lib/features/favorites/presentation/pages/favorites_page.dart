import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<FavoriteBloc>().add(const FavoriteLoadList(refresh: true));
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<FavoriteBloc>().state;
      if (state is FavoriteLoaded && state.hasMore && !state.isLoadingMore) {
        context
            .read<FavoriteBloc>()
            .add(FavoriteLoadList(page: state.currentPage + 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(AppStrings.favorites),
        actions: [
          BlocBuilder<FavoriteBloc, FavoriteState>(
            builder: (context, state) {
              if (state is FavoriteLoaded && state.favorites.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Iconsax.trash, size: 20),
                  tooltip: 'Tout supprimer',
                  onPressed: () => _confirmClearAll(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return _buildNotLoggedIn(context);
          }
          return _buildBody(context);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        if (state is FavoriteLoading || state is FavoriteInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FavoriteError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<FavoriteBloc>()
                        .add(const FavoriteLoadList(refresh: true)),
                    icon: const Icon(Iconsax.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is FavoriteLoaded) {
          if (state.favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<FavoriteBloc>()
                  .add(const FavoriteLoadList(refresh: true));
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimens.paddingM),
              itemCount: state.favorites.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimens.paddingM),
              itemBuilder: (context, index) {
                if (index == state.favorites.length) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildCard(context, state.favorites[index]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.heart,
                size: 48,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              'Aucun favori',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Explorez et ajoutez des établissements à vos favoris',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.search),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryGreen,
              ),
              icon: const Icon(Iconsax.search_normal_1),
              label: const Text('Explorer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Establishment e) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.establishment.replaceFirst(':id', e.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppDimens.radiusL),
              ),
              child: e.coverImage != null
                  ? Image.network(
                      e.coverImage!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingM,
                  AppDimens.paddingM,
                  AppDimens.paddingS,
                  AppDimens.paddingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.name,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (e.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Iconsax.verify5,
                                color: AppColors.primaryGreen, size: 15),
                          ),
                      ],
                    ),
                    if (e.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        e.category!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimens.paddingXS),
                    if (e.wilaya != null)
                      Row(
                        children: [
                          const Icon(Iconsax.location,
                              color: AppColors.grey500, size: 13),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              e.wilaya!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.grey600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppDimens.paddingXS),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.starFilled, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          e.displayRating,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: AppDimens.paddingXS),
                        Text(
                          '(${e.totalReviews})',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Remove from favorites
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.paddingXS),
              child: IconButton(
                icon: const Icon(Iconsax.heart5,
                    color: AppColors.primaryRed, size: 22),
                tooltip: 'Retirer des favoris',
                onPressed: () => context
                    .read<FavoriteBloc>()
                    .add(FavoriteRemove(establishmentId: e.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 110,
      height: 110,
      color: AppColors.grey200,
      child: const Icon(Iconsax.image, color: AppColors.grey400, size: 32),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.redSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.heart,
                size: 48,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              'Connectez-vous pour voir vos favoris',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Sauvegardez vos établissements préférés pour les retrouver facilement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryGreen,
              ),
              child: const Text(AppStrings.login),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider les favoris'),
        content: const Text(
            'Voulez-vous supprimer tous vos favoris ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FavoriteBloc>().add(FavoriteClearAll());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}
