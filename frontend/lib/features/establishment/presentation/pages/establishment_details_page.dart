import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _bloc = EstablishmentBloc();
    _loadEstablishment();
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
                      'Erreur de chargement',
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
                      child: const Text('Réessayer'),
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
                  _buildReviewsSection(state),
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
    final images = establishment.images ?? [];
    final hasImages = images.isNotEmpty;
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
                message: 'Connectez-vous pour ajouter cet établissement à vos favoris.',
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
                isOpen ? AppStrings.openNow : AppStrings.closedNow,
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
            const Icon(Icons.star_rounded,
                size: 20, color: AppColors.starFilled),
            const SizedBox(width: AppDimens.paddingXS),
            Text(
              establishment.displayRating,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: AppDimens.paddingXS),
            Text(
              '(${establishment.totalReviews} avis)',
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
            label: AppStrings.call,
            color: AppColors.primaryGreen,
            onTap: () => _launchPhone(establishment.phone),
          ),
        ),
        const SizedBox(width: AppDimens.paddingM),
        if (establishment.hasWhatsApp) ...[
          Expanded(
            child: _ActionButton(
              icon: Iconsax.message,
              label: AppStrings.whatsapp,
              color: const Color(0xFF25D366),
              onTap: () => _launchWhatsApp(establishment.whatsapp!),
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
        ],
        Expanded(
          child: _ActionButton(
            icon: Iconsax.routing,
            label: AppStrings.directions,
            color: AppColors.info,
            onTap: () => _showDirectionsOptions(establishment),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Establishment establishment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.about, style: Theme.of(context).textTheme.titleLarge),
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
        Text(AppStrings.services,
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
        Text(AppStrings.amenities,
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
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.openingHours,
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
              String hoursText = 'Fermé';

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
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
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

  Widget _buildContact(Establishment establishment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.contact, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimens.paddingS),
        _buildContactRow(
          Iconsax.call,
          establishment.formattedPhone ?? establishment.phone,
          onTap: () => _launchPhone(establishment.phone),
        ),
        if (establishment.hasEmail)
          _buildContactRow(
            Iconsax.sms,
            establishment.email!,
            onTap: () => _launchEmail(establishment.email!),
          ),
        if (establishment.hasWebsite)
          _buildContactRow(
            Iconsax.global,
            establishment.website!,
            onTap: () => _launchUrl(establishment.website!),
          ),
        if (establishment.facebook != null)
          _buildContactRow(
            Icons.facebook,
            'Facebook',
            onTap: () => _launchUrl(establishment.facebook!),
          ),
        if (establishment.instagram != null)
          _buildContactRow(
            Iconsax.camera,
            'Instagram',
            onTap: () => _launchUrl(establishment.instagram!),
          ),
      ],
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

  Widget _buildReviewsSection(EstablishmentLoaded state) {
    final reviews = state.reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.reviews} (${state.establishment.totalReviews})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (reviews.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.push(
                    '/establishment/${state.establishment.id}/reviews',
                    extra: {
                      'establishmentName': state.establishment.name,
                      'reviewsData': state.reviewsData,
                    },
                  );
                },
                child: const Text(AppStrings.seeAll),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingS),
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
                    'Aucun avis pour le moment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    'Soyez le premier à donner votre avis !',
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
        : 'Utilisateur';
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
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greenSurface,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: i < review.rating
                                ? AppColors.starFilled
                                : AppColors.starEmpty,
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingS),
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
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey700,
                  ),
            ),
          ],
          // Partner reply
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
                          'Réponse du propriétaire',
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
          // Report button
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
        const SnackBar(
          content: Text('Connectez-vous pour signaler un avis'),
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
        title: const Text('Signaler cet avis'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Raison du signalement (min. 10 caractères)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
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
                      const SnackBar(
                        content: Text('Signalement envoyé'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors du signalement'),
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
            child: const Text('Signaler'),
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

  Widget _buildBottomBar(Establishment establishment) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: OutlinedButton.icon(
        onPressed: () async {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final result = await context.push<bool>(
              AppRoutes.writeReview
                  .replaceFirst(':establishmentId', establishment.id),
            );
            if (result == true) {
              _bloc.add(const EstablishmentLoadReviews());
            }
          } else {
            _showLoginRequiredDialog(
              message: 'Vous devez être connecté pour écrire un avis.',
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
        label: const Text(AppStrings.writeReview),
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
        title: const Row(
          children: [
            Icon(Iconsax.lock, color: AppColors.primaryGreen),
            SizedBox(width: AppDimens.paddingS),
            Text('Connexion requise'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Se connecter'),
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
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
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
