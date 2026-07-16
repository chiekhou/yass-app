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
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/establishment_model.dart';
import '../../data/repositories/establishment_repository.dart';
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

class _EstablishmentDetailsPageState extends State<EstablishmentDetailsPage>
    with SingleTickerProviderStateMixin {
  late EstablishmentBloc _bloc;
  late TabController _tabController;
  int _currentImageIndex = 0;
  bool _eliteOnly = false;
  int? _ratingFilter;
  String _sortBy = 'created_at';
  String _sortOrder = 'DESC';
  bool _descriptionExpanded = false;

  // Map state
  double? _routeDistanceKm;
  int? _routeDrivingMin;
  bool _routeLoaded = false;

  // Similaires — future stockée pour éviter les re-souscriptions sur chaque rebuild
  Future<List<Establishment>>? _similarsFuture;
  String? _similarsEstablishmentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

      // Distance à vol d'oiseau en fallback immédiat
      final straightDistanceM = const Distance().as(
        LengthUnit.Meter,
        userLatLng,
        destLatLng,
      );
      if (mounted) {
        setState(() {
          _routeDistanceKm = straightDistanceM / 1000;
          _routeDrivingMin = (straightDistanceM / 600).round();
        });
      }

      // Tente OSRM pour distance/durée réelles
      try {
        final url = 'https://router.project-osrm.org/route/v1/driving/'
            '${pos.longitude},${pos.latitude};'
            '${establishment.longitude},${establishment.latitude}'
            '?overview=false';

        final response = await Dio().get(url,
            options: Options(receiveTimeout: const Duration(seconds: 8)));
        final route = response.data['routes'][0];
        final distanceM = (route['distance'] as num).toDouble();
        final durationS = (route['duration'] as num).toDouble();

        if (mounted) {
          setState(() {
            _routeDistanceKm = distanceM / 1000;
            _routeDrivingMin = (durationS / 60).round();
          });
        }
      } catch (_) {
        // OSRM indisponible — on garde la distance à vol d'oiseau
      }
    } catch (_) {
      // GPS indisponible
    }
  }

  String _mapboxStaticUrl(double lat, double lng,
      {int width = 600, int height = 220}) {
    const token =
        String.fromEnvironment('MAPBOX_PUBLIC_TOKEN', defaultValue: '');
    final marker = 'pin-l+FF4444($lng,$lat)';
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/'
        '$marker/$lng,$lat,15,0/${width}x${height}@2x?access_token=$token';
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
    _tabController.dispose();
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
                child: CircularProgressIndicator(color: AppColors.white),
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
              child: CircularProgressIndicator(color: AppColors.white),
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
        context.read<FavoriteBloc>().add(const FavoriteLoadList(refresh: true));
      },
      child: Scaffold(
        backgroundColor:
            const Color.from(alpha: 1, red: 0, green: 0.184, blue: 0.655),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(establishment, state.isFavorited, state.reviews),
            SliverToBoxAdapter(
              child: _buildHeaderContent(establishment, state.isFavorited),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.accentGreen,
                  unselectedLabelColor: AppColors.scaffoldBackground,
                  indicatorColor: AppColors.accentGreen,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: context.l10n.tabOverview),
                    Tab(text: context.l10n.tabInfos),
                    Tab(text: context.l10n.reviews),
                    Tab(text: context.l10n.tabSimilar),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildApercuTab(establishment, state),
              _buildInfosTab(establishment),
              _buildAvisTab(establishment, state),
              _buildSimilairesTab(establishment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
      Establishment establishment, bool isFavorited, List<Review> reviews) {
    final isPremiumOrAbove =
        establishment.partnerSubscriptionPlan == 'premium' ||
            establishment.partnerSubscriptionPlan == 'gold';
    final imageUrls = (establishment.images ?? []).map((p) => p.url).toList();
    final images = imageUrls; // List<String> d'URLs pour le carousel
    final hasImages = images.isNotEmpty && isPremiumOrAbove;
    final coverImage = establishment.coverImage;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.kleinBlue,
      title: Text(
        establishment.name,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.arrow_left, color: AppColors.white),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.share, color: AppColors.white),
          ),
          onPressed: () => _shareEstablishment(establishment),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorited ? Iconsax.heart5 : Iconsax.heart,
              color: isFavorited ? AppColors.accentOrange : AppColors.white,
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _currentImageIndex = index);
                  });
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
            // Gradient overlay at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 130,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ),
            // Name + rating + photo button
            Builder(builder: (context) {
              final allPhotoItems = [
                if (coverImage != null)
                  PhotoItem(url: coverImage, category: 'autres'),
                ...(establishment.images ?? []),
                // Photos des avis utilisateurs (avec leurs catégories)
                for (final review in reviews)
                  if (review.images != null) ...review.images!,
                // Vidéos des avis utilisateurs
                for (final review in reviews)
                  if (review.videos != null) ...review.videos!,
              ];
              return Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Establishment name
                    Text(
                      establishment.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating + review count
                    if (establishment.totalReviews > 0)
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < establishment.averageRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${establishment.displayRating} ${context.l10n.reviewsCount(establishment.totalReviews)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // "Voir toutes les photos" button
                    if (allPhotoItems.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          context.push(
                            '/establishment/${establishment.id}/photos',
                            extra: {
                              'name': establishment.name,
                              'photos': allPhotoItems,
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white38, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.gallery,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.seeAllPhotos(allPhotoItems.length),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            // Page indicator dots (multi-image carousel)
            if (hasImages && images.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
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
    final lang = Localizations.localeOf(context).languageCode;

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
                  establishment.category!.localizedName(lang),
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

  Widget _buildInfoCard(Establishment establishment) {
    final fullAddress = _buildFullAddress(establishment);
    final hasPhone = establishment.phone.isNotEmpty;
    final hasEmail = establishment.hasEmail;

    if (!hasPhone && !hasEmail) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Iconsax.location,
            value: fullAddress,
            onTap: () {
              Clipboard.setData(ClipboardData(text: fullAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.addressCopied)),
              );
            },
            trailingIcon: Icons.copy_rounded,
            isFirst: true,
            isLast: !hasPhone && !hasEmail,
          ),
          if (hasPhone) ...[
            const Divider(height: 1, color: Colors.white12),
            _buildInfoRow(
              icon: Iconsax.call,
              value: establishment.formattedPhone ?? establishment.phone,
              onTap: () => _launchPhone(establishment.phone),
              trailingIcon: Iconsax.arrow_right_3,
              isFirst: false,
              isLast: !hasEmail,
            ),
          ],
          if (hasEmail) ...[
            const Divider(height: 1, color: Colors.white12),
            _buildInfoRow(
              icon: Iconsax.sms,
              value: establishment.email!,
              onTap: () => _launchEmail(establishment.email!),
              trailingIcon: Iconsax.arrow_right_3,
              isFirst: false,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    required IconData trailingIcon,
    required bool isFirst,
    required bool isLast,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppDimens.radiusM) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppDimens.radiusM) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.white),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ),
            Icon(trailingIcon, size: 16, color: Colors.white38),
          ],
        ),
      ),
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
                : () => _showLockedDialog(context, context.l10n.call),
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
        if (establishment.hasCoordinates) ...[
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: _ActionButton(
              icon: Iconsax.location_tick,
              label: context.l10n.location,
              color: AppColors.primaryGreen,
              onTap: () => _shareLocation(establishment),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactButton(Establishment establishment) {
    final isPremium = _isPremiumOrAbove(establishment);
    return SizedBox(
      width: double.infinity,
      child: isPremium
          ? OutlinedButton.icon(
              onPressed: () => _showContactForm(establishment),
              icon: const Icon(Iconsax.message_edit, color: AppColors.white),
              label: Text(
                context.l10n.contactRequest,
                style: const TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () =>
                  _showLockedDialog(context, context.l10n.contactRequest),
              icon: const Icon(Icons.lock_rounded,
                  color: AppColors.textHint, size: 18),
              label: Text(
                context.l10n.contactRequest,
                style: const TextStyle(
                    color: AppColors.textHint, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.textHint, width: 1.5),
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
                  color: Color(0xFF002FA7),
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
                        context.l10n.contactRequest,
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
                        decoration: InputDecoration(
                          labelText: context.l10n.yourName,
                          prefixIcon: const Icon(Iconsax.user),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.l10n.fieldRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: context.l10n.yourEmail,
                          prefixIcon: const Icon(Iconsax.sms),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return context.l10n.fieldRequired;
                          }
                          if (!v.contains('@'))
                            return context.l10n.invalidEmail;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: context.l10n.yourMessage,
                          prefixIcon: const Icon(Iconsax.message_text),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.l10n.fieldRequired
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              context.l10n.contactRequestSent),
                                          backgroundColor:
                                              AppColors.accentGreen,
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    setSheetState(() => isSubmitting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              context.l10n.contactRequestError),
                                          backgroundColor: AppColors.primaryRed,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
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
                              : Text(
                                  context.l10n.send,
                                  style: const TextStyle(
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
                      color:
                          hours == context.l10n.closed ? AppColors.error : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.location,
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
            width: double.infinity,
            child: Image.network(
              _mapboxStaticUrl(
                establishment.latitude!,
                establishment.longitude!,
                width: 600,
                height: 220,
              ),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE8E8E8),
                child: const Center(
                  child: Icon(Icons.map_outlined,
                      size: 48, color: Color(0xFFAAAAAA)),
                ),
              ),
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
                      label: Text(context.l10n.directions),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
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
                          SnackBar(content: Text(context.l10n.addressCopied)),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(context.l10n.copyAddress),
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
                  context.l10n.websiteLabel,
                  onTap: () =>
                      _showLockedDialog(context, context.l10n.websiteLabel),
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
      onTap: () => _showLockedDialog(context, context.l10n.customerReviews),
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
              context.l10n.customerReviews,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.notAvailableForEstab,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white24,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String get _sortLabel {
    if (_sortBy == 'rating' && _sortOrder == 'DESC')
      return context.l10n.sortHighestRated;
    if (_sortBy == 'rating' && _sortOrder == 'ASC')
      return context.l10n.sortLowestRated;
    if (_sortBy == 'created_at' && _sortOrder == 'ASC')
      return context.l10n.sortOldest;
    return context.l10n.sortMostRecent;
  }

  String get _ratingLabel => _ratingFilter != null
      ? context.l10n.nStars(_ratingFilter!)
      : context.l10n.rating;

  void _reloadReviews() {
    _bloc.add(EstablishmentLoadReviews(
      eliteOnly: _eliteOnly,
      rating: _ratingFilter,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    ));
  }

  Widget _filterPill({
    required String label,
    required bool hasChevron,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primaryGreen : Colors.white,
              ),
            ),
            if (hasChevron) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive ? AppColors.primaryGreen : Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    final options = [
      (context.l10n.sortMostRecent, 'created_at', 'DESC'),
      (context.l10n.sortOldest, 'created_at', 'ASC'),
      (context.l10n.sortHighestRated, 'rating', 'DESC'),
      (context.l10n.sortLowestRated, 'rating', 'ASC'),
    ];
    showModalBottomSheet(
      backgroundColor: AppColors.scaffoldBackground,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...options.map((opt) {
            final isSelected = _sortBy == opt.$2 && _sortOrder == opt.$3;
            return ListTile(
              title: Text(
                opt.$1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.primaryGreen, fontSize: 16),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primaryGreen)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sortBy = opt.$2;
                  _sortOrder = opt.$3;
                });
                _reloadReviews();
              },
            );
          }),
          ListTile(
            title: Text(
              context.l10n.eliteReviews,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.primaryGreen, fontSize: 16),
            ),
            trailing: _eliteOnly
                ? const Icon(Icons.check, color: AppColors.primaryGreen)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _eliteOnly = !_eliteOnly);
              _reloadReviews();
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.grey700,
                  side: const BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.l10n.cancel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingSheet() {
    showModalBottomSheet(
      backgroundColor: AppColors.scaffoldBackground,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...[5, 4, 3, 2, 1].map((r) => ListTile(
                title: Text(
                  context.l10n.nStars(r),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.primaryGreen, fontSize: 16),
                ),
                trailing: _ratingFilter == r
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _ratingFilter = r);
                  _reloadReviews();
                },
              )),
          ListTile(
            title: Text(
              context.l10n.allReviews,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.primaryGreen, fontSize: 16),
            ),
            trailing: _ratingFilter == null
                ? const Icon(Icons.check, color: AppColors.primaryGreen)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _ratingFilter = null);
              _reloadReviews();
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.grey700,
                  side: const BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.l10n.cancel),
              ),
            ),
          ),
        ],
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
        const SizedBox(height: AppDimens.paddingM),
        // ── Yelp-style filter pills ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterPill(
                label: _sortLabel,
                hasChevron: true,
                isActive: _sortBy != 'created_at' || _sortOrder != 'DESC',
                onTap: _showSortSheet,
              ),
              const SizedBox(width: 8),
              _filterPill(
                label: context.l10n.eliteReviews,
                hasChevron: false,
                isActive: _eliteOnly,
                onTap: () {
                  setState(() => _eliteOnly = !_eliteOnly);
                  _reloadReviews();
                },
              ),
              const SizedBox(width: 8),
              _filterPill(
                label: _ratingLabel,
                hasChevron: true,
                isActive: _ratingFilter != null,
                onTap: _showRatingSheet,
              ),
            ],
          ),
        ),
        if (_eliteOnly || _ratingFilter != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _eliteOnly && _ratingFilter != null
                    ? '${context.l10n.eliteReviews} · ${context.l10n.nStars(_ratingFilter!)}'
                    : _eliteOnly
                        ? context.l10n.eliteReviews
                        : context.l10n.nStars(_ratingFilter!),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _eliteOnly = false;
                    _ratingFilter = null;
                  });
                  _reloadReviews();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.l10n.clearFilters,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppDimens.paddingM),
        if (state.isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: CircularProgressIndicator(color: AppColors.white),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.user?.isElite == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.medal_star,
                                    size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'Élite',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          review.rating,
                          (i) => const Text('🇩🇿',
                              style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                const Icon(Iconsax.calendar_1,
                    size: 13, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  context.l10n.visitedOn(_formatDate(review.visitDate!)),
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
              context.l10n.detailedRatings,
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
              final labels = {
                'quality': context.l10n.subRatingQuality,
                'welcome': context.l10n.subRatingWelcome,
                'information': context.l10n.subRatingInformation,
                'value': context.l10n.subRatingValue,
                'availability': context.l10n.subRatingAvailability,
                'reliability': context.l10n.subRatingReliability,
                'comfort': context.l10n.subRatingComfort,
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
                    review.images![i].url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.grey200,
                      child:
                          const Icon(Iconsax.image, color: AppColors.grey400),
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
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.partnerReply!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    const Icon(Iconsax.flag,
                        size: 14, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.report,
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
      return context.l10n.timeAgoYears(difference.inDays ~/ 365);
    } else if (difference.inDays > 30) {
      return context.l10n.timeAgoMonths(difference.inDays ~/ 30);
    } else if (difference.inDays > 0) {
      return context.l10n.timeAgoDays(difference.inDays);
    } else if (difference.inHours > 0) {
      return context.l10n.timeAgoHours(difference.inHours);
    } else {
      return context.l10n.timeAgoJustNow;
    }
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM. yyyy', locale).format(date);
  }

  // ==================== HEADER CONTENT ====================

  Widget _buildHeaderContent(Establishment establishment, bool isFavorited) {
    final isOpen = OpeningHoursHelper.isOpenNow(establishment.openingHours);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (establishment.category != null)
            Text(
              establishment.category!.name,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                isOpen ? context.l10n.open : context.l10n.closed,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOpen ? AppColors.success : AppColors.error,
                ),
              ),
              if (establishment.openingHours != null) ...[
                const SizedBox(width: 4),
                Text(
                  context.l10n.seeHours,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.primaryGreen),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHeaderActionButton(
                  icon: Iconsax.star,
                  label: context.l10n.addReview,
                  filled: true,
                  onTap: () {
                    if (!_isPremiumOrAbove(establishment)) {
                      _showLockedDialog(context, context.l10n.customerReviews);
                      return;
                    }
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      final name = Uri.encodeComponent(establishment.name);
                      final cat = Uri.encodeComponent(
                          establishment.category?.name ?? '');
                      context
                          .push(
                        '${AppRoutes.writeReview.replaceFirst(':establishmentId', establishment.id)}?name=$name&category=$cat',
                      )
                          .then((result) {
                        if (result == true && mounted) {
                          _bloc.add(const EstablishmentLoadReviews());
                        }
                      });
                    } else {
                      _showLoginRequiredDialog(
                          message: context.l10n.loginToReview);
                    }
                  },
                ),
                const SizedBox(width: 8),
                if (establishment.hasWebsite) ...[
                  _buildHeaderActionButton(
                    icon: Iconsax.global,
                    label: context.l10n.website,
                    filled: false,
                    onTap: () => _launchUrl(establishment.website!),
                  ),
                  const SizedBox(width: 8),
                ],
                if (establishment.phone.isNotEmpty) ...[
                  _buildHeaderActionButton(
                    icon: Iconsax.call,
                    label: context.l10n.call,
                    filled: false,
                    onTap: _isPremiumOrAbove(establishment)
                        ? () => _launchPhone(establishment.phone)
                        : () => _showLockedDialog(context, context.l10n.call),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildHeaderActionButton(
                  icon: Iconsax.routing,
                  label: context.l10n.directions,
                  filled: false,
                  onTap: () => _showDirectionsOptions(establishment),
                ),
                const SizedBox(width: 8),
                _buildHeaderActionButton(
                  icon: Iconsax.share,
                  label: context.l10n.share,
                  filled: false,
                  onTap: () => _shareEstablishment(establishment),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is! AuthAuthenticated) {
                      _showLoginRequiredDialog(
                          message: context.l10n.loginToFavoriteMsg);
                      return;
                    }
                    _bloc.add(EstablishmentToggleFavorite());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFavorited
                          ? AppColors.primaryRed.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isFavorited
                            ? AppColors.primaryRed
                            : const Color(0xFFDDDDDD),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFavorited ? Iconsax.heart5 : Iconsax.heart,
                          size: 16,
                          color: isFavorited
                              ? AppColors.primaryRed
                              : Colors.black87,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isFavorited
                              ? context.l10n.favorited
                              : context.l10n.favorites,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFavorited
                                ? AppColors.primaryRed
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRecommendSection(establishment, isFavorited),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: filled ? AppColors.primaryGreen : const Color(0xFFDDDDDD),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendSection(Establishment establishment, bool isFavorited) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.recommendQuestion,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildRecommendButton(
              label: context.l10n.yes,
              icon: Icons.thumb_up_outlined,
              onTap: () => _onRecommend(establishment, rating: null),
            ),
            const SizedBox(width: 8),
            _buildRecommendButton(
              label: context.l10n.no,
              icon: Icons.thumb_down_outlined,
              onTap: () => _onRecommend(establishment, rating: 1),
            ),
            const SizedBox(width: 8),
            _buildRecommendButton(
              label: context.l10n.maybe,
              icon: isFavorited ? Icons.bookmark : Icons.bookmark_border,
              activeColor: isFavorited ? AppColors.primaryGreen : null,
              onTap: () => _onMaybe(establishment, isFavorited),
            ),
          ],
        ),
      ],
    );
  }

  void _onRecommend(Establishment establishment, {int? rating}) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showLoginRequiredDialog(message: context.l10n.loginToReview);
      return;
    }
    final name = Uri.encodeComponent(establishment.name);
    final ratingParam = rating != null ? '&initialRating=$rating' : '';
    context.push('/review/${establishment.id}?name=$name$ratingParam');
  }

  void _onMaybe(Establishment establishment, bool isFavorited) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showLoginRequiredDialog(message: context.l10n.loginToFavoriteMsg);
      return;
    }
    _bloc.add(EstablishmentToggleFavorite());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorited
              ? context.l10n.removedFromFavorites
              : context.l10n.addedToFavorites,
        ),
        backgroundColor:
            isFavorited ? AppColors.grey700 : AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRecommendButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? Colors.black87;
    final isActive = activeColor != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : const Color(0xFFDDDDDD),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TABS (stubs) ====================

  Widget _buildApercuTab(
      Establishment establishment, EstablishmentLoaded state) {
    final fullAddress = _buildFullAddress(establishment);
    final isPremium = _isPremiumOrAbove(establishment);

    return SingleChildScrollView(
      key: const PageStorageKey('tab-apercu'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Informations rapides ──
          _buildApercuSection(
            title: context.l10n.informationSection,
            child: Column(
              children: [
                if (establishment.phone.isNotEmpty)
                  _buildApercuRow(
                    icon: Iconsax.call,
                    label: establishment.formattedPhone ?? establishment.phone,
                    onTap: isPremium
                        ? () => _launchPhone(establishment.phone)
                        : () => _showLockedDialog(context, context.l10n.call),
                    locked: !isPremium,
                    isFirst: true,
                    isLast:
                        !establishment.hasWebsite && !establishment.hasEmail,
                  ),
                if (establishment.hasWebsite) ...[
                  const Divider(height: 1, indent: 48),
                  _buildApercuRow(
                    icon: Iconsax.global,
                    label: establishment.website!,
                    onTap: isPremium
                        ? () => _launchUrl(establishment.website!)
                        : () => _showLockedDialog(
                            context, context.l10n.websiteLabel),
                    locked: !isPremium,
                    isFirst: establishment.phone.isEmpty,
                    isLast: !establishment.hasEmail,
                  ),
                ],
                if (establishment.hasEmail) ...[
                  const Divider(height: 1, indent: 48),
                  _buildApercuRow(
                    icon: Iconsax.sms,
                    label: establishment.email!,
                    onTap: () => _launchEmail(establishment.email!),
                    locked: false,
                    isFirst: establishment.phone.isEmpty &&
                        !establishment.hasWebsite,
                    isLast: true,
                  ),
                ],
                if (establishment.facebook != null) ...[
                  const Divider(height: 1, indent: 48),
                  _buildApercuRow(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    onTap: isPremium
                        ? () => _launchUrl(establishment.facebook!)
                        : () => _showLockedDialog(context, 'Facebook'),
                    locked: !isPremium,
                    isFirst: false,
                    isLast: establishment.instagram == null &&
                        establishment.tiktok == null,
                  ),
                ],
                if (establishment.instagram != null) ...[
                  const Divider(height: 1, indent: 48),
                  _buildApercuRow(
                    icon: Iconsax.camera,
                    label: 'Instagram',
                    onTap: isPremium
                        ? () => _launchUrl(establishment.instagram!)
                        : () => _showLockedDialog(context, 'Instagram'),
                    locked: !isPremium,
                    isFirst: false,
                    isLast: establishment.tiktok == null,
                  ),
                ],
                if (establishment.tiktok != null) ...[
                  const Divider(height: 1, indent: 48),
                  _buildApercuRow(
                    icon: Iconsax.video,
                    label: 'TikTok',
                    onTap: isPremium
                        ? () => _launchUrl(establishment.tiktok!)
                        : () => _showLockedDialog(context, 'TikTok'),
                    locked: !isPremium,
                    isFirst: false,
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Carte miniature + adresse ──
          if (establishment.hasCoordinates)
            _buildApercuSection(
              title: context.l10n.location,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Image.network(
                        _mapboxStaticUrl(
                          establishment.latitude!,
                          establishment.longitude!,
                          width: 600,
                          height: 160,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE8E8E8),
                          child: const Center(
                            child: Icon(Icons.map_outlined,
                                size: 40, color: Color(0xFFAAAAAA)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      children: [
                        if (_routeDrivingMin != null &&
                            _routeDistanceKm != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n
                                      .drivingMinutes(_routeDrivingMin!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_routeDistanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildApercuRow(
                          icon: Iconsax.location,
                          label: fullAddress,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: fullAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(context.l10n.addressCopied)),
                            );
                          },
                          locked: false,
                          isFirst: true,
                          isLast: false,
                        ),
                        const Divider(height: 1, indent: 48),
                        _buildApercuRow(
                          icon: Iconsax.routing,
                          label: context.l10n.seeDirections,
                          onTap: () => _showDirectionsOptions(establishment),
                          locked: false,
                          isFirst: false,
                          isLast: true,
                          labelColor: AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ── Prise de contact (premium & gold uniquement) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: isPremium
                  ? OutlinedButton.icon(
                      onPressed: () => _showContactForm(establishment),
                      icon: const Icon(Iconsax.message_edit,
                          color: AppColors.primaryGreen),
                      label: Text(
                        context.l10n.contactRequest,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: AppColors.primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _showLockedDialog(
                          context, context.l10n.contactRequest),
                      icon: const Icon(Icons.lock_rounded,
                          color: AppColors.textHint, size: 18),
                      label: Text(
                        context.l10n.contactRequest,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: AppColors.textHint, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ── CTA partenaire (si non premium, non admin) ──
          if (!isPremium &&
              !(context.read<AuthBloc>().state is AuthAuthenticated &&
                  (context.read<AuthBloc>().state as AuthAuthenticated)
                      .user
                      .isAdmin))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is! AuthAuthenticated) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Iconsax.profile_circle, size: 20),
                            const SizedBox(width: 8),
                            Text(context.l10n.connect,
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        content: Text(
                          context.l10n.loginToClaimBusiness,
                          style: const TextStyle(height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(context.l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push(AppRoutes.login);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen),
                            child: Text(context.l10n.signIn,
                                style: const TextStyle(color: AppColors.white)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  if (authState.user.isPartner) {
                    context.push(AppRoutes.partnerSubscription);
                  } else {
                    context.push(AppRoutes.registerPartner);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greenSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          color: AppColors.primaryGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.ownThisPlace,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.claimNow,
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.grey600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Iconsax.arrow_right_3,
                          size: 18, color: AppColors.primaryGreen),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildApercuSection({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApercuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool locked,
    required bool isFirst,
    required bool isLast,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: locked ? Colors.black26 : AppColors.grey700),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      locked ? Colors.black26 : (labelColor ?? Colors.black87),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (locked)
              const Icon(Icons.lock_rounded, size: 14, color: Colors.black26)
            else
              Icon(
                isLast && labelColor == null
                    ? Icons.copy_rounded
                    : Iconsax.arrow_right_3,
                size: 16,
                color: AppColors.grey400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosTab(Establishment establishment) {
    final fullAddress = _buildFullAddress(establishment);
    final authState = context.read<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.fullName
        : context.l10n.youLabel;

    return SingleChildScrollView(
      key: const PageStorageKey('tab-infos'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grande carte + localisation ──
          if (establishment.hasCoordinates) ...[
            ClipRRect(
              child: SizedBox(
                height: 270,
                width: double.infinity,
                child: Image.network(
                  _mapboxStaticUrl(
                    establishment.latitude!,
                    establishment.longitude!,
                    width: 600,
                    height: 270,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8E8E8),
                    child: const Center(
                      child: Icon(Icons.map_outlined,
                          size: 48, color: Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  if (_routeDrivingMin != null && _routeDistanceKm != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car,
                              size: 18, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.drivingMinutes(_routeDrivingMin!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_routeDistanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                  _buildInfosRow(
                    icon: Iconsax.location,
                    label: fullAddress,
                    trailing: Icons.copy_rounded,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: fullAddress));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.addressCopied)),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  _buildInfosRow(
                    icon: Iconsax.routing,
                    label: context.l10n.seeDirections,
                    labelColor: AppColors.primaryGreen,
                    trailing: Iconsax.arrow_right_3,
                    onTap: () => _showDirectionsOptions(establishment),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFF002FA7)),
            const SizedBox(height: 8),
          ],

          // ── Fonctionnalités (services + amenities) ──
          if ((establishment.services != null &&
                  establishment.services!.isNotEmpty) ||
              (establishment.amenities != null &&
                  establishment.amenities!.isNotEmpty)) ...[
            _buildInfosBlockTitle(context.l10n.features),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  if (establishment.services != null)
                    ...establishment.services!.map(
                      (s) => _buildFeatureRow(
                          Iconsax.tick_circle, _localizedFeatureLabel(s)),
                    ),
                  if (establishment.amenities != null)
                    ...establishment.amenities!.map(
                      (a) => _buildFeatureRow(
                          Iconsax.star, _localizedFeatureLabel(a)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFF002FA7)),
            const SizedBox(height: 8),
          ],

          // ── Horaires d'ouverture ──
          if (establishment.openingHours != null) ...[
            _buildInfosBlockTitle(context.l10n.openingHours),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: (() {
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
                  return dayNames.entries.map((entry) {
                    final dayHours = hours[entry.key];
                    String hoursText = context.l10n.closed;
                    if (dayHours != null && dayHours['is_closed'] != true) {
                      final open = dayHours['open'];
                      final close = dayHours['close'];
                      if (open != null && close != null) {
                        hoursText = '$open - $close';
                      }
                    }
                    return _buildDayRow(entry.value, hoursText,
                        isLast: entry.key == 'sunday');
                  }).toList();
                })(),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFF002FA7)),
            const SizedBox(height: 8),
          ],

          // ── À propos ──
          if (establishment.description != null &&
              establishment.description!.isNotEmpty) ...[
            _buildInfosBlockTitle(context.l10n.aboutThisPlace),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    establishment.description!,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white, height: 1.6),
                    maxLines: _descriptionExpanded ? null : 3,
                    overflow:
                        _descriptionExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (establishment.description!.length > 120) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(
                          () => _descriptionExpanded = !_descriptionExpanded),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _descriptionExpanded
                              ? context.l10n.showLess
                              : context.l10n.readMore,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFF002FA7)),
            const SizedBox(height: 8),
          ],

          // ── Laisser un avis (inline) ──
          _buildInfosBlockTitle(context.l10n.writeAReview),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF002FA7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.grey200,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () {
                          if (!_isPremiumOrAbove(establishment)) {
                            _showLockedDialog(
                                context, context.l10n.customerReviews);
                            return;
                          }
                          if (authState is! AuthAuthenticated) {
                            _showLoginRequiredDialog(
                                message: context.l10n.loginToReview);
                            return;
                          }
                          final name = Uri.encodeComponent(establishment.name);
                          final cat = Uri.encodeComponent(
                              establishment.category?.name ?? '');
                          context
                              .push(
                            '${AppRoutes.writeReview.replaceFirst(':establishmentId', establishment.id)}?name=$name&category=$cat',
                          )
                              .then((result) {
                            if (result == true && mounted) {
                              _bloc.add(const EstablishmentLoadReviews());
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Iconsax.star,
                            size: 28,
                            color: AppColors.grey300,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (!_isPremiumOrAbove(establishment)) {
                        _showLockedDialog(
                            context, context.l10n.customerReviews);
                        return;
                      }
                      if (authState is! AuthAuthenticated) {
                        _showLoginRequiredDialog(
                            message: context.l10n.loginToReview);
                        return;
                      }
                      final name = Uri.encodeComponent(establishment.name);
                      final cat = Uri.encodeComponent(
                          establishment.category?.name ?? '');
                      context
                          .push(
                        '${AppRoutes.writeReview.replaceFirst(':establishmentId', establishment.id)}?name=$name&category=$cat',
                      )
                          .then((result) {
                        if (result == true && mounted) {
                          _bloc.add(const EstablishmentLoadReviews());
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.writeReviewHint,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.grey400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isPremiumOrAbove(establishment)) {
                              _showLockedDialog(
                                  context, context.l10n.customerReviews);
                              return;
                            }
                            if (authState is! AuthAuthenticated) {
                              _showLoginRequiredDialog(
                                  message: context.l10n.loginToReview);
                              return;
                            }
                            final name =
                                Uri.encodeComponent(establishment.name);
                            final cat = Uri.encodeComponent(
                                establishment.category?.name ?? '');
                            context
                                .push(
                              '${AppRoutes.writeReview.replaceFirst(':establishmentId', establishment.id)}?name=$name&category=$cat',
                            )
                                .then((result) {
                              if (result == true && mounted) {
                                _bloc.add(const EstablishmentLoadReviews());
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.camera,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.addPhoto,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(context.l10n.checkInComingSoon)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.location_tick,
                                    size: 18, color: Colors.black54),
                                SizedBox(width: 6),
                                Text(
                                  'Check-In',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfosBlockTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfosRow({
    required IconData icon,
    required String label,
    required IconData trailing,
    required VoidCallback onTap,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.grey600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(trailing, size: 16, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  String _localizedFeatureLabel(String raw) {
    final key = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final l = context.l10n;
    return <String, String Function()>{
      // ── Connectivité ──
      'wifi': () => l.featureWifi,
      'wi-fi': () => l.featureWifi,
      'wifi gratuit': () => l.featureFreeWifi,
      'wi-fi gratuit': () => l.featureFreeWifi,
      // ── Parking ──
      'parking': () => l.featureParking,
      'parking couvert': () => l.featureCoveredParking,
      'parking à proximité': () => l.featureNearbyParking,
      'parking a proximite': () => l.featureNearbyParking,
      // ── Restauration ──
      'bar': () => l.featureBar,
      'livraison': () => l.featureDelivery,
      'livraison à domicile': () => l.featureDelivery,
      'traiteur': () => l.featureCatering,
      'commande en ligne': () => l.featureOnlineOrder,
      'sur place': () => l.featureDineIn,
      'à emporter': () => l.featureTakeaway,
      'a emporter': () => l.featureTakeaway,
      'drive': () => l.featureDrive,
      // ── Paiement ──
      'paiement en ligne': () => l.featureOnlinePayment,
      'carte bancaire': () => l.featureCardPayment,
      // ── Accessibilité ──
      'accès pmr': () => l.featureDisabledAccess,
      'acces pmr': () => l.featureDisabledAccess,
      'accès handicapé': () => l.featureDisabledAccess,
      'pmr': () => l.featureDisabledAccess,
      // ── Réservation & services ──
      'réservation': () => l.featureReservation,
      'reservation': () => l.featureReservation,
      'conseil': () => l.featureConsultation,
      'assurance': () => l.featureInsurance,
      'service voiturier': () => l.featureValet,
      'voiturier': () => l.featureValet,
      'blanchisserie': () => l.featureLaundry,
      'pressing': () => l.featureLaundry,
      'réception 24h/24': () => l.feature24hReception,
      'reception 24h/24': () => l.feature24hReception,
      'coffre-fort': () => l.featureSafe,
      // ── Confort ──
      'climatisation': () => l.featureAirConditioning,
      'clim': () => l.featureAirConditioning,
      'chauffage': () => l.featureHeating,
      // ── Espaces ──
      'terrasse': () => l.featureTerrace,
      'jardin': () => l.featureGarden,
      'piscine': () => l.featurePool,
      'salle de sport': () => l.featureGym,
      'gym': () => l.featureGym,
      'fitness': () => l.featureFitness,
      'tennis': () => l.featureTennis,
      'espace enfants': () => l.featureKidsArea,
      'jeux enfants': () => l.featureKidsArea,
      'espace vip': () => l.featureVipArea,
      'salle de prière': () => l.featurePrayerRoom,
      'salle de priere': () => l.featurePrayerRoom,
      'salle de conférence': () => l.featureConferenceRoom,
      'salle de conference': () => l.featureConferenceRoom,
      'vestiaires': () => l.featureChangingRooms,
      'cuisine équipée': () => l.featureEquippedKitchen,
      'cuisine equipee': () => l.featureEquippedKitchen,
      // ── Fumeurs ──
      'non-fumeur': () => l.featureNonSmoking,
      'non fumeur': () => l.featureNonSmoking,
      'espace fumeur': () => l.featureSmokingArea,
      'zone fumeur': () => l.featureSmokingArea,
      // ── Animaux ──
      'animaux acceptés': () => l.featurePetsWelcome,
      'animaux bienvenus': () => l.featurePetsWelcome,
      // ── Vue ──
      'vue mer': () => l.featureSeaView,
      // ── Chambre / Hôtel ──
      'service en chambre': () => l.featureRoomService,
      // ── Événementiel ──
      'location salle': () => l.featureHallRental,
      'décoration': () => l.featureDecoration,
      'decoration': () => l.featureDecoration,
      'dj': () => l.featureDj,
      'photographe': () => l.featurePhotographer,
      'sonorisation': () => l.featureSoundSystem,
      'sono': () => l.featureSoundSystem,
      'vidéoprojecteur': () => l.featureProjector,
      'videoprojecteur': () => l.featureProjector,
      'animation': () => l.featureAnimation,
      'spectacle': () => l.featureEntertainment,
      // ── Bien-être ──
      'spa': () => l.featureSpa,
      'hammam': () => l.featureHammam,
      'sauna': () => l.featureSauna,
      'jacuzzi': () => l.featureJacuzzi,
      'gommage': () => l.featureScrub,
      'massage': () => l.featureMassage,
      'soin visage': () => l.featureFacialTreatment,
      'soins corps': () => l.featureBodyTreatment,
      'manucure': () => l.featureManicure,
      'pédicure': () => l.featurePedicure,
      'pedicure': () => l.featurePedicure,
      'épilation': () => l.featureWaxing,
      'epilation': () => l.featureWaxing,
      'maquillage': () => l.featureMakeup,
      // ── Location ──
      'location courte durée': () => l.featureShortTermRental,
      'location courte duree': () => l.featureShortTermRental,
      'location longue durée': () => l.featureLongTermRental,
      'location longue duree': () => l.featureLongTermRental,
      // ── Mobilité ──
      'vélos disponibles': () => l.featureBicycles,
      'velos disponibles': () => l.featureBicycles,
      'borne de recharge': () => l.featureEVCharging,
    }[key]
        ?.call() ??
        raw;
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisTab(Establishment establishment, EstablishmentLoaded state) {
    final reviews = state.reviews;
    final total = establishment.totalReviews;
    final avg = establishment.averageRating;

    // Distribution depuis l'API
    final Map<int, int> dist =
        state.reviewsData?.ratingDistribution ?? {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final maxCount = dist.values.fold(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      key: const PageStorageKey('tab-avis'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Note globale + distribution ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.recommendedReviews,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Note + drapeaux
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            avg.round().clamp(0, 5),
                            (i) => const Text('🇩🇿',
                                style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          context.l10n.reviewsCount(total),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Barres de distribution
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((star) {
                          final count = dist[star] ?? 0;
                          final fraction =
                              maxCount > 0 ? count / maxCount : 0.0;
                          final barColor = star >= 4
                              ? const Color(0xFFE53935)
                              : star == 3
                                  ? const Color(0xFFFFA726)
                                  : const Color(0xFFBDBDBD);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  '$star',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.grey500),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          color: const Color(0xFFEEEEEE),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: fraction,
                                          child: Container(
                                            height: 8,
                                            color: barColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF002FA7)),
          const SizedBox(height: 12),

          // ── Pills filtres ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterPill(
                    label: _sortLabel,
                    hasChevron: true,
                    isActive: _sortBy != 'created_at' || _sortOrder != 'DESC',
                    onTap: _showSortSheet,
                  ),
                  const SizedBox(width: 8),
                  _filterPill(
                    label: context.l10n.eliteReviews,
                    hasChevron: false,
                    isActive: _eliteOnly,
                    onTap: () {
                      setState(() => _eliteOnly = !_eliteOnly);
                      _reloadReviews();
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterPill(
                    label: _ratingLabel,
                    hasChevron: true,
                    isActive: _ratingFilter != null,
                    onTap: _showRatingSheet,
                  ),
                ],
              ),
            ),
          ),

          // ── Filtre actif — bouton Effacer ──
          if (_eliteOnly || _ratingFilter != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _eliteOnly && _ratingFilter != null
                        ? '${context.l10n.eliteReviews} · ${context.l10n.nStars(_ratingFilter!)}'
                        : _eliteOnly
                            ? context.l10n.eliteReviews
                            : context.l10n.nStars(_ratingFilter!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _eliteOnly = false;
                        _ratingFilter = null;
                      });
                      _reloadReviews();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.clearFilters,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Liste des avis ──
          if (!_isPremiumOrAbove(establishment))
            _buildLockedReviewsSection()
          else if (state.isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else if (reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Iconsax.message_text,
                        size: 48, color: AppColors.grey300),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noReviews,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.beFirstReview,
                      style: const TextStyle(
                          color: AppColors.grey400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildReviewCard(reviews[index]),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSimilairesTab(Establishment establishment) {
    if (establishment.category == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.noSimilarEstablishments,
            style: const TextStyle(color: AppColors.grey500, fontSize: 14),
          ),
        ),
      );
    }

    // Initialise la future une seule fois par établissement pour éviter
    // de re-souscrire à chaque rebuild du BlocBuilder (cause des erreurs "unmounted")
    if (_similarsFuture == null ||
        _similarsEstablishmentId != establishment.id) {
      _similarsEstablishmentId = establishment.id;
      _similarsFuture = EstablishmentRepository()
          .getByCategory(establishment.category!.id, limit: 10)
          .then((r) =>
              r.items.where((e) => e.id != establishment.id).take(8).toList());
    }

    return FutureBuilder<List<Establishment>>(
      future: _similarsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.white),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.building_3,
                      size: 48, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noSimilarEstablishments,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    establishment.category!.name,
                    style:
                        const TextStyle(color: AppColors.grey400, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final similaires = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: similaires.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 80, color: Color(0xFFEEEEEE)),
          itemBuilder: (context, index) {
            final e = similaires[index];
            return _buildSimilaireCard(e);
          },
        );
      },
    );
  }

  Widget _buildSimilaireCard(Establishment e) {
    final isOpen = OpeningHoursHelper.isOpenNow(e.openingHours);
    final isPremium = e.partnerSubscriptionPlan == 'premium' ||
        e.partnerSubscriptionPlan == 'gold';

    return InkWell(
      onTap: () {
        context.push('/establishment/${e.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: isPremium && e.coverImage != null
                    ? Image.network(
                        e.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildSimPlaceholder(e),
                      )
                    : _buildSimPlaceholder(e),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
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
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (e.isVerified)
                        const Icon(Iconsax.verify5,
                            size: 14, color: AppColors.primaryGreen),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Drapeaux + note
                  Row(
                    children: [
                      ...List.generate(
                        e.averageRating.round().clamp(0, 5),
                        (_) =>
                            const Text('🇩🇿', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        e.displayRating,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${e.totalReviews})',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.greenAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Catégorie + prix
                  Text(
                    [
                      if (e.category != null) e.category!.name,
                      if (e.priceRange != null) e.priceRange!,
                    ].join(' · '),
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.white),
                  ),
                  const SizedBox(height: 3),

                  // Statut ouverture
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOpen ? context.l10n.open : context.l10n.closed,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isOpen ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Iconsax.arrow_right_3,
                size: 16, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }

  Widget _buildSimPlaceholder(Establishment e) {
    return Container(
      color: AppColors.greenSurface,
      alignment: Alignment.center,
      child: Text(
        e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
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
              backgroundColor: AppColors.accentGreen,
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
    if (establishment.hasCoordinates) {
      final lat = establishment.latitude!;
      final lng = establishment.longitude!;
      final encodedName = Uri.encodeComponent(establishment.name);
      buffer.writeln();
      buffer.writeln('🗺️ Voir sur la carte :');
      buffer.writeln(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedName');
    }
    buffer.writeln();
    buffer.write('Découvert sur Win-وين 🔍');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _shareLocation(Establishment establishment) {
    if (!establishment.hasCoordinates) return;
    final lat = establishment.latitude!;
    final lng = establishment.longitude!;
    final encodedName = Uri.encodeComponent(establishment.name);
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedName';
    final text = '📍 Localisation précise de ${establishment.name}\n$mapsUrl';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ==================== LOCKED FEATURE DIALOG ====================

  bool _isPremiumOrAbove(Establishment e) =>
      e.partnerSubscriptionPlan == 'premium' ||
      e.partnerSubscriptionPlan == 'gold';

  void _showLockedDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.grey500, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.notAvailable,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          context.l10n.featureNotAvailable(featureName),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  // ==================== DIRECTIONS ====================

  void _showDirectionsOptions(Establishment establishment) {
    if (!establishment.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.coordinatesNotAvailable),
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
              context.l10n.openWith,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              context.l10n.chooseNavApp,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            _buildNavigationOption(
              context,
              icon: Icons.map,
              title: 'Google Maps',
              subtitle: context.l10n.gpsNavigation,
              color: const Color(0xFF4285F4),
              onTap: () => _openGoogleMaps(context),
            ),
            const SizedBox(height: AppDimens.paddingM),
            _buildNavigationOption(
              context,
              icon: Icons.navigation,
              title: 'Waze',
              subtitle: context.l10n.socialNavigation,
              color: const Color(0xFF33CCFF),
              onTap: () => _openWaze(context),
            ),
            const SizedBox(height: AppDimens.paddingM),
            _buildNavigationOption(
              context,
              icon: Icons.directions,
              title: 'Apple Plans',
              subtitle: context.l10n.appleNavigation,
              color: const Color(0xFF000000),
              onTap: () => _openAppleMaps(context),
            ),
            const SizedBox(height: AppDimens.paddingM),
            _buildNavigationOption(
              context,
              icon: Iconsax.map,
              title: context.l10n.otherApps,
              subtitle: context.l10n.openWithSystem,
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

// ==================== STICKY TAB BAR DELEGATE ====================

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
