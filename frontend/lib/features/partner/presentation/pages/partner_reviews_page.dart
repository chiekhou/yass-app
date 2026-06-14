import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/reviews/data/models/review_model.dart';
import '../../../../app_router.dart';
import '../widgets/partner_drawer.dart';

class PartnerReviewsPage extends StatefulWidget {
  const PartnerReviewsPage({super.key});

  @override
  State<PartnerReviewsPage> createState() => _PartnerReviewsPageState();
}

class _PartnerReviewsPageState extends State<PartnerReviewsPage> {
  final _apiClient = ApiClient.instance;
  final _scrollController = ScrollController();

  List<Review> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200 &&
        _hasMore &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final response = await _apiClient.get(
        ApiConfig.partnerReviews,
        queryParameters: {'page': 1, 'limit': 20},
      );
      final data = response.data['data'];
      final reviews =
          (data['reviews'] as List).map((e) => Review.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _hasMore = data['pagination']['hasNext'] == true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final response = await _apiClient.get(
        ApiConfig.partnerReviews,
        queryParameters: {'page': _page + 1, 'limit': 20},
      );
      final data = response.data['data'];
      final more =
          (data['reviews'] as List).map((e) => Review.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _reviews.addAll(more);
          _hasMore = data['pagination']['hasNext'] == true;
          _page++;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _showReplyDialog(Review review) async {
    final controller = TextEditingController(text: review.partnerReply ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Répondre à l\'avis'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Votre réponse...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Publier'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _submitReply(review.id, result);
    }
  }

  Future<void> _submitReply(String reviewId, String reply) async {
    try {
      await _apiClient.post(
        ApiConfig.partnerReviewReply(reviewId),
        data: {'reply': reply},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réponse publiée'),
            backgroundColor: AppColors.success,
          ),
        );
        _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Mes avis'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: PartnerDrawer(currentRoute: AppRoutes.partnerReviews),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: AppColors.grey400),
            const SizedBox(height: AppDimens.paddingM),
            Text(_error!, style: const TextStyle(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.paddingM),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.star, size: 64, color: AppColors.grey300),
            SizedBox(height: AppDimens.paddingM),
            Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.grey600,
              ),
            ),
            SizedBox(height: AppDimens.paddingS),
            Text(
              'Les avis de vos clients apparaîtront ici',
              style: TextStyle(color: AppColors.grey500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimens.paddingM),
      itemCount: _reviews.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingM),
      itemBuilder: (context, index) {
        if (index == _reviews.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }
        return _ReviewCard(
          review: _reviews[index],
          onReply: () => _showReplyDialog(_reviews[index]),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onReply;

  const _ReviewCard({required this.review, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Établissement
            if (review.establishment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.building,
                        size: 12, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      review.establishment!.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimens.paddingS),

            // Header : auteur + note + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.grey200,
                  child: Text(
                    review.user?.firstName.isNotEmpty == true
                        ? review.user!.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.grey700),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.user != null
                            ? '${review.user!.firstName} ${review.user!.lastName}'
                            : 'Anonyme',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy', 'fr')
                                .format(review.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Commentaire
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingS),
              Text(
                review.comment,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.grey700, height: 1.5),
              ),
            ],

            // Réponse existante
            if (review.hasPartnerReply) ...[
              const SizedBox(height: AppDimens.paddingS),
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Iconsax.message_text,
                            size: 13, color: AppColors.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Votre réponse',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.partnerReply!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey700),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimens.paddingS),
            const Divider(height: 1),
            const SizedBox(height: AppDimens.paddingXS),

            // Bouton répondre
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: Icon(
                  review.hasPartnerReply ? Iconsax.edit : Iconsax.message_add,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
                label: Text(
                  review.hasPartnerReply ? 'Modifier la réponse' : 'Répondre',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
