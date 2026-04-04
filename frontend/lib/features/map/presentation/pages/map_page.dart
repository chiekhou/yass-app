import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../establishment/data/repositories/establishment_repository.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../../search/presentation/widgets/filter_bottom_sheets.dart';

class MapPage extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialWilayaId;

  const MapPage({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialWilayaId,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final EstablishmentRepository _repository = EstablishmentRepository();
  final LocationService _locationService = LocationService();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final WilayaRepository _wilayaRepository = WilayaRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late PageController _pageController;

  List<Establishment> _establishments = [];
  LatLng? _userLocation;
  int _selectedIndex = -1;
  bool _loading = true;
  bool _mapMoved = false;
  bool _isReadyForMapEvents = false;
  bool _suppressMapEvents = false;
  bool _isSearching = false;

  // Requête courante (peut être modifiée depuis la barre de recherche)
  String? _currentQuery;

  // Suggestions intelligentes
  List<Establishment> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounceTimer;
  final List<String> _recentSearches = [];

  static const _popularKeywords = [
    'Restaurant', 'Café', 'Hôpital', 'Pharmacie',
    'Banque', 'Hôtel', 'Coiffeur', 'Supermarché',
    'École', 'Boulangerie', 'Médecin', 'Dentiste',
  ];

  // Filtres actifs
  String? _categoryId;
  String? _subcategoryId;
  String? _wilayaId;
  String? _communeId;
  double? _minRating;
  String? _priceRange;

  // Données pour les bottom sheets
  List<Category> _categories = [];
  List<Wilaya> _wilayas = [];

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _categoryId = widget.initialCategoryId;
    _wilayaId = widget.initialWilayaId;
    _searchController.text = widget.initialQuery ?? '';
    _pageController = PageController(viewportFraction: 0.88);
    _init();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadLocation(),
      _loadFilterData(),
    ]);
    await _loadEstablishments();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isReadyForMapEvents = true);
    });
  }

  Future<void> _loadFilterData() async {
    try {
      final results = await Future.wait([
        _categoryRepository.getAll(),
        _wilayaRepository.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _wilayas = results[1] as List<Wilaya>;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    }
  }

  Future<void> _loadEstablishments() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _mapMoved = false;
    });
    try {
      final hasSearchQuery = (_currentQuery?.isNotEmpty ?? false) ||
          _categoryId != null ||
          _subcategoryId != null ||
          _wilayaId != null ||
          _minRating != null ||
          _priceRange != null;

      final result = await _repository.search(
        query: _currentQuery,
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
        wilayaId: _wilayaId,
        communeId: _communeId,
        minRating: _minRating,
        priceRange: _priceRange,
        latitude: hasSearchQuery ? null : _userLocation?.latitude,
        longitude: hasSearchQuery ? null : _userLocation?.longitude,
        radius: hasSearchQuery ? null : (_userLocation != null ? 25 : null),
        limit: 100,
        sortBy: hasSearchQuery
            ? 'created_at'
            : (_userLocation != null ? 'distance' : 'created_at'),
      );
      if (mounted) {
        final withCoords =
            result.items.where((e) => e.hasCoordinates).toList();
        setState(() {
          _establishments = withCoords;
          _selectedIndex = withCoords.isNotEmpty ? 0 : -1;
          _loading = false;
        });
        _suppressMapEvents = true;
        if (withCoords.isNotEmpty) {
          _mapController.move(
            LatLng(withCoords.first.latitude!, withCoords.first.longitude!),
            13,
          );
        } else if (_userLocation != null) {
          _mapController.move(_userLocation!, 13);
        }
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _suppressMapEvents = false);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchInArea() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _mapMoved = false;
      _selectedIndex = -1;
    });
    try {
      final center = _mapController.camera.center;
      final radius = _calculateRadiusKm().clamp(1, 100).toInt();
      final result = await _repository.search(
        query: _currentQuery,
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
        wilayaId: _wilayaId,
        communeId: _communeId,
        minRating: _minRating,
        priceRange: _priceRange,
        latitude: center.latitude,
        longitude: center.longitude,
        radius: radius,
        limit: 100,
        sortBy: 'distance',
      );
      if (mounted) {
        final withCoords =
            result.items.where((e) => e.hasCoordinates).toList();
        setState(() {
          _establishments = withCoords;
          _selectedIndex = withCoords.isNotEmpty ? 0 : -1;
          _loading = false;
        });
        if (_pageController.hasClients && withCoords.isNotEmpty) {
          _pageController.jumpToPage(0);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _calculateRadiusKm() {
    try {
      final bounds = _mapController.camera.visibleBounds;
      final center = _mapController.camera.center;
      const dist = Distance();
      final radiusM = dist(
        LatLng(center.latitude, center.longitude),
        LatLng(bounds.north, center.longitude),
      );
      return (radiusM / 1000).clamp(1.0, 100.0);
    } catch (_) {
      return 25.0;
    }
  }

  // ── Recherche inline intelligente ────────────────────────────────────────

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      return;
    }
    setState(() => _loadingSuggestions = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final result = await _repository.search(query: query, limit: 5);
        if (mounted) {
          setState(() {
            _suggestions = result.items;
            _loadingSuggestions = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
    });
  }

  void _performSearch({String? keyword}) {
    final query = keyword ?? _searchController.text.trim();
    if (keyword != null) _searchController.text = keyword;
    _addToRecentSearches(query);
    _debounceTimer?.cancel();
    setState(() {
      _currentQuery = query.isEmpty ? null : query;
      _isSearching = false;
      _suggestions = [];
    });
    _searchFocusNode.unfocus();
    _loadEstablishments();
  }

  void _activateSearch() {
    setState(() => _isSearching = true);
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _cancelSearch() {
    _debounceTimer?.cancel();
    _searchController.text = _currentQuery ?? '';
    setState(() {
      _isSearching = false;
      _suggestions = [];
      _loadingSuggestions = false;
    });
    _searchFocusNode.unfocus();
  }

  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
  }

  void _selectSuggestion(Establishment e) {
    _debounceTimer?.cancel();
    setState(() {
      _currentQuery = e.name;
      _isSearching = false;
      _suggestions = [];
    });
    _searchController.text = e.name;
    _searchFocusNode.unfocus();
    // Zoom directement sur cet établissement si coordonnées disponibles
    if (e.hasCoordinates) {
      _suppressMapEvents = true;
      _mapController.move(LatLng(e.latitude!, e.longitude!), 15);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _suppressMapEvents = false);
      });
      final idx = _establishments.indexWhere((es) => es.id == e.id);
      if (idx != -1) {
        setState(() => _selectedIndex = idx);
        if (_pageController.hasClients) {
          _pageController.animateToPage(idx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
      } else {
        // L'établissement n'est pas encore dans la liste : recharge
        _loadEstablishments();
      }
    } else {
      _loadEstablishments();
    }
  }

  // ── Filtres ──────────────────────────────────────────────────────────────

  int get _activeFilterCount =>
      (_categoryId != null ? 1 : 0) +
      (_subcategoryId != null ? 1 : 0) +
      (_wilayaId != null ? 1 : 0) +
      (_communeId != null ? 1 : 0) +
      (_minRating != null ? 1 : 0) +
      (_priceRange != null ? 1 : 0);

  bool get _hasActiveFilters => _activeFilterCount > 0;

  Future<void> _showFiltersSheet() async {
    final result = await MapFiltersSheet.show(
      context,
      categories: _categories,
      wilayas: _wilayas,
      selectedCategoryId: _categoryId,
      selectedSubcategoryId: _subcategoryId,
      selectedWilayaId: _wilayaId,
      selectedCommuneId: _communeId,
      selectedMinRating: _minRating,
      selectedPriceRange: _priceRange,
    );
    if (result == null) return;

    setState(() {
      _categoryId = result.categoryId;
      _subcategoryId = result.subcategoryId;
      _wilayaId = result.wilayaId;
      _communeId = result.communeId;
      _minRating = result.minRating;
      _priceRange = result.priceRange;
    });
    _loadEstablishments();
  }

  // ── Marqueurs & Navigation ────────────────────────────────────────────────

  void _onMarkerTap(int index) {
    setState(() {
      _selectedIndex = index;
      _suppressMapEvents = true;
    });
    final e = _establishments[index];
    _mapController.move(LatLng(e.latitude!, e.longitude!), 15);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _suppressMapEvents = false);
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _suppressMapEvents = true;
    });
    final e = _establishments[index];
    _mapController.move(LatLng(e.latitude!, e.longitude!), 15);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _suppressMapEvents = false);
    });
  }

  Future<void> _shareLocation() async {
    LatLng? loc = _userLocation;
    if (loc == null) {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Impossible de récupérer votre position')),
          );
        }
        return;
      }
      loc = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _userLocation = loc);
    }
    final url =
        'https://maps.google.com/?q=${loc.latitude},${loc.longitude}';
    await SharePlus.instance.share(ShareParams(text: 'Je suis ici : $url'));
  }

  void _openDirections(Establishment establishment) {
    final lat = establishment.latitude!;
    final lng = establishment.longitude!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ouvrir avec',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppDimens.paddingM),
              ListTile(
                leading:
                    const Icon(Icons.map, color: AppColors.primaryGreen),
                title: const Text('Google Maps'),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(
                    Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation,
                    color: AppColors.primaryGreen),
                title: const Text('Waze'),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(
                    Uri.parse('waze://?ll=$lat,$lng&navigate=yes'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasQuery = (_currentQuery?.isNotEmpty ?? false) ||
        _categoryId != null ||
        _wilayaId != null ||
        _minRating != null ||
        _priceRange != null;
    final hasEstablishments = _establishments.isNotEmpty && !_loading;
    const topBarHeight = 66.0;
    final topPadding = MediaQuery.of(context).padding.top;
    final topBarBottom = topPadding + 8 + topBarHeight;
    final searchAreaBottom = topBarBottom + 8;
    const cardHeight = 160.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final fabBottom = hasEstablishments
        ? (cardHeight + bottomPadding + 24)
        : (bottomPadding + AppDimens.paddingL);

    return Scaffold(
      body: Stack(
        children: [
          // ── Carte ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.0, 2.0),
              initialZoom: 5,
              onMapEvent: (event) {
                if (!_isReadyForMapEvents || _suppressMapEvents) return;
                if (event is MapEventMoveEnd ||
                    event is MapEventFlingAnimationEnd ||
                    event is MapEventScrollWheelZoom) {
                  if (!_mapMoved && !_loading) {
                    setState(() => _mapMoved = true);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.dz.win.app',
              ),
              MarkerLayer(
                markers: [
                  ..._establishments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    final isSelected = _selectedIndex == index;
                    return Marker(
                      point: LatLng(e.latitude!, e.longitude!),
                      width: 140,
                      height: 36,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                        .withValues(alpha: 0.35)
                                    : Colors.black26,
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.grey300,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            e.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.grey800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Barre du haut ────────────────────────────────────────────────
          Positioned(
            top: topPadding + 8,
            left: AppDimens.paddingM,
            right: AppDimens.paddingM,
            child: Row(
              children: [
                // Bouton retour
                Material(
                  color: AppColors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    onTap: () => context.pop(),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back,
                          size: 20, color: AppColors.grey800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Barre de recherche
                Expanded(
                  child: GestureDetector(
                    onTap: _isSearching ? null : _activateSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingM, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        border: Border.all(
                          color: _isSearching
                              ? AppColors.primaryGreen
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.search_normal,
                              color: AppColors.primaryGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isSearching
                                ? TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    textInputAction: TextInputAction.search,
                                    onChanged: _onSearchChanged,
                                    onSubmitted: (_) => _performSearch(),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      hintText: 'Restaurant, hôtel...',
                                      hintStyle: const TextStyle(
                                          color: AppColors.grey400,
                                          fontSize: 15),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      border: InputBorder.none,
                                    ),
                                  )
                                : Text(
                                    _currentQuery?.isNotEmpty == true
                                        ? _currentQuery!
                                        : hasQuery
                                            ? 'Résultats filtrés'
                                            : 'Rechercher sur la carte...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: _currentQuery?.isNotEmpty == true
                                          ? AppColors.grey800
                                          : AppColors.grey400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          if (_isSearching) ...[
                            // Bouton effacer saisie
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _debounceTimer?.cancel();
                                  setState(() {
                                    _suggestions = [];
                                    _loadingSuggestions = false;
                                  });
                                },
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.grey400),
                              ),
                          ] else if (!_loading) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${_establishments.length} lieu${_establishments.length > 1 ? 'x' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Bouton Annuler (visible uniquement en mode recherche)
                if (_isSearching) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelSearch,
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                if (!_isSearching) ...[
                const SizedBox(width: 8),
                // Bouton filtre avec badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: _hasActiveFilters
                          ? AppColors.primaryGreen
                          : AppColors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        onTap: _showFiltersSheet,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Iconsax.setting_4,
                            size: 20,
                            color: _hasActiveFilters
                                ? AppColors.white
                                : AppColors.grey800,
                          ),
                        ),
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                ], // fin if (!_isSearching)
              ],
            ),
          ),

          // ── "Rechercher dans cette zone" ─────────────────────────────────
          if (_mapMoved && !_loading)
            Positioned(
              top: searchAreaBottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _searchInArea,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingL, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusRound),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.search_normal,
                            size: 15, color: AppColors.primaryGreen),
                        SizedBox(width: 6),
                        Text(
                          'Rechercher dans cette zone',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Spinner ──────────────────────────────────────────────────────
          if (_loading)
            Positioned(
              top: searchAreaBottom,
              left: 0,
              right: 0,
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: AppColors.primaryGreen),
                ),
              ),
            ),

          // ── Boutons flottants ────────────────────────────────────────────
          Positioned(
            right: AppDimens.paddingM,
            bottom: fabBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'share_location',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryGreen,
                  elevation: 4,
                  onPressed: _shareLocation,
                  child: const Icon(Icons.share_location_rounded),
                ),
                const SizedBox(height: AppDimens.paddingS),
                FloatingActionButton.small(
                  heroTag: 'locate',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryGreen,
                  elevation: 4,
                  onPressed: () {
                    if (_userLocation != null) {
                      setState(() => _suppressMapEvents = true);
                      _mapController.move(_userLocation!, 14);
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) {
                          setState(() => _suppressMapEvents = false);
                        }
                      });
                    } else {
                      _loadLocation();
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // ── Cartes établissements (Airbnb style) ─────────────────────────
          if (hasEstablishments)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 16,
              child: SizedBox(
                height: cardHeight,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _establishments.length,
                  itemBuilder: (context, index) {
                    final e = _establishments[index];
                    return _EstablishmentMapCard(
                      establishment: e,
                      isSelected: _selectedIndex == index,
                      onNavigate: () => _openDirections(e),
                      onTap: () => context.push('/e/${e.slug}'),
                    );
                  },
                ),
              ),
            ),

          // ── Aucun résultat ───────────────────────────────────────────────
          if (!_loading && _establishments.isEmpty)
            Positioned(
              bottom: bottomPadding + 24,
              left: AppDimens.paddingM,
              right: AppDimens.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                    vertical: AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusM),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.search_status,
                        size: 20, color: AppColors.grey400),
                    SizedBox(width: 8),
                    Text(
                      'Aucun établissement trouvé dans cette zone',
                      style: TextStyle(
                          color: AppColors.grey600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // ── Overlay suggestions ──────────────────────────────────────────
          if (_isSearching)
            Positioned(
              top: topBarBottom + 8,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSearchOverlay(),
            ),
        ],
      ),
    );
  }

  // ── Overlay de recherche intelligente ─────────────────────────────────────

  Widget _buildSearchOverlay() {
    final query = _searchController.text;
    final hasSuggestions = _suggestions.isNotEmpty || _loadingSuggestions;

    if (query.length >= 2 && hasSuggestions) {
      return _buildLiveSuggestions(query);
    }
    if (query.length >= 2) {
      return _buildKeywordSuggestions(query);
    }
    return _buildPreSearchUI();
  }

  Widget _buildPreSearchUI() {
    return Container(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Récentes
          if (_recentSearches.isNotEmpty) ...[
            _overlaySection('Recherches récentes',
                action: 'Effacer',
                onAction: () => setState(() => _recentSearches.clear())),
            ..._recentSearches.map((s) => ListTile(
                  dense: true,
                  leading: const Icon(Iconsax.clock,
                      size: 18, color: AppColors.grey400),
                  title: Text(s, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Iconsax.arrow_right_3,
                      size: 16, color: AppColors.grey400),
                  onTap: () => _performSearch(keyword: s),
                )),
            const Divider(height: 1),
          ],
          // Populaires
          _overlaySection('Recherches populaires'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularKeywords.map((kw) {
                return GestureDetector(
                  onTap: () => _performSearch(keyword: kw),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Text(kw,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordSuggestions(String query) {
    return Container(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_userLocation != null)
            ListTile(
              leading: _overlayIcon(
                  Icons.my_location,
                  AppColors.primaryGreen,
                  AppColors.primaryGreen.withValues(alpha: 0.1)),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Rechercher "'),
                TextSpan(
                    text: query,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '" près de moi'),
              ])),
              trailing: const Icon(Iconsax.arrow_right_3,
                  size: 16, color: AppColors.grey400),
              onTap: () => _performSearch(),
            ),
          ListTile(
            leading: _overlayIcon(
                Iconsax.search_normal, AppColors.grey500, AppColors.grey100),
            title: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Rechercher "'),
              TextSpan(
                  text: query,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '"'),
            ])),
            trailing: const Icon(Iconsax.arrow_right_3,
                size: 16, color: AppColors.grey400),
            onTap: () => _performSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSuggestions(String query) {
    return Container(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // "Voir tous les résultats"
          ListTile(
            leading: _userLocation != null
                ? _overlayIcon(
                    Icons.my_location,
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withValues(alpha: 0.1))
                : _overlayIcon(Iconsax.search_normal, AppColors.grey500,
                    AppColors.grey100),
            title: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Voir tous les résultats pour "'),
              TextSpan(
                  text: query,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '"'),
              if (_userLocation != null)
                const TextSpan(
                    text: ' près de moi',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500)),
            ])),
            trailing: const Icon(Iconsax.arrow_right_3,
                size: 16, color: AppColors.grey400),
            onTap: () => _performSearch(),
          ),
          const Divider(height: 1),
          // Suggestions live
          if (_loadingSuggestions)
            const Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryGreen),
              ),
            )
          else
            ..._suggestions.map((e) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SuggestionItem(
                      establishment: e,
                      userLocation: _userLocation,
                      onTap: () => _selectSuggestion(e),
                    ),
                    const Divider(height: 1, indent: 72),
                  ],
                )),
        ],
      ),
    );
  }

  Widget _overlaySection(String title,
      {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600)),
          if (action != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.primaryGreen)),
            ),
        ],
      ),
    );
  }

  Widget _overlayIcon(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

// ── Suggestion item ───────────────────────────────────────────────────────────

class _SuggestionItem extends StatelessWidget {
  final Establishment establishment;
  final LatLng? userLocation;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.establishment,
    required this.onTap,
    this.userLocation,
  });

  String? _formatDistance() {
    if (userLocation == null || !establishment.hasCoordinates) return null;
    final dist = const Distance().as(
      LengthUnit.Kilometer,
      userLocation!,
      LatLng(establishment.latitude!, establishment.longitude!),
    );
    if (dist < 1) return '${(dist * 1000).round()} m';
    return '${dist.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final distance = _formatDistance();
    final e = establishment;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        clipBehavior: Clip.antiAlias,
        child: e.logo != null
            ? Image.network(e.logo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Iconsax.shop, color: AppColors.grey400))
            : const Icon(Iconsax.shop, color: AppColors.grey400),
      ),
      title: Text(
        e.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (e.category != null) ...[
            Text(e.category!.name,
                style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
            const SizedBox(width: 4),
            Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                    color: AppColors.grey400, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          if (distance != null) ...[
            Text(distance,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                    color: AppColors.grey400, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              e.wilaya?.name ?? e.address,
              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: const Icon(Iconsax.arrow_right_3,
          size: 16, color: AppColors.grey400),
    );
  }
}

// ── Résultat du filtre ────────────────────────────────────────────────────────

class MapFilterResult {
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? wilayaId;
  final String? wilayaName;
  final String? communeId;
  final String? communeName;
  final double? minRating;
  final String? priceRange;

  const MapFilterResult({
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.wilayaId,
    this.wilayaName,
    this.communeId,
    this.communeName,
    this.minRating,
    this.priceRange,
  });
}

// ── Drawer Filtres (style Airbnb) ─────────────────────────────────────────────

class MapFiltersSheet extends StatefulWidget {
  final List<Category> categories;
  final List<Wilaya> wilayas;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final String? selectedWilayaId;
  final String? selectedCommuneId;
  final double? selectedMinRating;
  final String? selectedPriceRange;

  const MapFiltersSheet({
    super.key,
    required this.categories,
    required this.wilayas,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    this.selectedWilayaId,
    this.selectedCommuneId,
    this.selectedMinRating,
    this.selectedPriceRange,
  });

  static Future<MapFilterResult?> show(
    BuildContext context, {
    required List<Category> categories,
    required List<Wilaya> wilayas,
    String? selectedCategoryId,
    String? selectedSubcategoryId,
    String? selectedWilayaId,
    String? selectedCommuneId,
    double? selectedMinRating,
    String? selectedPriceRange,
  }) {
    return showModalBottomSheet<MapFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapFiltersSheet(
        categories: categories,
        wilayas: wilayas,
        selectedCategoryId: selectedCategoryId,
        selectedSubcategoryId: selectedSubcategoryId,
        selectedWilayaId: selectedWilayaId,
        selectedCommuneId: selectedCommuneId,
        selectedMinRating: selectedMinRating,
        selectedPriceRange: selectedPriceRange,
      ),
    );
  }

  @override
  State<MapFiltersSheet> createState() => _MapFiltersSheetState();
}

class _MapFiltersSheetState extends State<MapFiltersSheet> {
  String? _categoryId;
  String? _categoryName;
  String? _subcategoryId;
  String? _subcategoryName;
  List<SubCategory> _subcategories = [];
  bool _loadingSubcategories = false;
  String? _wilayaId;
  String? _wilayaName;
  String? _communeId;
  String? _communeName;
  List<Commune> _communes = [];
  bool _loadingCommunes = false;
  double? _minRating;
  String? _priceRange;

  final CategoryRepository _categoryRepository = CategoryRepository();
  final WilayaRepository _wilayaRepository = WilayaRepository();

  static const _ratings = [4.5, 4.0, 3.5, 3.0, 2.0];
  static const _prices = [
    ('\$', 'Économique'),
    ('\$\$', 'Modéré'),
    ('\$\$\$', 'Élevé'),
    ('\$\$\$\$', 'Luxe'),
  ];

  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _subcategoryId = widget.selectedSubcategoryId;
    _wilayaId = widget.selectedWilayaId;
    _minRating = widget.selectedMinRating;
    _priceRange = widget.selectedPriceRange;

    if (_categoryId != null) {
      _categoryName = widget.categories
          .cast<Category?>()
          .firstWhere((c) => c?.id == _categoryId, orElse: () => null)
          ?.name;
      _loadSubcategories(_categoryId!);
    }
    if (_wilayaId != null) {
      _wilayaName = widget.wilayas
          .cast<Wilaya?>()
          .firstWhere((w) => w?.id == _wilayaId, orElse: () => null)
          ?.name;
      _loadCommunes(_wilayaId!);
    }
    _communeId = widget.selectedCommuneId;
  }

  Future<void> _loadCommunes(String wilayaId) async {
    final fromCache = widget.wilayas
        .cast<Wilaya?>()
        .firstWhere((w) => w?.id == wilayaId, orElse: () => null)
        ?.communes;
    if (fromCache != null && fromCache.isNotEmpty) {
      if (mounted) setState(() => _communes = fromCache);
      return;
    }
    if (mounted) setState(() => _loadingCommunes = true);
    try {
      final communes = await _wilayaRepository.getCommunes(wilayaId);
      if (mounted) setState(() { _communes = communes; _loadingCommunes = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCommunes = false);
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    // D'abord essayer depuis le modèle déjà chargé
    final cat = widget.categories.cast<Category?>()
        .firstWhere((c) => c?.id == categoryId, orElse: () => null);
    if (cat?.subcategories != null && cat!.subcategories!.isNotEmpty) {
      if (mounted) setState(() => _subcategories = cat.subcategories!);
      return;
    }
    if (mounted) setState(() => _loadingSubcategories = true);
    try {
      final subs = await _categoryRepository.getSubcategories(categoryId);
      if (mounted) setState(() { _subcategories = subs; _loadingSubcategories = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSubcategories = false);
    }
  }

  int get _activeCount =>
      (_categoryId != null ? 1 : 0) +
      (_subcategoryId != null ? 1 : 0) +
      (_wilayaId != null ? 1 : 0) +
      (_communeId != null ? 1 : 0) +
      (_minRating != null ? 1 : 0) +
      (_priceRange != null ? 1 : 0);

  void _clearAll() {
    setState(() {
      _categoryId = null;
      _categoryName = null;
      _subcategoryId = null;
      _subcategoryName = null;
      _subcategories = [];
      _wilayaId = null;
      _wilayaName = null;
      _communeId = null;
      _communeName = null;
      _communes = [];
      _minRating = null;
      _priceRange = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      MapFilterResult(
        categoryId: _categoryId,
        categoryName: _categoryName,
        subcategoryId: _subcategoryId,
        subcategoryName: _subcategoryName,
        wilayaId: _wilayaId,
        wilayaName: _wilayaName,
        communeId: _communeId,
        communeName: _communeName,
        minRating: _minRating,
        priceRange: _priceRange,
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await CategoryFilterSheet.show(
      context,
      categories: widget.categories,
      selectedCategoryId: _categoryId,
    );
    if (selected == null && _categoryId != null) {
      setState(() {
        _categoryId = null;
        _categoryName = null;
        _subcategoryId = null;
        _subcategoryName = null;
        _subcategories = [];
      });
    } else if (selected != null && selected.id != _categoryId) {
      setState(() {
        _categoryId = selected.id;
        _categoryName = selected.name;
        _subcategoryId = null;
        _subcategoryName = null;
        _subcategories = [];
      });
      _loadSubcategories(selected.id);
    }
  }

  Future<void> _pickSubcategory() async {
    if (_subcategories.isEmpty) return;
    final selected = await SubcategoryFilterSheet.show(
      context,
      subcategories: _subcategories,
      selectedSubcategoryId: _subcategoryId,
    );
    if (selected == null && _subcategoryId != null) {
      setState(() { _subcategoryId = null; _subcategoryName = null; });
    } else if (selected != null) {
      setState(() { _subcategoryId = selected.id; _subcategoryName = selected.name; });
    }
  }

  Future<void> _pickWilaya() async {
    final selected = await WilayaFilterSheet.show(
      context,
      wilayas: widget.wilayas,
      selectedWilayaId: _wilayaId,
    );
    if (selected == null && _wilayaId != null) {
      setState(() {
        _wilayaId = null; _wilayaName = null;
        _communeId = null; _communeName = null; _communes = [];
      });
    } else if (selected != null && selected.id != _wilayaId) {
      setState(() {
        _wilayaId = selected.id; _wilayaName = selected.name;
        _communeId = null; _communeName = null; _communes = [];
      });
      _loadCommunes(selected.id);
    }
  }

  Future<void> _pickCommune() async {
    if (_communes.isEmpty) return;
    final selected = await CommuneFilterSheet.show(
      context,
      communes: _communes,
      selectedCommuneId: _communeId,
    );
    if (selected == null && _communeId != null) {
      setState(() { _communeId = null; _communeName = null; });
    } else if (selected != null) {
      setState(() { _communeId = selected.id; _communeName = selected.name; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_activeCount > 0)
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text(
                      'Effacer tout',
                      style: TextStyle(
                        color: AppColors.grey800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM, vertical: AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Catégorie ────────────────────────────────────────────
                  _SectionTitle(label: 'Catégorie'),
                  const SizedBox(height: 8),
                  _PickerRow(
                    icon: Iconsax.category,
                    label: _categoryName ?? 'Toutes les catégories',
                    isSelected: _categoryId != null,
                    onTap: _pickCategory,
                  ),

                  // ── Sous-catégorie (conditionnelle) ──────────────────────
                  if (_categoryId != null) ...[
                    const SizedBox(height: 10),
                    _loadingSubcategories
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen),
                            ),
                          )
                        : _subcategories.isEmpty
                            ? const SizedBox.shrink()
                            : _PickerRow(
                                icon: Iconsax.category_2,
                                label: _subcategoryName ?? 'Toutes les sous-catégories',
                                isSelected: _subcategoryId != null,
                                onTap: _pickSubcategory,
                              ),
                  ],

                  const _Divider(),

                  // ── Wilaya ───────────────────────────────────────────────
                  _SectionTitle(label: 'Wilaya'),
                  const SizedBox(height: 8),
                  _PickerRow(
                    icon: Iconsax.location,
                    label: _wilayaName ?? 'Toutes les wilayas',
                    isSelected: _wilayaId != null,
                    onTap: _pickWilaya,
                  ),

                  // ── Commune (conditionnelle) ──────────────────────────────
                  if (_wilayaId != null) ...[
                    const SizedBox(height: 10),
                    _loadingCommunes
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen),
                            ),
                          )
                        : _communes.isEmpty
                            ? const SizedBox.shrink()
                            : _PickerRow(
                                icon: Iconsax.building_3,
                                label: _communeName ?? 'Toutes les communes',
                                isSelected: _communeId != null,
                                onTap: _pickCommune,
                              ),
                  ],

                  const _Divider(),

                  // ── Note minimum ─────────────────────────────────────────
                  _SectionTitle(label: 'Note minimum'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ratings.map((rating) {
                      final isSelected = _minRating == rating;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _minRating = isSelected ? null : rating),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.grey300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.starFilled,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$rating+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const _Divider(),

                  // ── Gamme de prix ────────────────────────────────────────
                  _SectionTitle(label: 'Gamme de prix'),
                  const SizedBox(height: 12),
                  Row(
                    children: _prices.map((p) {
                      final isSelected = _priceRange == p.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() =>
                              _priceRange = isSelected ? null : p.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(
                                right: p.$1 != '\$\$\$\$' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : AppColors.grey300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  p.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.grey800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.$2,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? AppColors.white.withValues(alpha: 0.85)
                                        : AppColors.grey500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: AppDimens.paddingM),
                ],
              ),
            ),
          ),

          // ── Bouton appliquer ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                AppDimens.paddingM, 12, AppDimens.paddingM, bottomPadding + 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _activeCount > 0
                      ? 'Afficher les résultats · $_activeCount filtre${_activeCount > 1 ? 's' : ''}'
                      : 'Afficher les résultats',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.grey800,
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.06)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primaryGreen : AppColors.grey500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primaryGreen : AppColors.grey700,
                ),
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: isSelected ? AppColors.primaryGreen : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
      child: Divider(height: 1, color: AppColors.grey200),
    );
  }
}

// ── Establishment Map Card ────────────────────────────────────────────────────

class _EstablishmentMapCard extends StatelessWidget {
  final Establishment establishment;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const _EstablishmentMapCard({
    required this.establishment,
    required this.isSelected,
    required this.onTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final e = establishment;
    final imageUrl = e.coverImage ?? e.logo ?? e.images?.firstOrNull;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(left: 8, right: 8, top: isSelected ? 0 : 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isSelected
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 110,
                  height: 160,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.greenSurface,
                            child: const Center(
                              child: Icon(Iconsax.building_3,
                                  size: 40,
                                  color: AppColors.primaryGreen),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.greenSurface,
                          child: const Center(
                            child: Icon(Iconsax.building_3,
                                size: 40, color: AppColors.primaryGreen),
                          ),
                        ),
                ),
              ),
              // Infos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (e.category != null)
                        Text(
                          e.category!.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (e.averageRating > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: e.averageRating,
                              itemBuilder: (_, __) => const Icon(
                                  Icons.star,
                                  color: Colors.amber),
                              itemCount: 5,
                              itemSize: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              e.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey600),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Iconsax.location,
                              size: 12, color: AppColors.grey500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              e.address,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: onNavigate,
                          icon:
                              const Icon(Icons.navigation, size: 14),
                          label: const Text('Y aller',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(
                                color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                        ),
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
}
