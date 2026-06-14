import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/reviews_repository.dart';
import '../bloc/review_bloc.dart';

class AllReviewsPage extends StatefulWidget {
  final String establishmentId;
  final String? establishmentName;
  final String? categoryName;
  final ReviewsResponse? initialData;

  const AllReviewsPage({
    super.key,
    required this.establishmentId,
    this.establishmentName,
    this.categoryName,
    this.initialData,
  });

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  final ReviewRepository _repository = ReviewRepository();
  final ScrollController _scrollController = ScrollController();

  List<Review> _reviews = [];
  ReviewsResponse? _reviewsData;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  bool _eliteOnly = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _reviews = widget.initialData!.reviews;
      _reviewsData = widget.initialData;
      _hasMore = _reviews.length < widget.initialData!.totalReviews;
    } else {
      _loadReviews();
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
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getEstablishmentReviews(
        widget.establishmentId,
        page: 1,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        eliteOnly: _eliteOnly,
      );
      setState(() {
        _reviews = data.reviews;
        _reviewsData = data;
        _currentPage = 1;
        _hasMore = _reviews.length < data.totalReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getEstablishmentReviews(
        widget.establishmentId,
        page: _currentPage + 1,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        eliteOnly: _eliteOnly,
      );
      setState(() {
        _reviews.addAll(data.reviews);
        _currentPage++;
        _hasMore = _reviews.length < data.totalReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.establishmentName ?? 'Avis'),
      ),
      body: Column(
        children: [
          // Rating summary
          if (_reviewsData != null) _buildRatingSummary(),

          // Sort options
          _buildSortBar(),

          // Reviews list
          Expanded(
            child: _reviews.isEmpty && !_isLoading
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadReviews,
                    color: AppColors.primaryGreen,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      itemCount: _reviews.length + (_isLoading ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimens.paddingM),
                      itemBuilder: (context, index) {
                        if (index == _reviews.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimens.paddingM),
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen),
                            ),
                          );
                        }
                        return _buildReviewCard(_reviews[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final name = Uri.encodeComponent(widget.establishmentName ?? '');
            final cat = Uri.encodeComponent(widget.categoryName ?? '');
            final result = await context.push<bool>(
              '${AppRoutes.writeReview.replaceFirst(':establishmentId', widget.establishmentId)}?name=$name&category=$cat',
            );
            if (result == true) {
              _loadReviews();
            }
          } else {
            _showLoginRequiredDialog();
          }
        },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Iconsax.edit, size: 18),
        label: Text(context.l10n.writeReview),
      ),
    );
  }

  Widget _buildRatingSummary() {
    final data = _reviewsData!;
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.grey50,
      child: Row(
        children: [
          // Average rating
          Column(
            children: [
              Text(
                data.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Text('🇩🇿', style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.totalReviews} avis',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
              ),
            ],
          ),
          const SizedBox(width: AppDimens.paddingL),
          // Distribution bars
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = data.ratingDistribution[star] ?? 0;
                final total = data.totalReviews;
                final percentage = total > 0 ? count / total : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      const Text('🇩🇿', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: AppColors.grey200,
                            color: AppColors.starFilled,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey500,
                                  ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: Row(
            children: [
              Text(
                'Trier par :',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
              ),
              const SizedBox(width: AppDimens.paddingS),
              _buildSortChip('Plus récents', 'created_at', 'desc'),
              const SizedBox(width: AppDimens.paddingXS),
              _buildSortChip('Meilleure note', 'rating', 'desc'),
              const SizedBox(width: AppDimens.paddingXS),
              _buildSortChip('Plus anciens', 'created_at', 'asc'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimens.paddingM,
            right: AppDimens.paddingM,
            bottom: AppDimens.paddingS,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() => _eliteOnly = !_eliteOnly);
              _loadReviews();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _eliteOnly ? const Color(0xFFFFD700) : AppColors.grey100,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(
                  color:
                      _eliteOnly ? const Color(0xFFFFB300) : AppColors.grey200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.medal_star,
                    size: 14,
                    color: _eliteOnly ? Colors.white : AppColors.grey600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Avis Élite',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _eliteOnly ? Colors.white : AppColors.grey600,
                          fontWeight:
                              _eliteOnly ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String sortBy, String sortOrder) {
    final isSelected = _sortBy == sortBy && _sortOrder == sortOrder;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _sortBy = sortBy;
            _sortOrder = sortOrder;
          });
          _loadReviews();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? AppColors.white : AppColors.grey600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.grey200),
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
                    Row(
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.titleSmall,
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
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => const Text('🇩🇿',
                              style: TextStyle(fontSize: 12)),
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
          // Helpful button
          const SizedBox(height: AppDimens.paddingS),
          Row(
            children: [
              InkWell(
                onTap: () {
                  // Mark helpful - handled via ReviewBloc
                  context
                      .read<ReviewBloc>()
                      .add(ReviewMarkHelpful(reviewId: review.id));
                },
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.like_1,
                          size: 16, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        'Utile${review.helpfulCount > 0 ? ' (${review.helpfulCount})' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              InkWell(
                onTap: () => _showReportDialog(review.id),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.flag,
                          size: 16, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        'Signaler',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.message_text, size: 64, color: AppColors.white),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'Aucun avis pour le moment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Soyez le premier à donner votre avis !',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String reviewId) {
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
            onPressed: () {
              if (controller.text.trim().length >= 10) {
                context.read<ReviewBloc>().add(ReviewReport(
                      reviewId: reviewId,
                      reason: controller.text.trim(),
                    ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signalement envoyé'),
                    backgroundColor: AppColors.success,
                  ),
                );
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

  void _showLoginRequiredDialog() {
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
        content: const Text(
          'Vous devez être connecté pour écrire un avis.',
        ),
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
}
