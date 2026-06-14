import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../establishment/data/repositories/establishment_repository.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/repositories/category_repository.dart';

class MapPage extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final String? initialWilayaId;

  const MapPage({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialSubcategoryId,
    this.initialWilayaId,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // ── Mapbox ────────────────────────────────────────────────────────────────
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  final Map<String, int> _annotationIndexMap = {};
  final Map<String, Uint8List> _bitmapCache = {};

  // ── Data ──────────────────────────────────────────────────────────────────
  final EstablishmentRepository _repository = EstablishmentRepository();
  final LocationService _locationService = LocationService();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final WilayaRepository _wilayaRepository = WilayaRepository();

  List<Establishment> _establishments = [];
  LatLng? _userLocation;
  int _selectedIndex = -1;
  bool _loading = true;
  bool _mapMoved = false;
  bool _isReadyForMapEvents = false;
  bool _suppressMapEvents = false;
  bool _isSearching = false;
  bool _mapCreated = false;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late PageController _pageController;

  String? _currentQuery;
  List<Establishment> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounceTimer;
  Timer? _mapMoveTimer;
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
    'Boulangerie',
    'Médecin',
    'Dentiste',
  ];

  // ── Filtres ───────────────────────────────────────────────────────────────
  String? _categoryId;
  String? _subcategoryId;
  String? _wilayaId;
  String? _communeId;
  double? _minRating;
  String? _priceRange;
  bool _openNow = false;
  int? _maxDistanceKm;
  String _sortBy = 'average_rating';

  List<Category> _categories = [];
  List<Wilaya> _wilayas = [];

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _categoryId = widget.initialCategoryId;
    _subcategoryId = widget.initialSubcategoryId;
    _wilayaId = widget.initialWilayaId;
    _searchController.text = widget.initialQuery ?? '';
    _pageController = PageController(viewportFraction: 0.88);
    _init();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapMoveTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.wait([_loadLocation(), _loadFilterData()]);
    await _loadEstablishments();
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

  // ── Données établissements ────────────────────────────────────────────────

  Future<void> _loadEstablishments() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _mapMoved = false;
    });
    try {
      final hasQuery = (_currentQuery?.isNotEmpty ?? false) ||
          _categoryId != null ||
          _subcategoryId != null ||
          _wilayaId != null ||
          _minRating != null ||
          _priceRange != null;

      final effectiveRadius = _maxDistanceKm ??
          (hasQuery ? null : (_userLocation != null ? 50 : null));

      final result = await _repository.search(
        query: _currentQuery,
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
        wilayaId: _wilayaId,
        communeId: _communeId,
        minRating: _minRating,
        priceRange: _priceRange,
        latitude: _userLocation?.latitude,
        longitude: _userLocation?.longitude,
        radius: effectiveRadius,
        limit: 100,
        sortBy: _sortBy,
      );

      if (mounted) {
        var withCoords = result.items.where((e) => e.hasCoordinates).toList();
        if (_openNow) {
          withCoords = withCoords
              .where((e) => OpeningHoursHelper.isOpenNow(e.openingHours))
              .toList();
        }
        setState(() {
          _establishments = withCoords;
          _selectedIndex = withCoords.isNotEmpty ? 0 : -1;
          _loading = false;
        });

        if (_mapCreated) {
          _suppressMapEvents = true;
          await _updateMarkers();
          final target = withCoords.isNotEmpty ? withCoords.first : null;
          if (target != null) {
            await _mapboxMap?.flyTo(
              CameraOptions(
                center: Point(
                    coordinates: Position(target.longitude!, target.latitude!)),
                zoom: 13.0,
              ),
              MapAnimationOptions(duration: 0),
            );
          } else if (_userLocation != null) {
            await _mapboxMap?.flyTo(
              CameraOptions(
                center: Point(
                    coordinates: Position(
                        _userLocation!.longitude, _userLocation!.latitude)),
                zoom: 13.0,
              ),
              MapAnimationOptions(duration: 0),
            );
          }
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _suppressMapEvents = false);
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchInArea() async {
    if (!mounted || _mapboxMap == null) return;
    setState(() {
      _loading = true;
      _mapMoved = false;
      _selectedIndex = -1;
    });
    try {
      final cameraState = await _mapboxMap!.getCameraState();
      final coords = cameraState.center.coordinates;
      final lat = coords[1] as double;
      final lng = coords[0] as double;
      final radius = _zoomToRadiusKm(cameraState.zoom).clamp(1, 100).toInt();

      final result = await _repository.search(
        query: _currentQuery,
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
        wilayaId: _wilayaId,
        communeId: _communeId,
        minRating: _minRating,
        priceRange: _priceRange,
        latitude: lat,
        longitude: lng,
        radius: radius,
        limit: 100,
        sortBy: 'distance',
      );

      if (mounted) {
        var withCoords = result.items.where((e) => e.hasCoordinates).toList();
        if (_openNow) {
          withCoords = withCoords
              .where((e) => OpeningHoursHelper.isOpenNow(e.openingHours))
              .toList();
        }
        setState(() {
          _establishments = withCoords;
          _selectedIndex = withCoords.isNotEmpty ? 0 : -1;
          _loading = false;
        });
        await _updateMarkers();
        if (_pageController.hasClients && withCoords.isNotEmpty) {
          _pageController.jumpToPage(0);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _zoomToRadiusKm(double zoom) {
    return (40075 / pow(2, zoom + 1)).clamp(1.0, 100.0);
  }

  // ── Recherche inline ──────────────────────────────────────────────────────

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

    if (e.hasCoordinates) {
      _suppressMapEvents = true;
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(e.longitude!, e.latitude!)),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 400),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _suppressMapEvents = false);
      });
      final idx = _establishments.indexWhere((es) => es.id == e.id);
      if (idx != -1) {
        setState(() => _selectedIndex = idx);
        _updateMarkers();
        if (_pageController.hasClients) {
          _pageController.animateToPage(idx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
      } else {
        _loadEstablishments();
      }
    } else {
      _loadEstablishments();
    }
  }

  // ── Filtres ───────────────────────────────────────────────────────────────

  int get _activeFilterCount =>
      (_categoryId != null ? 1 : 0) +
      (_subcategoryId != null ? 1 : 0) +
      (_wilayaId != null ? 1 : 0) +
      (_communeId != null ? 1 : 0) +
      (_minRating != null ? 1 : 0) +
      (_priceRange != null ? 1 : 0) +
      (_openNow ? 1 : 0) +
      (_maxDistanceKm != null ? 1 : 0);

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
      selectedOpenNow: _openNow,
      selectedMaxDistanceKm: _maxDistanceKm,
      hasLocation: _userLocation != null,
    );
    if (result == null) return;
    setState(() {
      _categoryId = result.categoryId;
      _subcategoryId = result.subcategoryId;
      _wilayaId = result.wilayaId;
      _communeId = result.communeId;
      _minRating = result.minRating;
      _priceRange = result.priceRange;
      _openNow = result.openNow;
      _maxDistanceKm = result.maxDistanceKm;
    });
    _loadEstablishments();
  }

  // ── Mapbox callbacks ──────────────────────────────────────────────────────

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _mapCreated = true;

    // Affichage de la position utilisateur (puck bleu natif Mapbox)
    await _mapboxMap!.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));

    // Gestionnaire d'annotations (marqueurs)
    _annotationManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();
    _annotationManager!
        .addOnPointAnnotationClickListener(_AnnotationClickListener(
      onTap: (annotation) {
        final idx = _annotationIndexMap[annotation.id];
        if (idx != null) _onMarkerTap(idx);
      },
    ));

    // Marqueurs et caméra initiale si les établissements sont déjà chargés
    if (!_loading) {
      await _updateMarkers();
      if (_establishments.isNotEmpty) {
        final e = _establishments.first;
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(e.longitude!, e.latitude!)),
            zoom: 13.0,
          ),
          MapAnimationOptions(duration: 0),
        );
      } else if (_userLocation != null) {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
                coordinates: Position(
                    _userLocation!.longitude, _userLocation!.latitude)),
            zoom: 13.0,
          ),
          MapAnimationOptions(duration: 0),
        );
      }
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isReadyForMapEvents = true);
    });
  }

  void _onCameraIdle() {
    if (!_isReadyForMapEvents || _suppressMapEvents) return;
    _mapMoveTimer?.cancel();
    _mapMoveTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && !_mapMoved && !_loading) {
        setState(() => _mapMoved = true);
      }
    });
  }

  // ── Marqueurs ─────────────────────────────────────────────────────────────

  Future<void> _updateMarkers() async {
    if (_annotationManager == null) return;
    await _annotationManager!.deleteAll();
    _annotationIndexMap.clear();

    for (var i = 0; i < _establishments.length; i++) {
      final e = _establishments[i];
      final isSelected = i == _selectedIndex;
      final bitmap =
          await _getMarkerBitmap(_markerColor(e), _markerIcon(e), isSelected);

      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(e.longitude!, e.latitude!)),
          image: bitmap,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: 1.0,
        ),
      );
      _annotationIndexMap[annotation.id] = i;
    }
  }

  Future<Uint8List> _getMarkerBitmap(
      Color color, IconData icon, bool selected) async {
    final key = '${color.value}_${icon.codePoint}_$selected';
    if (_bitmapCache.containsKey(key)) return _bitmapCache[key]!;
    final bmp = await _buildMarkerBitmap(color, icon, selected);
    _bitmapCache[key] = bmp;
    return bmp;
  }

  Future<Uint8List> _buildMarkerBitmap(
      Color color, IconData icon, bool selected) async {
    const double w = 96;
    const double h = 110;
    const double r = 34.0;
    const double cx = w / 2;
    const double cy = r + 4;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    // Ombre portée
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx + 2, cy + 2), r, shadowPaint);

    // Cercle coloré
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

    // Bordure blanche
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4.0 : 2.5,
    );

    // Icône Material
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: selected ? 30 : 26,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // Pointe triangulaire
    final pointer = ui.Path()
      ..moveTo(cx - 9, cy + r - 2)
      ..lineTo(cx + 9, cy + r - 2)
      ..lineTo(cx, cy + r + 14)
      ..close();
    canvas.drawPath(pointer, Paint()..color = color);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  // ── Navigation marqueurs / cards ──────────────────────────────────────────

  Future<void> _onMarkerTap(int index) async {
    setState(() {
      _selectedIndex = index;
      _suppressMapEvents = true;
    });
    await _updateMarkers();

    final e = _establishments[index];
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(e.longitude!, e.latitude!)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 500),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _suppressMapEvents = false);
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _onPageChanged(int index) async {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _suppressMapEvents = true;
    });
    await _updateMarkers();

    final e = _establishments[index];
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(e.longitude!, e.latitude!)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 400),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _suppressMapEvents = false);
    });
  }

  // ── Couleur & icône par catégorie ─────────────────────────────────────────

  Color _markerColor(Establishment e) {
    final cat = e.category?.name.toLowerCase() ?? '';
    if (cat.contains('restaurant') ||
        cat.contains('pizza') ||
        cat.contains('burger') ||
        cat.contains('snack') ||
        cat.contains('fast') ||
        cat.contains('grill') ||
        cat.contains('boulangerie') ||
        cat.contains('pâtisserie') ||
        cat.contains('cuisine') ||
        cat.contains('traiteur')) {
      return const Color(0xFFFF8C00);
    }
    if (cat.contains('café') ||
        cat.contains('cafe') ||
        cat.contains('bar') ||
        cat.contains('brasserie') ||
        cat.contains('salon de thé') ||
        cat.contains('boisson') ||
        cat.contains('glace') ||
        cat.contains('jus')) {
      return const Color(0xFF3B82F6);
    }
    if (cat.contains('shopping') ||
        cat.contains('boutique') ||
        cat.contains('magasin') ||
        cat.contains('mode') ||
        cat.contains('vêtement') ||
        cat.contains('prêt') ||
        cat.contains('bijou') ||
        cat.contains('chaussure')) {
      return const Color(0xFF8B5CF6);
    }
    if (cat.contains('hôtel') ||
        cat.contains('hotel') ||
        cat.contains('hébergement') ||
        cat.contains('résidence') ||
        cat.contains('auberge')) {
      return const Color(0xFFEC4899);
    }
    if (cat.contains('santé') ||
        cat.contains('médecin') ||
        cat.contains('pharmacie') ||
        cat.contains('clinique') ||
        cat.contains('hôpital') ||
        cat.contains('hopital') ||
        cat.contains('dentiste') ||
        cat.contains('optique')) {
      return const Color(0xFFEF4444);
    }
    if (cat.contains('sport') ||
        cat.contains('fitness') ||
        cat.contains('salle') ||
        cat.contains('gym')) {
      return const Color(0xFF10B981);
    }
    return AppColors.primaryGreen;
  }

  IconData _markerIcon(Establishment e) {
    final cat = e.category?.name.toLowerCase() ?? '';
    if (cat.contains('restaurant') ||
        cat.contains('pizza') ||
        cat.contains('burger') ||
        cat.contains('snack') ||
        cat.contains('fast') ||
        cat.contains('grill') ||
        cat.contains('cuisine') ||
        cat.contains('traiteur')) {
      return Icons.restaurant;
    }
    if (cat.contains('boulangerie') || cat.contains('pâtisserie')) {
      return Icons.bakery_dining;
    }
    if (cat.contains('café') ||
        cat.contains('cafe') ||
        cat.contains('salon de thé') ||
        cat.contains('glace') ||
        cat.contains('jus')) {
      return Icons.local_cafe;
    }
    if (cat.contains('bar') ||
        cat.contains('brasserie') ||
        cat.contains('boisson')) {
      return Icons.local_bar;
    }
    if (cat.contains('shopping') ||
        cat.contains('boutique') ||
        cat.contains('magasin') ||
        cat.contains('mode') ||
        cat.contains('vêtement') ||
        cat.contains('prêt')) {
      return Icons.shopping_bag;
    }
    if (cat.contains('bijou')) return Icons.diamond;
    if (cat.contains('hôtel') ||
        cat.contains('hotel') ||
        cat.contains('hébergement') ||
        cat.contains('résidence') ||
        cat.contains('auberge')) {
      return Icons.hotel;
    }
    if (cat.contains('pharmacie')) return Icons.local_pharmacy;
    if (cat.contains('médecin') ||
        cat.contains('clinique') ||
        cat.contains('hôpital') ||
        cat.contains('hopital')) {
      return Icons.local_hospital;
    }
    if (cat.contains('dentiste')) return Icons.medical_services;
    if (cat.contains('optique')) return Icons.visibility;
    if (cat.contains('sport') ||
        cat.contains('fitness') ||
        cat.contains('gym')) {
      return Icons.fitness_center;
    }
    return Icons.storefront;
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

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
    final url = 'https://maps.google.com/?q=${loc!.latitude},${loc.longitude}';
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
                leading: const Icon(Icons.map, color: AppColors.primaryGreen),
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
                leading:
                    const Icon(Icons.navigation, color: AppColors.primaryGreen),
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
    const topBarHeight = 52.0;
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
          // ── Carte Mapbox ─────────────────────────────────────────────────
          MapWidget(
            key: const ValueKey('mapboxWidget'),
            styleUri: 'mapbox://styles/mapbox/streets-v12',
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(2.0, 28.0)),
              zoom: 5.0,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: (CameraChangedEventData _) =>
                _onCameraIdle(),
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
                                    decoration: const InputDecoration(
                                      hintText: 'Restaurant, hôtel...',
                                      hintStyle: TextStyle(
                                          color: AppColors.grey400,
                                          fontSize: 15),
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 4),
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
                ],
              ],
            ),
          ),

          // ── Chips de tri rapide ───────────────────────────────────────────
          if (!_isSearching)
            Positioned(
              top: topBarBottom + 8,
              left: AppDimens.paddingM,
              right: AppDimens.paddingM,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickChip(
                      icon: Icons.star_rounded,
                      label: 'Recommandés',
                      active: _sortBy == 'average_rating',
                      onTap: () {
                        setState(() => _sortBy = _sortBy == 'average_rating'
                            ? 'created_at'
                            : 'average_rating');
                        _loadEstablishments();
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      icon: Iconsax.clock,
                      label: 'Ouverts maintenant',
                      active: _openNow,
                      onTap: () {
                        setState(() => _openNow = !_openNow);
                        _loadEstablishments();
                      },
                    ),
                    if (_userLocation != null) ...[
                      const SizedBox(width: 8),
                      _QuickChip(
                        icon: Iconsax.location,
                        label: 'Près de moi',
                        active: _maxDistanceKm != null,
                        onTap: () {
                          setState(() => _maxDistanceKm =
                              _maxDistanceKm != null ? null : 10);
                          _loadEstablishments();
                        },
                      ),
                    ],
                  ],
                ),
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

          // ── Boutons flottants ─────────────────────────────────────────────
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
                  onPressed: () async {
                    if (_userLocation != null) {
                      _suppressMapEvents = true;
                      await _mapboxMap?.flyTo(
                        CameraOptions(
                          center: Point(
                              coordinates: Position(_userLocation!.longitude,
                                  _userLocation!.latitude)),
                          zoom: 14.0,
                        ),
                        MapAnimationOptions(duration: 500),
                      );
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) {
                          setState(() => _suppressMapEvents = false);
                        }
                      });
                    } else {
                      await _loadLocation();
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // ── Cartes établissements ─────────────────────────────────────────
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

          // ── Aucun résultat ────────────────────────────────────────────────
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
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
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
                      style: TextStyle(color: AppColors.grey600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // ── Overlay suggestions ───────────────────────────────────────────
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

  // ── Overlays de recherche ─────────────────────────────────────────────────

  Widget _buildSearchOverlay() {
    final query = _searchController.text;
    final hasSuggestions = _suggestions.isNotEmpty || _loadingSuggestions;
    if (query.length >= 2 && hasSuggestions) {
      return _buildLiveSuggestions(query);
    }
    if (query.length >= 2) return _buildKeywordSuggestions(query);
    return _buildPreSearchUI();
  }

  Widget _buildPreSearchUI() {
    return Container(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              leading: _overlayIcon(Icons.my_location, AppColors.primaryGreen,
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
            leading: _overlayIcon(
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

  Widget _buildLiveSuggestions(String query) {
    return Container(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: _userLocation != null
                ? _overlayIcon(Icons.my_location, AppColors.primaryGreen,
                    AppColors.primaryGreen.withValues(alpha: 0.1))
                : _overlayIcon(Iconsax.search_normal, AppColors.grey500,
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

// ── Listener clics annotations ────────────────────────────────────────────────

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onTap;
  _AnnotationClickListener({required this.onTap});

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    onTap(annotation);
    return true;
  }
}

// ── Quick filter chip ─────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: active ? AppColors.white : AppColors.grey700),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.white : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
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
      trailing:
          const Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.grey400),
    );
  }
}

// ── Carte établissement ───────────────────────────────────────────────────────

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
    final imageUrl = e.coverImage ?? e.logo ?? e.images?.firstOrNull?.url;

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
                                  size: 40, color: AppColors.primaryGreen),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (e.category != null)
                            Expanded(
                              child: Text(
                                e.category!.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (e.openingHours != null) ...[
                            const SizedBox(width: 4),
                            _OpenBadge(
                                isOpen: OpeningHoursHelper.isOpenNow(
                                    e.openingHours)),
                          ],
                        ],
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
                              itemBuilder: (_, __) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              e.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey600),
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
                                  fontSize: 12, color: AppColors.grey500),
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
                          icon: const Icon(Icons.navigation, size: 14),
                          label: const Text('Y aller',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side:
                                const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'Ouvert' : 'Fermé',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

// ── Résultat filtre ───────────────────────────────────────────────────────────

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
  final bool openNow;
  final int? maxDistanceKm;

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
    this.openNow = false,
    this.maxDistanceKm,
  });
}

// ── Sheet filtres ─────────────────────────────────────────────────────────────

class MapFiltersSheet extends StatefulWidget {
  final List<Category> categories;
  final List<Wilaya> wilayas;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final String? selectedWilayaId;
  final String? selectedCommuneId;
  final double? selectedMinRating;
  final String? selectedPriceRange;
  final bool selectedOpenNow;
  final int? selectedMaxDistanceKm;
  final bool hasLocation;

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
    this.selectedOpenNow = false,
    this.selectedMaxDistanceKm,
    this.hasLocation = false,
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
    bool selectedOpenNow = false,
    int? selectedMaxDistanceKm,
    bool hasLocation = false,
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
        selectedOpenNow: selectedOpenNow,
        selectedMaxDistanceKm: selectedMaxDistanceKm,
        hasLocation: hasLocation,
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
  bool _openNow = false;
  int? _maxDistanceKm;

  static const _distanceOptions = [5, 10, 25, 50];
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
    _openNow = widget.selectedOpenNow;
    _maxDistanceKm = widget.selectedMaxDistanceKm;

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
      if (mounted) {
        setState(() {
          _communes = communes;
          _loadingCommunes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCommunes = false);
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    final cat = widget.categories
        .cast<Category?>()
        .firstWhere((c) => c?.id == categoryId, orElse: () => null);
    if (cat?.subcategories != null && cat!.subcategories!.isNotEmpty) {
      if (mounted) setState(() => _subcategories = cat.subcategories!);
      return;
    }
    if (mounted) setState(() => _loadingSubcategories = true);
    try {
      final subs = await _categoryRepository.getSubcategories(categoryId);
      if (mounted) {
        setState(() {
          _subcategories = subs;
          _loadingSubcategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSubcategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('Filtres',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _categoryId = null;
                      _subcategoryId = null;
                      _wilayaId = null;
                      _communeId = null;
                      _minRating = null;
                      _priceRange = null;
                      _openNow = false;
                      _maxDistanceKm = null;
                    }),
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  _filterSection('Catégorie', _buildCategoryFilter()),
                  if (_subcategories.isNotEmpty)
                    _filterSection('Sous-catégorie', _buildSubcategoryFilter()),
                  _filterSection('Wilaya', _buildWilayaFilter()),
                  if (_communes.isNotEmpty)
                    _filterSection('Commune', _buildCommuneFilter()),
                  _filterSection('Note minimale', _buildRatingFilter()),
                  _filterSection('Gamme de prix', _buildPriceFilter()),
                  _filterSection('Disponibilité', _buildOpenNowFilter()),
                  if (widget.hasLocation)
                    _filterSection('Distance max.', _buildDistanceFilter()),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
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
                        openNow: _openNow,
                        maxDistanceKm: _maxDistanceKm,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Appliquer les filtres',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        content,
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.categories.map((cat) {
        final isSelected = _categoryId == cat.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _categoryId = null;
                _categoryName = null;
                _subcategoryId = null;
                _subcategories = [];
              } else {
                _categoryId = cat.id;
                _categoryName = cat.name;
                _subcategoryId = null;
                _loadSubcategories(cat.id);
              }
            });
          },
          child: _FilterChip(label: cat.name, isSelected: isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildSubcategoryFilter() {
    if (_loadingSubcategories) {
      return const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryGreen));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _subcategories.map((sub) {
        final isSelected = _subcategoryId == sub.id;
        return GestureDetector(
          onTap: () => setState(() {
            _subcategoryId = isSelected ? null : sub.id;
            _subcategoryName = isSelected ? null : sub.name;
          }),
          child: _FilterChip(label: sub.name, isSelected: isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildWilayaFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.wilayas.map((w) {
        final isSelected = _wilayaId == w.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _wilayaId = null;
                _wilayaName = null;
                _communeId = null;
                _communes = [];
              } else {
                _wilayaId = w.id;
                _wilayaName = w.name;
                _communeId = null;
                _loadCommunes(w.id);
              }
            });
          },
          child: _FilterChip(label: w.name, isSelected: isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildCommuneFilter() {
    if (_loadingCommunes) {
      return const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryGreen));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _communes.map((c) {
        final isSelected = _communeId == c.id;
        return GestureDetector(
          onTap: () => setState(() {
            _communeId = isSelected ? null : c.id;
            _communeName = isSelected ? null : c.name;
          }),
          child: _FilterChip(label: c.name, isSelected: isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ratings.map((r) {
        final isSelected = _minRating == r;
        return GestureDetector(
          onTap: () => setState(() => _minRating = isSelected ? null : r),
          child: _FilterChip(
              label: '${r.toStringAsFixed(1)}+ ★', isSelected: isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildPriceFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _prices.map((p) {
        final isSelected = _priceRange == p.$1;
        return GestureDetector(
          onTap: () => setState(() => _priceRange = isSelected ? null : p.$1),
          child:
              _FilterChip(label: '${p.$1} · ${p.$2}', isSelected: isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildOpenNowFilter() {
    return GestureDetector(
      onTap: () => setState(() => _openNow = !_openNow),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: _openNow ? AppColors.primaryGreen : AppColors.grey300,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
                  _openNow ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Ouverts maintenant', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _distanceOptions.map((d) {
        final isSelected = _maxDistanceKm == d;
        return GestureDetector(
          onTap: () => setState(() => _maxDistanceKm = isSelected ? null : d),
          child: _FilterChip(label: '$d km', isSelected: isSelected),
        );
      }).toList(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGreen : AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.grey200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.grey700,
        ),
      ),
    );
  }
}
