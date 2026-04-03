import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../suggestions/data/models/suggestion_model.dart';
import '../../../suggestions/data/repositories/suggestion_repository.dart';
import '../widgets/admin_drawer.dart';

class AdminSuggestionsPage extends StatefulWidget {
  const AdminSuggestionsPage({super.key});

  @override
  State<AdminSuggestionsPage> createState() => _AdminSuggestionsPageState();
}

class _AdminSuggestionsPageState extends State<AdminSuggestionsPage> {
  final _repo = SuggestionRepository();
  final _scrollController = ScrollController();

  List<SuggestionModel> _suggestions = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;
  String _statusFilter = 'all';

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
      final result = await _repo.adminGetAll(
        page: 1,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
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
      final result = await _repo.adminGetAll(
        page: _page + 1,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
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

  Future<void> _approve(SuggestionModel s) async {
    final confirm = await _showConfirmDialog(
      'Approuver la suggestion',
      'Approuver « ${s.name} » ? Elle sera convertie en établissement.',
      confirmLabel: 'Approuver',
      confirmColor: AppColors.primaryGreen,
    );
    if (!confirm) return;
    try {
      await _repo.adminApprove(s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion approuvée'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.redLight),
        );
      }
    }
  }

  Future<void> _reject(SuggestionModel s) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la suggestion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejeter « ${s.name} » ?'),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.redLight),
            child:
                const Text('Rejeter', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.adminReject(s.id, note: noteController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion rejetée')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.redLight),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String content, {
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel,
                style: const TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Suggestions communauté'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: '/admin/suggestions'),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = [
      ('all', 'Toutes'),
      ('approved', 'Approuvées'),
      ('pending', 'En attente'),
      ('rejected', 'Rejetées'),
    ];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _statusFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.paddingS),
              child: FilterChip(
                label: Text(f.$2),
                selected: selected,
                onSelected: (_) {
                  setState(() => _statusFilter = f.$1);
                  _load();
                },
                selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryGreen : AppColors.grey700,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
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
              'Aucune suggestion',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.grey600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      child: ListView.separated(
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
          final s = _suggestions[index];
          return _AdminSuggestionCard(
            suggestion: s,
            onApprove: s.isPending ? () => _approve(s) : null,
            onReject: s.isPending ? () => _reject(s) : null,
          );
        },
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _AdminSuggestionCard extends StatelessWidget {
  final SuggestionModel suggestion;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AdminSuggestionCard({
    required this.suggestion,
    this.onApprove,
    this.onReject,
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
        border: Border.all(
          color: s.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: s.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
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
                          color: s.statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.paddingS),

            // Address
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

            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingS),
              Text(
                s.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.grey700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (s.adminNote != null && s.adminNote!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingS),
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.info_circle,
                        size: 13, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.adminNote!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimens.paddingS),

            // Votes + suggester
            Row(
              children: [
                const Icon(Iconsax.like_1,
                    size: 13, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  '${s.voteCount} vote${s.voteCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                const Icon(Iconsax.user, size: 13, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  s.suggesterName ?? 'Anonyme',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                if (s.wilayaName != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Iconsax.location,
                      size: 11, color: AppColors.grey400),
                  const SizedBox(width: 3),
                  Text(s.wilayaName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey500)),
                ],
              ],
            ),

            // Action buttons (only for pending)
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(height: 1),
              const SizedBox(height: AppDimens.paddingS),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Iconsax.close_circle, size: 16),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.redLight,
                          side: const BorderSide(color: AppColors.redLight),
                        ),
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: AppDimens.paddingS),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Iconsax.tick_circle, size: 16),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
