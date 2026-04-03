import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/repositories/suggestion_repository.dart';

class SuggestionsListPage extends StatefulWidget {
  const SuggestionsListPage({super.key});

  @override
  State<SuggestionsListPage> createState() => _SuggestionsListPageState();
}

class _SuggestionsListPageState extends State<SuggestionsListPage> {
  final _repo = SuggestionRepository();
  final _scrollController = ScrollController();

  List<SuggestionModel> _suggestions = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;
  bool _isAuthError = false;

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
      _isAuthError = false;
      _page = 1;
    });
    try {
      final result = await _repo.getAll(page: 1);
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
          if (e is UnauthorizedException) {
            _isAuthError = true;
          } else {
            _error = e.toString();
          }
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await _repo.getAll(page: _page + 1);
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

  SuggestionModel _copyWith(
    SuggestionModel s, {
    int? voteCount,
    bool? hasVoted,
    int? downvoteCount,
    bool? hasDownvoted,
  }) {
    return SuggestionModel(
      id: s.id,
      name: s.name,
      address: s.address,
      phone: s.phone,
      description: s.description,
      categoryId: s.categoryId,
      categoryName: s.categoryName,
      wilayaId: s.wilayaId,
      wilayaName: s.wilayaName,
      suggestedBy: s.suggestedBy,
      suggesterName: s.suggesterName,
      suggesterAvatar: s.suggesterAvatar,
      voteCount: voteCount ?? s.voteCount,
      hasVoted: hasVoted ?? s.hasVoted,
      downvoteCount: downvoteCount ?? s.downvoteCount,
      hasDownvoted: hasDownvoted ?? s.hasDownvoted,
      status: s.status,
      adminNote: s.adminNote,
      createdAt: s.createdAt,
    );
  }

  Future<void> _vote(int index) async {
    final s = _suggestions[index];
    setState(() {
      _suggestions[index] = _copyWith(
        s,
        voteCount: s.hasVoted ? s.voteCount - 1 : s.voteCount + 1,
        hasVoted: !s.hasVoted,
      );
    });

    try {
      final result = await _repo.vote(s.id);
      if (mounted) {
        setState(() {
          _suggestions[index] = _copyWith(
            _suggestions[index],
            voteCount: result['vote_count'] as int,
            hasVoted: result['voted'] as bool,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _suggestions[index] = s);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.redLight),
        );
      }
    }
  }

  Future<void> _downvote(int index) async {
    final s = _suggestions[index];
    setState(() {
      _suggestions[index] = _copyWith(
        s,
        downvoteCount:
            s.hasDownvoted ? s.downvoteCount - 1 : s.downvoteCount + 1,
        hasDownvoted: !s.hasDownvoted,
      );
    });

    try {
      final result = await _repo.downvote(s.id);
      if (mounted) {
        setState(() {
          _suggestions[index] = _copyWith(
            _suggestions[index],
            downvoteCount: result['downvote_count'] as int,
            hasDownvoted: result['downvoted'] as bool,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _suggestions[index] = s);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.redLight),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Suggestions de la communauté'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.main),
        ),
        actions: [
          if (context.read<AuthBloc>().state is AuthAuthenticated)
            IconButton(
              icon: const Icon(Iconsax.add_circle),
              tooltip: 'Suggérer un établissement',
              onPressed: () => context.push('/suggestions/new'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.profile_circle,
                size: 48,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            const Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.grey800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingS),
            const Text(
              'Connectez-vous pour accéder aux suggestions de la communauté et voter pour vos établissements préférés.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (_isAuthError) {
      return _buildLoginRequired();
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
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.shop_add, size: 64, color: AppColors.grey300),
            const SizedBox(height: AppDimens.paddingM),
            const Text(
              'Aucune suggestion pour le moment',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimens.paddingS),
            const Text(
              'Soyez le premier à suggérer un établissement !',
              style: TextStyle(color: AppColors.grey500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (context.read<AuthBloc>().state is AuthAuthenticated) ...[
              const SizedBox(
                  height: AppDimens.paddingL, width: AppDimens.paddingM),
              ElevatedButton.icon(
                onPressed: () => context.push('/suggestions/new'),
                icon: const Icon(Iconsax.add),
                label: const Text('Faire une suggestion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                    vertical: AppDimens.paddingM,
                  ),
                ),
              ),
            ],
          ],
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
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }
        return _SuggestionCard(
          suggestion: _suggestions[index],
          onVote: () => _vote(index),
          onDownvote: () => _downvote(index),
        );
      },
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

// ── Card ────────────────────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final SuggestionModel suggestion;
  final VoidCallback onVote;
  final VoidCallback onDownvote;

  const _SuggestionCard({
    required this.suggestion,
    required this.onVote,
    required this.onDownvote,
  });

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
            // Header: nom + catégorie
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                // Boutons vote
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _VoteButton(
                      count: s.voteCount,
                      voted: s.hasVoted,
                      onTap: onVote,
                    ),
                    const SizedBox(width: 8),
                    _DownvoteButton(
                      count: s.downvoteCount,
                      downvoted: s.hasDownvoted,
                      onTap: onDownvote,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppDimens.paddingS),

            // Adresse
            Row(
              children: [
                const Icon(Iconsax.location,
                    size: 13, color: AppColors.grey500),
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

            // Phone
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

            const SizedBox(height: AppDimens.paddingM),
            const Divider(height: 1),
            const SizedBox(height: AppDimens.paddingS),

            // Footer: suggester + wilaya + date
            Row(
              children: [
                const Icon(Iconsax.user, size: 13, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  s.suggesterName ?? 'Anonyme',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                if (s.wilayaName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                        color: AppColors.grey400, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Iconsax.location,
                      size: 11, color: AppColors.grey400),
                  const SizedBox(width: 3),
                  Text(s.wilayaName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey500)),
                ],
                const Spacer(),
                Text(
                  _formatRelativeDate(s.createdAt),
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.grey400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vote button ────────────────────────────────────────────────────────────────

class _VoteButton extends StatelessWidget {
  final int count;
  final bool voted;
  final VoidCallback onTap;

  const _VoteButton(
      {required this.count, required this.voted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: voted
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: AppColors.primaryGreen,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              voted ? Iconsax.like5 : Iconsax.like_1,
              size: 16,
              color: voted ? AppColors.white : AppColors.primaryGreen,
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: voted ? AppColors.white : AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Downvote button ─────────────────────────────────────────────────────────────

class _DownvoteButton extends StatelessWidget {
  final int count;
  final bool downvoted;
  final VoidCallback onTap;

  const _DownvoteButton(
      {required this.count, required this.downvoted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: downvoted ? red : red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: red, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              downvoted ? Iconsax.dislike4 : Iconsax.dislike,
              size: 16,
              color: downvoted ? AppColors.white : red,
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: downvoted ? AppColors.white : red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
