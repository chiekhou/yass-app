import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../bloc/search_bloc.dart';
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

  bool _overlayVisible = false;
  LatLng? _userLocation;
  bool _loadingLocation = false;
  final List<String> _recentSearches = [];

  static const _popularKeywords = [
    'Restaurant',
    'Café',
    'Hôpital',
    'Pharmacie',
    'Banque',
    'Hôtel',
    'Coiffeur',
    'Supermarché',
    'École',
    'Dentiste',
    'Médecin',
    'Boulangerie',
  ];

  // Filter values
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  List<SubCategory> _subcategories = [];
  String? _selectedWilayaId;
  String? _selectedCommuneId;
  String? _selectedCommuneName;
  List<Commune> _communes = [];
  double? _selectedMinRating;
  String? _selectedPriceRange;
  String? _selectedSortBy;
  String? _selectedSortOrder;
  String? _selectedCategoryName;
  String? _selectedWilayaName;

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(SearchLoadInitialData());

    _selectedCategoryId = widget.categoryId;
    _selectedWilayaId = widget.wilayaId;

    // Récupérer la position en arrière-plan dès l'ouverture
    _loadUserLocationSilently();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
    } else if (widget.categoryId != null || widget.wilayaId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
    }

    _focusNode.addListener(() {
      setState(() {
        _overlayVisible = _focusNode.hasFocus;
        if (!_focusNode.hasFocus) {
          context.read<SearchBloc>().add(SearchClearSuggestions());
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Récupère le GPS silencieusement sans bloquer l'UI
  Future<void> _loadUserLocationSilently() async {
    // Override dev : position simulée Alger (définie dans .env.dev.json)
    final devLoc = AppConfig.devLocation;
    if (devLoc != null) {
      if (mounted)
        setState(() => _userLocation = LatLng(devLoc.lat, devLoc.lng));
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (_) {
      // GPS indisponible, la recherche reste globale
    }
  }

  /// Rafraîchit la position (appelé depuis "Emplacement actuel")
  Future<void> _refreshLocation() async {
    if (_loadingLocation) return;
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _loadingLocation = false;
        });
        _performSearch();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
  }

  /// Navigue directement vers la carte avec les paramètres de recherche
  void _performSearch({String? keyword}) {
    final query = keyword ?? _searchController.text.trim();
    if (keyword != null) _searchController.text = keyword;

    _addToRecentSearches(query);

    setState(() => _overlayVisible = false);
    _focusNode.unfocus();

    context.push(
      AppRoutes.map,
      extra: {
        'query': query.isEmpty ? null : query,
        'categoryId': _selectedCategoryId,
        'wilayaId': _selectedWilayaId,
        'communeId': _selectedCommuneId,
      },
    );
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      context.read<SearchBloc>().add(SearchSuggestions(query: query));
    } else {
      context.read<SearchBloc>().add(SearchClearSuggestions());
    }
    setState(() {}); // refresh overlay content
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchBloc>().add(SearchClearSuggestions());
    context.read<SearchBloc>().add(SearchClear());
    setState(() {});
  }

  Future<void> _loadCommunes(String wilayaId) async {
    try {
      final fromCache = context
          .read<SearchBloc>()
          .state
          .wilayas
          .cast<Wilaya?>()
          .firstWhere((w) => w?.id == wilayaId, orElse: () => null)
          ?.communes;
      if (fromCache != null && fromCache.isNotEmpty) {
        if (mounted) setState(() => _communes = fromCache);
        return;
      }
      final communes = await WilayaRepository().getCommunes(wilayaId);
      if (mounted) setState(() => _communes = communes);
    } catch (_) {}
  }

  Future<void> _loadSubcategories(String categoryId) async {
    try {
      final fromCache = context
          .read<SearchBloc>()
          .state
          .categories
          .cast<Category?>()
          .firstWhere((c) => c?.id == categoryId, orElse: () => null)
          ?.subcategories;
      if (fromCache != null && fromCache.isNotEmpty) {
        if (mounted) setState(() => _subcategories = fromCache);
        return;
      }
      final subs = await CategoryRepository().getSubcategories(categoryId);
      if (mounted) setState(() => _subcategories = subs);
    } catch (_) {}
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedSubcategoryId = null;
      _selectedSubcategoryName = null;
      _subcategories = [];
      _selectedWilayaId = null;
      _selectedWilayaName = null;
      _selectedCommuneId = null;
      _selectedCommuneName = null;
      _communes = [];
      _selectedMinRating = null;
      _selectedPriceRange = null;
      _selectedSortBy = null;
      _selectedSortOrder = null;
    });
    _performSearch();
  }

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _selectedSubcategoryId != null ||
      _selectedWilayaId != null ||
      _selectedCommuneId != null ||
      _selectedMinRating != null ||
      _selectedPriceRange != null ||
      _selectedSortBy != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(context.l10n.search),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              onPressed: _clearAllFilters,
              icon: const Icon(Iconsax.filter_remove),
              tooltip: context.l10n.clearFilters,
            ),
        ],
      ),
      body: BlocConsumer<SearchBloc, SearchState>(
        listener: (context, state) {
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
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingM,
                  AppDimens.paddingM,
                  AppDimens.paddingM,
                  AppDimens.paddingS,
                ),
                child: _buildSearchBar(),
              ),

              // Indicateur de localisation active
              if (_userLocation != null && !_overlayVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimens.paddingM, 0,
                      AppDimens.paddingM, AppDimens.paddingS),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location,
                          size: 13, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      const Text(
                        'Résultats près de vous',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Filters (hidden when overlay is open)
              if (!_overlayVisible) _buildFilters(state),
              if (!_overlayVisible) const SizedBox(height: AppDimens.paddingS),

              // Content: overlay OR results
              Expanded(
                child: _overlayVisible
                    ? _buildSearchOverlay(state)
                    : _buildContent(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
          hintText: 'Restaurants, hôpitaux, banques...',
          hintStyle: const TextStyle(color: AppColors.grey400),
          prefixIcon:
              const Icon(Iconsax.search_normal, color: AppColors.grey500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Iconsax.close_circle,
                      color: AppColors.grey400),
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

  // ── OVERLAY ────────────────────────────────────────────────────────────────

  Widget _buildSearchOverlay(SearchState state) {
    final query = _searchController.text;
    final hasSuggestions =
        state.suggestions.isNotEmpty || state.isLoadingSuggestions;

    if (query.length >= 2 && hasSuggestions) {
      return _buildLiveSuggestions(state);
    }
    if (query.length >= 2) {
      return _buildKeywordSuggestions(query);
    }
    return _buildPreSearchUI();
  }

  /// Champ vide + focus → location, récents, populaires
  Widget _buildPreSearchUI() {
    return Container(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Emplacement actuel
          ListTile(
            onTap: _refreshLocation,
            leading: _loadingLocation
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  )
                : _circleIcon(Icons.my_location, AppColors.primaryGreen,
                    AppColors.primaryGreen.withValues(alpha: 0.1)),
            title: Text(
              _userLocation != null
                  ? 'Position détectée — Actualiser'
                  : 'Utiliser ma position actuelle',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: _userLocation != null
                ? const Text(
                    'Les recherches incluent automatiquement votre position',
                    style: TextStyle(fontSize: 11, color: Color(0xFF002FA7)),
                  )
                : null,
            trailing: const Icon(Iconsax.arrow_right_3,
                size: 16, color: AppColors.grey400),
          ),

          const Divider(height: 1),

          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            _sectionHeader(
              'Recherches récentes',
              action: 'Effacer',
              onAction: () => setState(() => _recentSearches.clear()),
            ),
            ..._recentSearches.map(
              (s) => ListTile(
                dense: true,
                leading: const Icon(Iconsax.clock,
                    size: 18, color: AppColors.grey400),
                title: Text(s, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Iconsax.arrow_right_3,
                    size: 16, color: AppColors.grey400),
                onTap: () => _performSearch(keyword: s),
              ),
            ),
            const Divider(height: 1),
          ],

          // Popular keywords
          _sectionHeader('Recherches populaires'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularKeywords.map((kw) {
                return GestureDetector(
                  onTap: () => _performSearch(keyword: kw),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Text(
                      kw,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Typing mais pas encore de suggestions
  Widget _buildKeywordSuggestions(String query) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          if (_userLocation != null)
            ListTile(
              leading: _circleIcon(Icons.my_location, AppColors.primaryGreen,
                  AppColors.primaryGreen.withValues(alpha: 0.1)),
              title: Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'Rechercher "',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
                TextSpan(
                    text: query,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
                const TextSpan(
                    text: '" près de moi',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
              ])),
              trailing: const Icon(Iconsax.arrow_right_3,
                  size: 16, color: AppColors.grey400),
              onTap: () => _performSearch(),
            ),
          ListTile(
            leading: _circleIcon(
                Iconsax.search_normal, AppColors.grey500, AppColors.grey100),
            title: Text.rich(TextSpan(children: [
              const TextSpan(
                  text: 'Rechercher "',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
              TextSpan(
                  text: query,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
              const TextSpan(
                  text: '"',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
            ])),
            trailing: const Icon(Iconsax.arrow_right_3,
                size: 16, color: AppColors.grey400),
            onTap: () => _performSearch(),
          ),
        ],
      ),
    );
  }

  /// Suggestions live avec distances
  Widget _buildLiveSuggestions(SearchState state) {
    final query = _searchController.text;

    return Container(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Rechercher X (avec position si dispo)
          ListTile(
            leading: _userLocation != null
                ? _circleIcon(Icons.my_location, AppColors.primaryGreen,
                    AppColors.primaryGreen.withValues(alpha: 0.1))
                : _circleIcon(Iconsax.search_normal, AppColors.grey500,
                    AppColors.grey100),
            title: Text.rich(TextSpan(children: [
              const TextSpan(
                  text: 'Voir tous les résultats pour "',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
              TextSpan(
                  text: query,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
              const TextSpan(
                  text: '"',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF002FA7))),
              if (_userLocation != null)
                const TextSpan(
                  text: ' près de moi',
                  style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500),
                ),
            ])),
            trailing: const Icon(Iconsax.arrow_right_3,
                size: 16, color: AppColors.grey400),
            onTap: () => _performSearch(),
          ),

          const Divider(height: 1),

          if (state.isLoadingSuggestions)
            const Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          else
            ...state.suggestions.map(
              (e) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchSuggestionItem(
                    establishment: e,
                    userLocation: _userLocation,
                    onTap: () {
                      setState(() => _overlayVisible = false);
                      _focusNode.unfocus();
                      context.push('/e/${e.slug}');
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _circleIcon(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  Widget _sectionHeader(String title,
      {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
          if (action != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  // ── FILTERS ────────────────────────────────────────────────────────────────

  Widget _buildFilters(SearchState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Row(
        children: [
          _FilterChip(
            label: _selectedCategoryName ?? context.l10n.categoryFilter,
            isSelected: _selectedCategoryId != null,
            onTap: () => _showCategoryFilter(state),
          ),
          if (_selectedCategoryId != null && _subcategories.isNotEmpty) ...[
            const SizedBox(width: AppDimens.paddingS),
            _FilterChip(
              label: _selectedSubcategoryName ?? 'Sous-catégorie',
              isSelected: _selectedSubcategoryId != null,
              onTap: _showSubcategoryFilter,
            ),
          ],
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _selectedWilayaName ?? context.l10n.wilayaFilter,
            isSelected: _selectedWilayaId != null,
            onTap: () => _showWilayaFilter(state),
          ),
          if (_selectedWilayaId != null && _communes.isNotEmpty) ...[
            const SizedBox(width: AppDimens.paddingS),
            _FilterChip(
              label: _selectedCommuneName ?? 'Commune',
              isSelected: _selectedCommuneId != null,
              onTap: _showCommuneFilter,
            ),
          ],
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _selectedMinRating != null
                ? '${_selectedMinRating!.toStringAsFixed(1)}+'
                : context.l10n.rating,
            isSelected: _selectedMinRating != null,
            onTap: _showRatingFilter,
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: _selectedPriceRange ?? context.l10n.priceFilter,
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
        return context.l10n.sortBestRated;
      case 'name':
        return context.l10n.sortAlphabetical;
      case 'created_at':
        return context.l10n.recent;
      default:
        return context.l10n.sortBy;
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
        // Réinitialiser la sous-catégorie si la catégorie change
        _selectedSubcategoryId = null;
        _selectedSubcategoryName = null;
        _subcategories = [];
      });
      if (selected != null) _loadSubcategories(selected.id);
      _performSearch();
    }
  }

  Future<void> _showSubcategoryFilter() async {
    if (_subcategories.isEmpty) return;
    final selected = await SubcategoryFilterSheet.show(
      context,
      subcategories: _subcategories,
      selectedSubcategoryId: _selectedSubcategoryId,
    );
    if (selected != null || _selectedSubcategoryId != null) {
      setState(() {
        _selectedSubcategoryId = selected?.id;
        _selectedSubcategoryName = selected?.name;
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
        // Réinitialiser la commune si la wilaya change
        _selectedCommuneId = null;
        _selectedCommuneName = null;
        _communes = [];
      });
      if (selected != null) _loadCommunes(selected.id);
      _performSearch();
    }
  }

  Future<void> _showCommuneFilter() async {
    if (_communes.isEmpty) return;
    final selected = await CommuneFilterSheet.show(
      context,
      communes: _communes,
      selectedCommuneId: _selectedCommuneId,
    );
    if (selected != null || _selectedCommuneId != null) {
      setState(() {
        _selectedCommuneId = selected?.id;
        _selectedCommuneName = selected?.name;
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
      setState(() => _selectedMinRating = selected);
      _performSearch();
    }
  }

  Future<void> _showPriceFilter() async {
    final selected = await PriceFilterSheet.show(
      context,
      selectedPriceRange: _selectedPriceRange,
    );
    if (selected != null || _selectedPriceRange != null) {
      setState(() => _selectedPriceRange = selected);
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

  // ── ÉTAT VIDE ──────────────────────────────────────────────────────────────

  Widget _buildContent(SearchState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.map_1, size: 64, color: AppColors.white),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Recherchez un établissement',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Les résultats s\'affichent directement sur la carte',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── FILTER CHIP ────────────────────────────────────────────────────────────────

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
          border: Border.all(color: AppColors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isSelected ? AppColors.primaryGreen : AppColors.white,
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
