import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/establishment_model.dart';
import '../bloc/establishment_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/data/repositories/reviews_repository.dart';

class EstablishmentDetailsPage extends StatefulWidget {
  final String? establishmentId;
  final String? slug;

  const EstablishmentDetailsPage({
    super.key,
    this.establishmentId,
    this.slug,
  });

  @override
  State<EstablishmentDetailsPage> createState() =>
      _EstablishmentDetailsPageState();
}

class _EstablishmentDetailsPageState extends State<EstablishmentDetailsPage> {
  late EstablishmentBloc _bloc;
  int _currentImageIndex = 0;

  // Map state
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDrivingMin;
  bool _routeLoaded = false;

  @override
  void initState() {
    super.initState();
    _bloc = EstablishmentBloc();
    _loadEstablishment();
  }

  Future<void> _loadRoute(Establishment establishment) async {
    if (!establishment.hasCoordinates) return;
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

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      final destLatLng =
          LatLng(establishment.latitude!, establishment.longitude!);

      // Affiche immédiatement le point utilisateur + ligne droite en fallback
      final straightDistanceM = const Distance().as(
        LengthUnit.Meter,
        userLatLng,
        destLatLng,
      );
      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _routePoints = [userLatLng, destLatLng];
          _routeDistanceKm = straightDistanceM / 1000;
          _routeDrivingMin =
              (straightDistanceM / 600).round(); // ~36 km/h ville
        });
        _fitMapBounds(userLatLng, destLatLng);
      }

      // Tente OSRM pour un vrai tracé routier
      try {
        final url = 'https://router.project-osrm.org/route/v1/driving/'
            '${pos.longitude},${pos.latitude};'
            '${establishment.longitude},${establishment.latitude}'
            '?overview=full&geometries=geojson';

        final response = await Dio().get(url,
            options: Options(receiveTimeout: const Duration(seconds: 8)));
        final route = response.data['routes'][0];
        final distanceM = (route['distance'] as num).toDouble();
        final durationS = (route['duration'] as num).toDouble();
        final coords = route['geometry']['coordinates'] as List;

        final points = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        if (mounted) {
          setState(() {
            _routePoints = points;
            _routeDistanceKm = distanceM / 1000;
            _routeDrivingMin = (durationS / 60).round();
          });
          _fitMapBounds(userLatLng, destLatLng);
        }
      } catch (_) {
        // OSRM indisponible — on garde la ligne droite
      }
    } catch (_) {
      // GPS indisponible
    }
  }

  void _fitMapBounds(LatLng user, LatLng dest) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([user, dest]),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  void _loadEstablishment() {
    if (widget.establishmentId != null) {
      _bloc.add(EstablishmentLoadById(id: widget.establishmentId!));
    } else if (widget.slug != null) {
      _bloc.add(EstablishmentLoadBySlug(slug: widget.slug!));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<EstablishmentBloc, EstablishmentState>(
        builder: (context, state) {
          if (state is EstablishmentLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            );
          }

          if (state is EstablishmentError) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.warning_2,
                      size: 64,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      context.l10n.loadingError,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    ElevatedButton(
                      onPressed: _loadEstablishment,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is EstablishmentLoaded) {
            return _buildContent(context, state);
          }

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EstablishmentLoaded state) {
    final establishment = state.establishment;

    if (!_routeLoaded && establishment.hasCoordinates) {
      _routeLoaded = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadRoute(establishment));
    }

    return BlocListener<EstablishmentBloc, EstablishmentState>(
      listenWhen: (previous, current) {
        if (previous is EstablishmentLoaded && current is EstablishmentLoaded) {
          return previous.isFavorited != current.isFavorited;
        }
        return false;
      },
      listener: (context, _) {
        // Sync la liste de favoris globale pour que la page Favoris reste à jour
        context.read<FavoriteBloc>().add(const FavoriteLoadList(refresh: true));
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(establishment, state.isFavorited),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(establishment),
                    const SizedBox(height: AppDimens.paddingL),
                    _buildActionButtons(establishment),
                    const SizedBox(height: AppDimens.paddingM),
                    _buildContactButton(establishment),
                    const SizedBox(height: AppDimens.paddingL),
                    if (establishment.description != null &&
                        establishment.description!.isNotEmpty) ...[
                      _buildDescription(establishment),
                      const SizedBox(height: AppDimens.paddingL),
                    ],
                    if (establishment.services != null &&
                        establishment.services!.isNotEmpty) ...[
                      _buildServices(establishment),
                      const SizedBox(height: AppDimens.paddingL),
                    ],
                    if (establishment.amenities != null &&
                        establishment.amenities!.isNotEmpty) ...[
                      _buildAmenities(establishment),
                      const SizedBox(height: AppDimens.paddingL),
                    ],
                    if (establishment.openingHours != null) ...[
                      _buildOpeningHours(establishment),
                      const SizedBox(height: AppDimens.paddingL),
                    ],
                    _buildContact(establishment),
                    const SizedBox(height: AppDimens.paddingL),
                    if (establishment.hasCoordinates)
                      _buildMapSection(establishment),
                    if (establishment.hasCoordinates)
                      const SizedBox(height: AppDimens.paddingL),
                    _isPremiumOrAbove(establishment)
                        ? _buildReviewsSection(state)
                        : _buildLockedReviewsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(establishment),
      ),
    );
  }

  Widget _buildSliverAppBar(Establishment establishment, bool isFavorited) {
    final isPremiumOrAbove = establishment.partnerSubscriptionPlan == 'premium' ||
        establishment.partnerSubscriptionPlan == 'gold';
    final images = establishment.images ?? [];
    final hasImages = images.isNotEmpty && isPremiumOrAbove;
    final coverImage = establishment.coverImage;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.arrow_left, color: AppColors.grey900),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.share, color: AppColors.grey900),
          ),
          onPressed: () => _shareEstablishment(establishment),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorited ? Iconsax.heart5 : Iconsax.heart,
              color: isFavorited ? AppColors.primaryRed : AppColors.grey900,
            ),
          ),
          onPressed: () {
            final authState = context.read<AuthBloc>().state;
            if (authState is! AuthAuthenticated) {
              _showLoginRequiredDialog(
                message: context.l10n.loginToFavoriteMsg,
              );
              return;
            }
            _bloc.add(EstablishmentToggleFavorite());
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (hasImages)
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  );
                },
              )
            else if (coverImage != null)
              Image.network(
                coverImage,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              )
            else
              _buildImagePlaceholder(),
            // Image indicator
            if (hasImages && images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? AppColors.white
                            : const Color(0x80FFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(Iconsax.image, size: 48, color: AppColors.grey400),
      ),
    );
  }

  Widget _buildHeader(Establishment establishment) {
    final isOpen = OpeningHoursHelper.isOpenNow(establishment.openingHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category & Status
        Row(
          children: [
            if (establishment.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingS,
                  vertical: AppDimens.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Text(
                  establishment.category!.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            const SizedBox(width: AppDimens.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: AppDimens.paddingXS,
              ),
              decoration: BoxDecoration(
                color: isOpen ? AppColors.successLight : AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Text(
                isOpen ? context.l10n.openNow : context.l10n.closedNow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isOpen ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Name
        Row(
          children: [
            Expanded(
              child: Text(
                establishment.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (establishment.isVerified)
              const Icon(Iconsax.verify5,
                  color: AppColors.primaryGreen, size: 24),
          ],
        ),
        const SizedBox(height: AppDimens.paddingS),

        // Address
        Row(
          children: [
            const Icon(Iconsax.location, size: 16, color: AppColors.white),
            const SizedBox(width: AppDimens.paddingXS),
            Expanded(
              child: Text(
                _buildFullAddress(establishment),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingS),

        // Rating & Price
        Row(
          children: [
            const Text('🇩🇿', style: TextStyle(fontSize: 14)),
            const SizedBox(width: AppDimens.paddingXS),
            Text(
              establishment.displayRating,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: AppDimens.paddingXS),
            Text(
              context.l10n.reviewsCount(establishment.totalReviews),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                  ),
            ),
            if (establishment.priceRange != null) ...[
              const SizedBox(width: AppDimens.paddingM),
              Text(
                establishment.priceRange!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _buildFullAddress(Establishment establishment) {
    final parts = <String>[];
    parts.add(establishment.address);
    if (establishment.commune != null) {
      parts.add(establishment.commune!.name);
    }
    if (establishment.wilaya != null) {
      parts.add(establishment.wilaya!.name);
    }
    return parts.join(', ');
  }

  Widget _buildActionButtons(Establishment establishment) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Iconsax.call,
            label: context.l10n.call,
            color: AppColors.white,
            onTap: _isPremiumOrAbove(establishment)
                ? () => _launchPhone(establishment.phone)
                : () => _showLockedDialog(context, 'Appel téléphonique'),
          ),
        ),
        const SizedBox(width: AppDimens.paddingM),
        if (establishment.hasWhatsApp) ...[
          Expanded(
            child: _ActionButton(
              icon: Iconsax.message,
              label: context.l10n.whatsapp,
              color: const Color.fromARGB(255, 104, 223, 68),
              onTap: _isPremiumOrAbove(establishment)
                  ? () => _launchWhatsApp(establishment.whatsapp!)
                  : () => _showLockedDialog(context, 'WhatsApp'),
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
        ],
        Expanded(
          child: _ActionButton(
            icon: Iconsax.routing,
            label: context.l10n.directions,
            color: AppColors.info,
            onTap: () => _showDirectionsOptions(establishment),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(Establishment establishment) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showContactForm(establishment),
        icon: const Icon(Iconsax.message_edit, color: AppColors.white),
        label: const Text(
          'Prise de contact',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
    );
  }

  void _showContactForm(Establishment establishment) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    bool isSubmitting = false;

    // Pre-fill authenticated user's email
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      emailCtrl.text = authState.user.email;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Prise de contact',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        establishment.name,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Votre nom',
                          prefixIcon: Icon(Iconsax.user),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Votre email',
                          prefixIcon: Icon(Iconsax.sms),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Champ requis';
                          }
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Votre message',
                          prefixIcon: Icon(Iconsax.message_text),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    await ApiClient.instance.post(
                                      ApiConfig.trackContact(establishment.id),
                                      data: {
                                        'name': nameCtrl.text.trim(),
                                        'email': emailCtrl.text.trim(),
                                        'message': messageCtrl.text.trim(),
                                      },
                                    );
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Votre demande a bien été envoyée !'),
                                          backgroundColor: AppColors.primaryGreen,
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    setSheetState(() => isSubmitting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Une erreur est survenue, réessayez.'),
                                          backgroundColor: AppColors.primaryRed,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Envoyer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDescription(Establishment establishment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.about, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimens.paddingS),
        Text(
          establishment.description!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildServices(Establishment establishment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.services,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimens.paddingS),
        Wrap(
          spacing: AppDimens.paddingS,
          runSpacing: AppDimens.paddingS,
          children: establishment.services!.map((service) {
            return Chip(
              label: Text(service),
              backgroundColor: AppColors.grey100,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenities(Establishment establishment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.amenities,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimens.paddingS),
        Wrap(
          spacing: AppDimens.paddingS,
          runSpacing: AppDimens.paddingS,
          children: establishment.amenities!.map((amenity) {
            return Chip(
              avatar: const Icon(Iconsax.tick_circle,
                  size: 16, color: AppColors.primaryGreen),
              label: Text(amenity),
              backgroundColor: AppColors.greenSurface,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOpeningHours(Establishment establishment) {
    final hours = establishment.openingHours!;
    final dayNames = {
      'monday': context.l10n.monday,
      'tuesday': context.l10n.tuesday,
      'wednesday': context.l10n.wednesday,
      'thursday': context.l10n.thursday,
      'friday': context.l10n.friday,
      'saturday': context.l10n.saturday,
      'sunday': context.l10n.sunday,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.openingHours,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimens.paddingS),
        Container(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: dayNames.entries.map((entry) {
              final dayHours = hours[entry.key];
              final isLast = entry.key == 'sunday';
              String hoursText = context.l10n.closed;

              if (dayHours != null && dayHours['is_closed'] != true) {
                final open = dayHours['open'];
                final close = dayHours['close'];
                if (open != null && close != null) {
                  hoursText = '$open - $close';
                }
              }

              return _buildDayRow(entry.value, hoursText, isLast: isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(String day, String hours, {bool isLast = false}) {
    final now = DateTime.now();
    final dayNames = [
      context.l10n.monday,
      context.l10n.tuesday,
      context.l10n.wednesday,
      context.l10n.thursday,
      context.l10n.friday,
      context.l10n.saturday,
      context.l10n.sunday,
    ];
    final isToday = dayNames[now.weekday - 1] == day;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.primaryGreen : null,
                    ),
              ),
              Text(
                hours,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hours == 'Fermé' ? AppColors.error : null,
                    ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  Widget _buildMapSection(Establishment establishment) {
    final destLatLng =
        LatLng(establishment.latitude!, establishment.longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimens.paddingS),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: destLatLng,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.win.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_routeDrivingMin != null && _routeDistanceKm != null)
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_routeDrivingMin min',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.directions_walk, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${(_routeDistanceKm! / 5 * 60).round()} min',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              if (_routeDrivingMin != null) const SizedBox(height: 6),
              Text(
                establishment.address,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_routeDistanceKm != null)
                Text(
                  '${_routeDistanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppColors.grey500),
                ),
              const SizedBox(height: AppDimens.paddingS),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDirectionsOptions(establishment),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Itinéraire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: establishment.address),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Adresse copiée')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text("Copier l'adresse"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContact(Establishment establishment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Text(context.l10n.contact,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimens.paddingS),
        _buildContactRow(
          Iconsax.call,
          establishment.formattedPhone ?? establishment.phone,
          onTap: () => _launchPhone(establishment.phone),
        ),*/
        if (establishment.hasEmail)
          _buildContactRow(
            Iconsax.sms,
            establishment.email!,
            onTap: () => _launchEmail(establishment.email!),
          ),
        if (establishment.hasWebsite)
          _isPremiumOrAbove(establishment)
              ? _buildContactRow(
                  Iconsax.global,
                  establishment.website!,
                  onTap: () => _launchUrl(establishment.website!),
                )
              : _buildLockedContactRow(
                  Iconsax.global,
                  'Site web',
                  onTap: () => _showLockedDialog(context, 'Site web'),
                ),
        if (establishment.facebook != null)
          _isPremiumOrAbove(establishment)
              ? _buildContactRow(
                  Icons.facebook,
                  'Facebook',
                  onTap: () => _launchUrl(establishment.facebook!),
                )
              : _buildLockedContactRow(
                  Icons.facebook,
                  'Facebook',
                  onTap: () => _showLockedDialog(context, 'Facebook'),
                ),
        if (establishment.instagram != null)
          _isPremiumOrAbove(establishment)
              ? _buildContactRow(
                  Iconsax.camera,
                  'Instagram',
                  onTap: () => _launchUrl(establishment.instagram!),
                )
              : _buildLockedContactRow(
                  Iconsax.camera,
                  'Instagram',
                  onTap: () => _showLockedDialog(context, 'Instagram'),
                ),
        if (establishment.tiktok != null)
          _isPremiumOrAbove(establishment)
              ? _buildContactRow(
                  Iconsax.video,
                  'TikTok',
                  onTap: () => _launchUrl(establishment.tiktok!),
                )
              : _buildLockedContactRow(
                  Iconsax.video,
                  'TikTok',
                  onTap: () => _showLockedDialog(context, 'TikTok'),
                ),
        if (establishment.snapchat != null)
          _isPremiumOrAbove(establishment)
              ? _buildContactRow(
                  Iconsax.ghost,
                  'Snapchat',
                  onTap: () => _launchUrl(establishment.snapchat!),
                )
              : _buildLockedContactRow(
                  Iconsax.ghost,
                  'Snapchat',
                  onTap: () => _showLockedDialog(context, 'Snapchat'),
                ),
      ],
    );
  }

  Widget _buildLockedContactRow(IconData icon, String label,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white24),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white24,
                    ),
              ),
            ),
            const Icon(Icons.lock_rounded, size: 14, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.white),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ),
            if (onTap != null)
              const Icon(Iconsax.arrow_right_3,
                  size: 16, color: AppColors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedReviewsSection() {
    return GestureDetector(
      onTap: () => _showLockedDialog(context, 'Les avis clients'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.paddingL),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Avis clients',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Non disponible pour cet établissement',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white24,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(EstablishmentLoaded state) {
    final reviews = state.reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${context.l10n.reviews} (${state.establishment.totalReviews})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (reviews.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.push(
                    '/establishment/${state.establishment.id}/reviews',
                    extra: {
                      'establishmentName': state.establishment.name,
                      'categoryName': state.establishment.category?.name,
                      'reviewsData': state.reviewsData,
                    },
                  );
                },
                child: Text(context.l10n.seeAll),
              ),
          ],
        ),
        //const SizedBox(height: AppDimens.paddingL),
        if (state.isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          )
        else if (reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  const Icon(Iconsax.message_text,
                      size: 48, color: AppColors.grey300),
                  const SizedBox(height: AppDimens.paddingS),
                  Text(
                    context.l10n.noReviews,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    context.l10n.beFirstReview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length > 3 ? 3 : reviews.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimens.paddingM),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewCard(review);
            },
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    final userName = review.user != null
        ? '${review.user!.firstName} ${review.user!.lastName}'
        : context.l10n.anonymous;
    final initials =
        review.user != null ? review.user!.firstName[0].toUpperCase() : 'U';
    final timeAgo = _formatTimeAgo(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête : avatar + nom + étoiles + date ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greenSurface,
                backgroundImage: review.user?.avatar != null
                    ? NetworkImage(review.user!.avatar!)
                    : null,
                child: review.user?.avatar == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          review.rating,
                          (i) => const Text('🇩🇿', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Titre ──
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              review.title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],

          // ── Commentaire ──
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.paddingXS),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey700,
                    height: 1.4,
                  ),
            ),
          ],

          // ── Date de visite ──
          if (review.visitDate != null) ...[
            const SizedBox(height: AppDimens.paddingS),
            Row(
              children: [
                const Icon(Iconsax.calendar_1, size: 13, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  'Visité le ${_formatDate(review.visitDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                ),
              ],
            ),
          ],

          // ── Points positifs ──
          if (review.hasPros) ...[
            const SizedBox(height: AppDimens.paddingS),
            ...review.pros!.map((pro) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pro,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey700,
                              ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // ── Points négatifs ──
          if (review.hasCons) ...[
            SizedBox(height: review.hasPros ? 2 : AppDimens.paddingS),
            ...review.cons!.map((con) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.remove_circle_outline_rounded,
                          size: 14, color: AppColors.primaryRed),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          con,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey700,
                              ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // ── Notes détaillées ──
          if (review.hasSubRatings) ...[
            const SizedBox(height: AppDimens.paddingM),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Notes détaillées',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            ...review.subRatings!.entries
                .where((e) => e.value != null)
                .map((e) {
              const labels = {
                'quality': 'Qualité',
                'welcome': 'Accueil',
                'information': 'Information',
                'value': 'Qualité/prix',
                'availability': 'Disponibilité',
                'reliability': 'Fiabilité',
                'comfort': 'Confort',
              };
              final label = labels[e.key] ?? e.key;
              final val = (e.value as num).toInt();
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: val / 5,
                          minHeight: 6,
                          backgroundColor: AppColors.grey200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            val >= 4
                                ? AppColors.primaryGreen
                                : val == 3
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$val/5',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // ── Photos ──
          if (review.hasImages) ...[
            const SizedBox(height: AppDimens.paddingS),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  child: Image.network(
                    review.images![i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.grey200,
                      child: const Icon(Iconsax.image, color: AppColors.grey400),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Réponse du partenaire ──
          if (review.hasPartnerReply) ...[
            const SizedBox(height: AppDimens.paddingS),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.message_text_1,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: AppDimens.paddingXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.ownerResponse,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.partnerReply!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Bouton signaler ──
          const SizedBox(height: AppDimens.paddingXS),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _showReportDialog(review.id),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.flag, size: 14, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      'Signaler',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey400,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String reviewId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.loginToReportReview),
          backgroundColor: AppColors.grey700,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: Text(context.l10n.reportReviewTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.l10n.reportReasonHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().length >= 10) {
                Navigator.pop(ctx);
                try {
                  await ReviewRepository()
                      .report(reviewId, controller.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.reportSent),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.reportError),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(context.l10n.report),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'il y a ${difference.inDays ~/ 365} an${difference.inDays ~/ 365 > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'il y a ${difference.inDays ~/ 30} mois';
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else {
      return 'à l\'instant';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]}. ${date.year}';
  }

  Widget _buildBottomBar(Establishment establishment) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: OutlinedButton.icon(
        onPressed: () async {
          if (!_isPremiumOrAbove(establishment)) {
            _showLockedDialog(context, 'Les avis clients');
            return;
          }
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final name = Uri.encodeComponent(establishment.name);
            final cat = Uri.encodeComponent(establishment.category?.name ?? '');
            final result = await context.push<bool>(
              '${AppRoutes.writeReview.replaceFirst(':establishmentId', establishment.id)}?name=$name&category=$cat',
            );
            if (result == true) {
              _bloc.add(const EstablishmentLoadReviews());
            }
          } else {
            _showLoginRequiredDialog(
              message: context.l10n.loginToReview,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
        icon: const Icon(Iconsax.edit, size: 18),
        label: Text(context.l10n.writeReview),
      ),
    );
  }

  void _showLoginRequiredDialog({
    String message = 'Vous devez être connecté pour effectuer cette action.',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: Row(
          children: [
            const Icon(Iconsax.lock, color: AppColors.primaryGreen),
            const SizedBox(width: AppDimens.paddingS),
            Text(context.l10n.loginRequired),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: Text(context.l10n.signIn),
          ),
        ],
      ),
    );
  }

  // ==================== LAUNCH METHODS ====================

  Future<void> _launchPhone(String phone) async {
    _bloc.add(EstablishmentTrackPhone());
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    _bloc.add(EstablishmentTrackWhatsApp());
    // Remove leading 0 and add Algeria country code
    final cleanPhone = phone.startsWith('0') ? phone.substring(1) : phone;
    final uri = Uri.parse('https://wa.me/213$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareEstablishment(Establishment establishment) {
    final address = _buildFullAddress(establishment);

    final buffer = StringBuffer();
    buffer.writeln('📍 ${establishment.name}');
    buffer.writeln(address);
    if (establishment.phone.isNotEmpty) {
      buffer.writeln('📞 ${establishment.formattedPhone}');
    }
    if (establishment.hasWebsite) {
      buffer.writeln('🌐 ${establishment.website}');
    }
    buffer.writeln();
    buffer.write('Découvert sur Win-وين 🔍');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  // ==================== LOCKED FEATURE DIALOG ====================

  bool _isPremiumOrAbove(Establishment e) =>
      e.partnerSubscriptionPlan == 'premium' ||
      e.partnerSubscriptionPlan == 'gold';

  void _showLockedDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.grey500, size: 20),
            const SizedBox(width: 8),
            const Text('Non disponible',
                style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          '$featureName n\'est pas disponible pour cet établissement pour le moment.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ==================== DIRECTIONS ====================

  void _showDirectionsOptions(Establishment establishment) {
    if (!establishment.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordonnées non disponibles pour cet établissement'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DirectionsBottomSheet(
        latitude: establishment.latitude!,
        longitude: establishment.longitude!,
        destinationName: establishment.name,
      ),
    );
  }
}

// ==================== ACTION BUTTON ====================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppDimens.paddingXS),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DIRECTIONS BOTTOM SHEET ====================

class _DirectionsBottomSheet extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String destinationName;

  const _DirectionsBottomSheet({
    required this.latitude,
    required this.longitude,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.paddingL,
        AppDimens.paddingL,
        AppDimens.paddingL,
        AppDimens.paddingL + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'Ouvrir avec',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Choisissez une application de navigation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          _buildNavigationOption(
            context,
            icon: Icons.map,
            title: 'Google Maps',
            subtitle: 'Navigation GPS',
            color: const Color(0xFF4285F4),
            onTap: () => _openGoogleMaps(context),
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildNavigationOption(
            context,
            icon: Icons.navigation,
            title: 'Waze',
            subtitle: 'Navigation sociale',
            color: const Color(0xFF33CCFF),
            onTap: () => _openWaze(context),
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildNavigationOption(
            context,
            icon: Icons.directions,
            title: 'Apple Plans',
            subtitle: 'Navigation Apple',
            color: const Color(0xFF000000),
            onTap: () => _openAppleMaps(context),
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildNavigationOption(
            context,
            icon: Iconsax.map,
            title: 'Autres applications',
            subtitle: 'Ouvrir avec le système',
            color: AppColors.primaryGreen,
            onTap: () => _openDefaultMaps(context),
          ),
          const SizedBox(height: AppDimens.paddingL),
        ],
      ),
      ),
    );
  }

  Widget _buildNavigationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3,
                size: 20, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    Navigator.pop(context);
    final encodedName = Uri.encodeComponent(destinationName);
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$encodedName&travelmode=driving';
    final uri = Uri.parse(url);

    // Try to open Google Maps app first
    final googleMapsUri = Uri.parse(
        'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze(BuildContext context) async {
    Navigator.pop(context);
    final url = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
    final uri = Uri.parse(url);

    // Try to open Waze app first
    final wazeUri = Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');
    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppleMaps(BuildContext context) async {
    Navigator.pop(context);
    final encodedName = Uri.encodeComponent(destinationName);
    final url =
        'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d&t=m&q=$encodedName';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDefaultMaps(BuildContext context) async {
    Navigator.pop(context);
    // Use geo: URI scheme which can be handled by any maps app
    final url =
        'geo:$latitude,$longitude?q=$latitude,$longitude($destinationName)';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps web
      final webUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      final webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
