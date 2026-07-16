import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../widgets/category_icon_widget.dart';

class AllCategoriesPage extends StatefulWidget {
  final List<Category>? initialCategories;

  const AllCategoriesPage({super.key, this.initialCategories});

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  final CategoryRepository _repository = CategoryRepository();
  List<Category> _categories = [];
  bool _isLoading = true;
  final Set<String> _expandedCategories = {};

  static const int _kMaxVisible = 5;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _repository.getAll(includeSubcategories: true);
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleExpand(String catId) {
    setState(() {
      if (_expandedCategories.contains(catId)) {
        _expandedCategories.remove(catId);
      } else {
        _expandedCategories.add(catId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          context.l10n.moreCategoriesTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _categories.isEmpty
              ? Center(child: Text(context.l10n.noCategoriesAvailable))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  itemCount: _categories.length,
                  itemBuilder: (context, catIndex) {
                    final cat = _categories[catIndex];
                    final langCode = Localizations.localeOf(context).languageCode;
                    final color = AppColors.categoryColors[
                        catIndex % AppColors.categoryColors.length];
                    final subs = cat.subcategories ?? [];
                    final isExpanded = _expandedCategories.contains(cat.id);
                    final hasMore = subs.length > _kMaxVisible;
                    final visibleSubs = (hasMore && !isExpanded)
                        ? subs.take(_kMaxVisible).toList()
                        : subs;
                    final remaining = subs.length - _kMaxVisible;

                    return Padding(
                      padding: const EdgeInsets.only(
                        left: AppDimens.paddingM,
                        right: AppDimens.paddingM,
                        bottom: AppDimens.paddingM,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Catégorie parente ──
                            InkWell(
                              onTap: cat.isActive
                                  ? () => context.push(
                                        '${AppRoutes.category.replaceFirst(':id', cat.id)}?name=${Uri.encodeComponent(cat.localizedName(langCode))}',
                                      )
                                  : null,
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(AppDimens.radiusL),
                                bottom: subs.isEmpty
                                    ? const Radius.circular(AppDimens.radiusL)
                                    : Radius.zero,
                              ),
                              child: Opacity(
                                opacity: cat.isActive ? 1.0 : 0.45,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.paddingM,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      CategoryIconWidget(
                                        slug: cat.slug,
                                        name: cat.localizedName(langCode),
                                        color: cat.isActive ? color : AppColors.grey400,
                                        size: 52,
                                      ),
                                      const SizedBox(width: AppDimens.paddingM),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.localizedName(langCode),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            if (!cat.isActive)
                                              Text(
                                                context.l10n.comingSoonFull,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.grey500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (subs.isNotEmpty && cat.isActive)
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.grey400,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // ── Sous-catégories ──
                            if (subs.isNotEmpty && cat.isActive) ...[
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF0F0F0),
                              ),
                              ...visibleSubs.asMap().entries.map((entry) {
                                final i = entry.key;
                                final sub = entry.value;
                                final isLastVisible = i == visibleSubs.length - 1;
                                final isLastOverall = !hasMore || isExpanded
                                    ? isLastVisible
                                    : false;

                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () => context.push(
                                        AppRoutes.map,
                                        extra: {
                                          'subcategoryId': sub.id,
                                          'query': sub.localizedName(langCode),
                                        },
                                      ),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: isLastOverall
                                            ? const Radius.circular(
                                                AppDimens.radiusL)
                                            : Radius.zero,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 76,
                                          right: AppDimens.paddingM,
                                          top: 12,
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sub.localizedName(langCode),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF4A4A4A),
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.grey300,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isLastVisible)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        indent: 76,
                                        color: Color(0xFFF5F5F5),
                                      ),
                                  ],
                                );
                              }),
                              // ── Bouton Voir plus / Voir moins ──
                              if (hasMore) ...[
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 76,
                                  color: Color(0xFFF5F5F5),
                                ),
                                InkWell(
                                  onTap: () => _toggleExpand(cat.id),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(AppDimens.radiusL),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 76,
                                      right: AppDimens.paddingM,
                                      top: 12,
                                      bottom: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          isExpanded
                                              ? context.l10n.seeLess
                                              : context.l10n.seeNMore(remaining),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.primaryBlue,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
