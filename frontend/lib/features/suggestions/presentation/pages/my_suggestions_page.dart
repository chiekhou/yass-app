import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/repositories/suggestion_repository.dart';

class MySuggestionsPage extends StatefulWidget {
  const MySuggestionsPage({super.key});

  @override
  State<MySuggestionsPage> createState() => _MySuggestionsPageState();
}

class _MySuggestionsPageState extends State<MySuggestionsPage> {
  final _repo = SuggestionRepository();
  final _scrollController = ScrollController();

  List<SuggestionModel> _suggestions = [];
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
      final result = await _repo.getMine(page: 1);
      if (mounted) {
        setState(() {
          _suggestions = result.items;
          _hasMore = result.pagination.hasNext;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await _repo.getMine(page: _page + 1);
      if (mounted) {
        setState(() {
          _suggestions.addAll(result.items);
          _hasMore = result.pagination.hasNext;
          _page++;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kleinBlue,
      appBar: AppBar(
        title: const Text('Mes suggestions'),
        backgroundColor: AppColors.kleinBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            tooltip: 'Faire une suggestion',
            onPressed: () => context.push(AppRoutes.newSuggestion),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accentGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: AppColors.white),
              const SizedBox(height: AppDimens.paddingM),
              Text(_error!, style: const TextStyle(color: AppColors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimens.paddingM),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.shop_add,
                    size: 48, color: AppColors.white),
              ),
              const SizedBox(height: AppDimens.paddingL),
              const Text(
                'Aucune suggestion pour le moment',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingS),
              const Text(
                'Suggérez un établissement que vous aimeriez voir sur la plateforme.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.newSuggestion),
                icon: const Icon(Iconsax.add),
                label: const Text('Faire une suggestion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingXL,
                    vertical: AppDimens.paddingM,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimens.paddingM),
      itemCount: _suggestions.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingM),
      itemBuilder: (context, index) {
        if (index == _suggestions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: CircularProgressIndicator(color: AppColors.white),
            ),
          );
        }
        return _MySuggestionCard(suggestion: _suggestions[index]);
      },
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _MySuggestionCard extends StatelessWidget {
  final SuggestionModel suggestion;

  const _MySuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final s = suggestion;

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
            // En-tête : nom + badge statut
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.categoryName != null)
                        Text(
                          s.categoryName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        s.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.statusColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusRound),
                    border: Border.all(
                        color: s.statusColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.statusIcon, size: 12, color: s.statusColor),
                      const SizedBox(width: 4),
                      Text(
                        s.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: s.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.paddingS),

            // Adresse
            Row(
              children: [
                const Icon(Iconsax.location, size: 13, color: AppColors.grey500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.address,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.grey600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Téléphone
            if (s.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.call, size: 13, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(s.phone!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey600)),
                ],
              ),
            ],

            // Description
            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingS),
              Text(
                s.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.grey700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Note admin (si rejetée)
            if (s.adminNote != null && s.adminNote!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingS),
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: s.statusColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  border: Border.all(
                      color: s.statusColor.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.info_circle,
                        size: 14, color: s.statusColor),
                    const SizedBox(width: AppDimens.paddingS),
                    Expanded(
                      child: Text(
                        s.adminNote!,
                        style: TextStyle(
                            fontSize: 12,
                            color: s.statusColor,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimens.paddingM),
            const Divider(height: 1),
            const SizedBox(height: AppDimens.paddingS),

            // Footer : wilaya + votes + date
            Row(
              children: [
                if (s.wilayaName != null) ...[
                  const Icon(Iconsax.location,
                      size: 11, color: AppColors.grey400),
                  const SizedBox(width: 3),
                  Text(s.wilayaName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey500)),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                        color: AppColors.grey400, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Iconsax.like_1,
                    size: 12, color: AppColors.primaryGreen.withValues(alpha: 0.7)),
                const SizedBox(width: 3),
                Text(
                  '${s.voteCount} vote${s.voteCount > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGreen.withValues(alpha: 0.8)),
                ),
                const Spacer(),
                Text(
                  _formatRelativeDate(s.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inSeconds < 60) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
  if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem.';
  if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
  return 'il y a ${(diff.inDays / 365).floor()} an(s)';
}
