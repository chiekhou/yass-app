import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../home/data/models/category_model.dart';
import '../bloc/search_bloc.dart';
import '../widgets/establishment_list_card.dart';
import '../widgets/filter_bottom_sheets.dart';
import '../widgets/search_suggestion_item.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  final String? categoryId;
  final String? wilayaId;

  const SearchPage({
    super.key,
    this.initialQuery,
    this.categoryId,
    this.wilayaId,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  // Current filter values
  String? _selectedCategoryId;
  String? _selectedWilayaId;
  double? _selectedMinRating;
  String? _selectedPriceRange;
  String? _selectedSortBy;
  String? _selectedSortOrder;

  // Selected filter names for display
  String? _selectedCategoryName;
  String? _selectedWilayaName;

  @override
  void initState() {
    super.initState();

    // Load initial data (categories and wilayas)
    context.read<SearchBloc>().add(SearchLoadInitialData());

    // Set initial filters from parameters
    _selectedCategoryId = widget.categoryId;
    _selectedWilayaId = widget.wilayaId;

    // Set initial query and search if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    } else if (widget.categoryId != null || widget.wilayaId != null) {
      // Search with initial filters
      _performSearch();
    }

    // Listen for focus changes to show/hide suggestions
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus &&
            _searchController.text.isNotEmpty &&
            context.read<SearchBloc>().state.suggestions.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    context.read<SearchBloc>().add(SearchQuery(
          query: query,
          categoryId: _selectedCategoryId,
          wilayaId: _selectedWilayaId,
          minRating: _selectedMinRating,
          priceRange: _selectedPriceRange,
          sortBy: _selectedSortBy,
          sortOrder: _selectedSortOrder,
        ));

    // Hide suggestions and unfocus
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      context.read<SearchBloc>().add(SearchSuggestions(query: query));
      setState(() => _showSuggestions = true);
    } else {
      context.read<SearchBloc>().add(SearchClearSuggestions());
      setState(() => _showSuggestions = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchBloc>().add(SearchClearSuggestions());
    context.read<SearchBloc>().add(SearchClear());
    setState(() => _showSuggestions = false);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedWilayaId = null;
      _selectedWilayaName = null;
      _selectedMinRating = null;
      _selectedPriceRange = null;
      _selectedSortBy = null;
      _selectedSortOrder = null;
    });
    _performSearch();
  }

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _selectedWilayaId != null ||
      _selectedMinRating != null ||
      _selectedPriceRange != null ||
      _selectedSortBy != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(AppStrings.search),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              onPressed: _clearAllFilters,
              icon: const Icon(Iconsax.filter_remove),
              tooltip: 'Effacer les filtres',
            ),
        ],
      ),
      body: BlocConsumer<SearchBloc, SearchState>(
        listener: (context, state) {
          // Update filter names from loaded data
          if (state.categories.isNotEmpty && _selectedCategoryId != null) {
            final category = state.categories.firstWhere(
              (c) => c.id == _selectedCategoryId,
              orElse: () => const Category(id: '', name: '', slug: ''),
            );
            if (category.id.isNotEmpty) {
              _selectedCategoryName = category.name;
            }
          }
          if (state.wilayas.isNotEmpty && _selectedWilayaId != null) {
            final wilaya = state.wilayas.firstWhere(
              (w) => w.id == _selectedWilayaId,
              orElse: () => const Wilaya(id: '', code: '', name: ''),
            );
            if (wilaya.id.isNotEmpty) {
              _selectedWilayaName = wilaya.name;
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: _buildSearchBar(state),
                  ),

                  // Filters
                  _buildFilters(state),

                  const SizedBox(height: AppDimens.paddingS),

                  // Results
                  Expanded(
                    child: _buildContent(state),
                  ),
                ],
              ),

              // Suggestions overlay
              if (_showSuggestions && state.suggestions.isNotEmpty)
                Positioned(
                  top: 70,
                  left: AppDimens.paddingM,
                  right: AppDimens.paddingM,
                  child: _buildSuggestionsOverlay(state),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(SearchState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onSubmitted: (_) => _performSearch(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          hintStyle: const TextStyle(color: AppColors.grey400),
          prefixIcon: const Icon(Iconsax.search_normal, color: AppColors.grey500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Iconsax.close_circle, color: AppColors.grey400),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingM,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay(SearchState state) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isLoadingSuggestions)
              const Padding(
                padding: EdgeInsets.all(AppDimens.paddingM),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                  itemCount: state.suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return SearchSuggestionItem(
                      establishment: state.suggestions[index],
                      onTap: () {
                        setState(() => _showSuggestions = false);
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
            // Search button
            InkWell(
              onTap: _performSearch,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.grey200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.search_normal,
                        size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      'Rechercher "${_searchController.text}"',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(SearchState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Row(
        children: [
          _FilterChip(
            label: _selectedCategoryName ?? 'Catégorie',
            isSelected: _selectedCategoryId != null,
            onTap: () => _showCategoryFilter(state),
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _selectedWilayaName ?? 'Wilaya',
            isSelected: _selectedWilayaId != null,
            onTap: () => _showWilayaFilter(state),
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _selectedMinRating != null
                ? '${_selectedMinRating!.toStringAsFixed(1)}+'
                : 'Note',
            isSelected: _selectedMinRating != null,
            onTap: _showRatingFilter,
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _selectedPriceRange ?? 'Prix',
            isSelected: _selectedPriceRange != null,
            onTap: _showPriceFilter,
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _sortLabel,
            isSelected: _selectedSortBy != null,
            onTap: _showSortFilter,
            icon: Iconsax.sort,
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_selectedSortBy) {
      case 'average_rating':
        return 'Mieux noté';
      case 'name':
        return 'A → Z';
      case 'created_at':
        return 'Récent';
      default:
        return 'Trier';
    }
  }

  Future<void> _showCategoryFilter(SearchState state) async {
    if (state.categories.isEmpty) return;

    final selected = await CategoryFilterSheet.show(
      context,
      categories: state.categories,
      selectedCategoryId: _selectedCategoryId,
    );

    if (selected != null || _selectedCategoryId != null) {
      setState(() {
        _selectedCategoryId = selected?.id;
        _selectedCategoryName = selected?.name;
      });
      _performSearch();
    }
  }

  Future<void> _showWilayaFilter(SearchState state) async {
    if (state.wilayas.isEmpty) return;

    final selected = await WilayaFilterSheet.show(
      context,
      wilayas: state.wilayas,
      selectedWilayaId: _selectedWilayaId,
    );

    if (selected != null || _selectedWilayaId != null) {
      setState(() {
        _selectedWilayaId = selected?.id;
        _selectedWilayaName = selected?.name;
      });
      _performSearch();
    }
  }

  Future<void> _showRatingFilter() async {
    final selected = await RatingFilterSheet.show(
      context,
      selectedRating: _selectedMinRating,
    );

    if (selected != null || _selectedMinRating != null) {
      setState(() {
        _selectedMinRating = selected;
      });
      _performSearch();
    }
  }

  Future<void> _showPriceFilter() async {
    final selected = await PriceFilterSheet.show(
      context,
      selectedPriceRange: _selectedPriceRange,
    );

    if (selected != null || _selectedPriceRange != null) {
      setState(() {
        _selectedPriceRange = selected;
      });
      _performSearch();
    }
  }

  Future<void> _showSortFilter() async {
    final result = await SortFilterSheet.show(
      context,
      selectedSortBy: _selectedSortBy,
      selectedSortOrder: _selectedSortOrder,
    );

    if (result != null) {
      setState(() {
        _selectedSortBy = result.sortBy;
        _selectedSortOrder = result.sortOrder;
      });
      _performSearch();
    }
  }

  Widget _buildContent(SearchState state) {
    if (state is SearchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    if (state is SearchError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: AppColors.redLight),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppDimens.paddingS),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state is SearchLoaded) {
      if (state.results.isEmpty) {
        return _buildNoResults();
      }
      return _buildResults(state);
    }

    // Initial state
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.search_normal_1,
            size: 64,
            color: AppColors.white,
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'Recherchez un établissement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Restaurant, hôtel, pharmacie...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.search_status,
            size: 64,
            color: AppColors.white,
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'Aucun résultat trouvé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Essayez avec d\'autres termes ou filtres',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: AppDimens.paddingL),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Iconsax.filter_remove),
              label: const Text('Effacer les filtres'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(SearchLoaded state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            state.hasMore &&
            !state.isLoadingMore) {
          context.read<SearchBloc>().add(SearchLoadMore());
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        itemCount: state.results.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.results.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            );
          }

          return EstablishmentListCard(
            establishment: state.results[index],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color: AppColors.white,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppColors.primaryGreen : AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: AppDimens.paddingXS),
            Icon(
              icon ?? Iconsax.arrow_down_1,
              size: 14,
              color: isSelected ? AppColors.primaryGreen : AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
