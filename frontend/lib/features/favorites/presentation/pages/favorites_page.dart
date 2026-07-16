import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
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
        title: Text(context.l10n.favorites),
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
                    label: Text(context.l10n.retry),
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
              label: Text(context.l10n.explore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Establishment e) {
    final imageUrl = e.coverImage ?? e.logo;
    final lang = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.establishment.replaceFirst(':id', e.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Grande image + bouton supprimer ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimens.radiusM),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                ),
                // Bouton retirer (overlay top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => context
                        .read<FavoriteBloc>()
                        .add(FavoriteRemove(establishmentId: e.id)),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Iconsax.heart5,
                          color: AppColors.primaryRed, size: 17),
                    ),
                  ),
                ),
              ],
            ),

            // ── Infos ──
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + vérifié
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
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
                  // Catégorie
                  if (e.category != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      e.category!.localizedName(lang),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Étoiles + note + avis
                  Row(
                    children: [
                      _starRating(rating: e.averageRating),
                      const SizedBox(width: 6),
                      Text(
                        e.displayRating,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${e.totalReviews})',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A8A8A)),
                      ),
                    ],
                  ),
                  // Wilaya
                  if (e.wilaya != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.grey400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            e.wilaya!.name,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8A8A8A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(Iconsax.image, color: AppColors.grey400, size: 40),
      ),
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
              child: Text(context.l10n.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _starRating({required double rating}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating && (rating - i) >= 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 14,
          color: const Color(0xFFFF8C00),
        );
      }),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.clearFavorites),
        content: const Text(
            'Voulez-vous supprimer tous vos favoris ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FavoriteBloc>().add(FavoriteClearAll());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.clear),
          ),
        ],
      ),
    );
  }
}
