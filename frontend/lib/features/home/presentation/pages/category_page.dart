import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../establishment/data/repositories/establishment_repository.dart';

class CategoryPage extends StatefulWidget {
  final String categoryId;
  final String? categoryName;

  const CategoryPage({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final EstablishmentRepository _repository = EstablishmentRepository();

  List<Establishment> _establishments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEstablishments();
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
      _loadMore();
    }
  }

  Future<void> _loadEstablishments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.getByCategory(
        widget.categoryId,
        page: 1,
        limit: 20,
      );

      setState(() {
        _establishments = response.items;
        _currentPage = 1;
        _hasMore = response.pagination.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _repository.getByCategory(
        widget.categoryId,
        page: _currentPage + 1,
        limit: 20,
      );

      setState(() {
        _establishments.addAll(response.items);
        _currentPage++;
        _hasMore = response.pagination.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Catégorie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_establishments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEstablishments,
      color: AppColors.white,
      backgroundColor: AppColors.primaryGreen,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimens.paddingM),
        itemCount: _establishments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _establishments.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            );
          }
          return _buildEstablishmentCard(_establishments[index]);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.white),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              _error ?? 'Une erreur est survenue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: _loadEstablishments,
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

  Widget _buildEmptyState() {
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
                Iconsax.shop,
                size: 48,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              'Aucun établissement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Il n\'y a pas encore d\'établissement dans cette catégorie',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
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

  Widget _buildEstablishmentCard(Establishment e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
      child: GestureDetector(
        onTap: () => context.push(
          AppRoutes.establishment.replaceFirst(':id', e.id),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppDimens.radiusM),
                ),
                child: e.logo != null || e.coverImage != null
                    ? Image.network(
                        e.logo ?? e.coverImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const Icon(
                              Iconsax.verify5,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingXS),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.location,
                            color: AppColors.grey500,
                            size: 14,
                          ),
                          const SizedBox(width: AppDimens.paddingXS),
                          Expanded(
                            child: Text(
                              e.wilaya?.name ?? e.address,
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
                      const SizedBox(height: AppDimens.paddingS),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.starFilled,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            e.displayRating,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: AppDimens.paddingXS),
                          Text(
                            '(${e.totalReviews} avis)',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.grey500),
                          ),
                          if (e.category != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenSurface,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusS,
                                ),
                              ),
                              child: Text(
                                e.category!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.grey200,
      child: const Icon(
        Iconsax.image,
        color: AppColors.grey400,
      ),
    );
  }
}
