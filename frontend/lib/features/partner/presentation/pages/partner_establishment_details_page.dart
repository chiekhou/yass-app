import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../data/repositories/partner_repository.dart';

class PartnerEstablishmentDetailsPage extends StatefulWidget {
  final String establishmentId;

  const PartnerEstablishmentDetailsPage({
    super.key,
    required this.establishmentId,
  });

  @override
  State<PartnerEstablishmentDetailsPage> createState() =>
      _PartnerEstablishmentDetailsPageState();
}

class _PartnerEstablishmentDetailsPageState
    extends State<PartnerEstablishmentDetailsPage> {
  final _repository = PartnerRepository();
  bool _isLoading = true;
  String? _errorMessage;
  Establishment? _establishment;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _loadEstablishment();
  }

  Future<void> _loadEstablishment() async {
    try {
      final establishment =
          await _repository.getEstablishmentById(widget.establishmentId);
      setState(() {
        _establishment = establishment;
        _isLoading = false;
      });
      _loadReviews();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final data = await _repository.getEstablishmentReviews(
        widget.establishmentId,
      );
      setState(() {
        _reviews = data.reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadEstablishment();
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final establishment = _establishment!;

    return CustomScrollView(
      slivers: [
        // App Bar with Cover Image
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (establishment.coverImage != null)
                  Image.network(
                    establishment.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      child: const Icon(
                        Iconsax.building,
                        size: 64,
                        color: AppColors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    child: const Icon(
                      Iconsax.building,
                      size: 64,
                      color: AppColors.white,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.edit),
              onPressed: () => context.push(
                AppRoutes.partnerEstablishmentEdit
                    .replaceFirst(':id', establishment.id),
              ),
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Stats Card
              _buildStatsCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Status Card
              _buildStatusCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Description Card
              if (establishment.description != null &&
                  establishment.description!.isNotEmpty)
                _buildDescriptionCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Contact Card
              _buildContactCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Location Card
              _buildLocationCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Social Media Card
              if (_hasSocialMedia(establishment)) _buildSocialMediaCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Reviews Card
              _buildReviewsCard(),

              const SizedBox(height: AppDimens.paddingXL),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.all(AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              color: AppColors.grey100,
              image: establishment.logo != null
                  ? DecorationImage(
                      image: NetworkImage(establishment.logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: establishment.logo == null
                ? const Icon(Iconsax.building, color: AppColors.grey400, size: 32)
                : null,
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        establishment.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (establishment.isVerified)
                      const Icon(
                        Iconsax.verify5,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                  ],
                ),
                if (establishment.category != null) ...[
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    establishment.category!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
                if (establishment.priceRange != null) ...[
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    establishment.priceRangeDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Iconsax.eye,
            value: establishment.totalViews.toString(),
            label: 'Vues',
          ),
          _buildStatItem(
            icon: Iconsax.heart,
            value: establishment.totalFavorites.toString(),
            label: 'Favoris',
          ),
          _buildStatItem(
            icon: Iconsax.star,
            value: establishment.displayRating,
            label: '(${establishment.totalReviews})',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 24),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Establishment establishment) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (establishment.status) {
      case 'active':
        statusColor = AppColors.success;
        statusLabel = 'Actif';
        statusIcon = Iconsax.tick_circle;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = 'En attente de validation';
        statusIcon = Iconsax.clock;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = 'Rejeté';
        statusIcon = Iconsax.close_circle;
        break;
      case 'inactive':
        statusColor = AppColors.grey500;
        statusLabel = 'Inactif';
        statusIcon = Iconsax.minus_cirlce;
        break;
      default:
        statusColor = AppColors.grey500;
        statusLabel = establishment.status;
        statusIcon = Iconsax.info_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.document_text, color: AppColors.grey600, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            establishment.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.call, color: AppColors.grey600, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                'Contact',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildContactRow(Iconsax.call, 'Téléphone', establishment.phone),
          if (establishment.phoneSecondary != null &&
              establishment.phoneSecondary!.isNotEmpty)
            _buildContactRow(
                Iconsax.call, 'Tél. secondaire', establishment.phoneSecondary!),
          if (establishment.whatsapp != null && establishment.whatsapp!.isNotEmpty)
            _buildContactRow(Iconsax.message, 'WhatsApp', establishment.whatsapp!),
          if (establishment.email != null && establishment.email!.isNotEmpty)
            _buildContactRow(Iconsax.sms, 'Email', establishment.email!),
          if (establishment.website != null && establishment.website!.isNotEmpty)
            _buildContactRow(Iconsax.global, 'Site web', establishment.website!),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey500, size: 18),
          const SizedBox(width: AppDimens.paddingS),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.location, color: AppColors.grey600, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                'Localisation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            establishment.address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                ),
          ),
          if (establishment.wilaya != null || establishment.commune != null) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              [
                if (establishment.commune != null) establishment.commune!.name,
                if (establishment.wilaya != null) establishment.wilaya!.name,
              ].join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ],
          if (establishment.hasCoordinates) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Coordonnées: ${establishment.latitude}, ${establishment.longitude}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasSocialMedia(Establishment establishment) {
    return (establishment.facebook != null && establishment.facebook!.isNotEmpty) ||
        (establishment.instagram != null && establishment.instagram!.isNotEmpty) ||
        (establishment.tiktok != null && establishment.tiktok!.isNotEmpty);
  }

  Widget _buildReviewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.message_text, color: AppColors.grey600, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                'Avis clients (${_reviews.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimens.paddingL),
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                child: Column(
                  children: [
                    const Icon(Iconsax.message_text,
                        size: 40, color: AppColors.grey300),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Aucun avis pour le moment',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey500,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
              _reviews.length > 5 ? 5 : _reviews.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < (_reviews.length > 5 ? 4 : _reviews.length - 1)
                      ? AppDimens.paddingM
                      : 0,
                ),
                child: _buildPartnerReviewCard(_reviews[index]),
              ),
            ),
          if (_reviews.length > 5) ...[
            const SizedBox(height: AppDimens.paddingM),
            Center(
              child: TextButton(
                onPressed: () {
                  context.push(
                    '/establishment/${widget.establishmentId}/reviews',
                    extra: {
                      'establishmentName': _establishment?.name,
                    },
                  );
                },
                child: Text(
                  'Voir tous les avis (${_reviews.length})',
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerReviewCard(Review review) {
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
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.greenSurface,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: i < review.rating
                                ? AppColors.starFilled
                                : AppColors.starEmpty,
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingXS),
                        Text(
                          timeAgo,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey500, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey700,
                    height: 1.4,
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
                      size: 14, color: AppColors.primaryGreen),
                  const SizedBox(width: AppDimens.paddingXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre réponse',
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
          ] else ...[
            // Reply button
            const SizedBox(height: AppDimens.paddingS),
            SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyDialog(review),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                icon: const Icon(Iconsax.message, size: 14),
                label: const Text('Répondre'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(Review review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: const Text('Répondre à cet avis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show the review
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: i < review.rating
                            ? AppColors.starFilled
                            : AppColors.starEmpty,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Votre réponse (min. 10 caractères)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
                  await _repository.replyToReview(
                    review.id,
                    controller.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Réponse envoyée'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadReviews();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Envoyer'),
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

  Widget _buildSocialMediaCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.link, color: AppColors.grey600, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                'Réseaux sociaux',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          if (establishment.facebook != null && establishment.facebook!.isNotEmpty)
            _buildContactRow(Iconsax.link, 'Facebook', establishment.facebook!),
          if (establishment.instagram != null && establishment.instagram!.isNotEmpty)
            _buildContactRow(Iconsax.instagram, 'Instagram', establishment.instagram!),
          if (establishment.tiktok != null && establishment.tiktok!.isNotEmpty)
            _buildContactRow(Iconsax.video, 'TikTok', establishment.tiktok!),
        ],
      ),
    );
  }
}
