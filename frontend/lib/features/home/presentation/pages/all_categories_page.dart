import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text(
          'Plus de catégories',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
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
              ? const Center(child: Text('Aucune catégorie disponible'))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  itemCount: _categories.length,
                  itemBuilder: (context, catIndex) {
                    final cat = _categories[catIndex];
                    final color = AppColors.categoryColors[
                        catIndex % AppColors.categoryColors.length];
                    final subs = cat.subcategories ?? [];

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
                              onTap: () => context.push(
                                '${AppRoutes.category.replaceFirst(':id', cat.id)}?name=${Uri.encodeComponent(cat.name)}',
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(AppDimens.radiusL),
                                bottom: subs.isEmpty
                                    ? const Radius.circular(AppDimens.radiusL)
                                    : Radius.zero,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingM,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CategoryIconWidget(
                                      slug: cat.slug,
                                      name: cat.name,
                                      color: color,
                                      size: 52,
                                    ),
                                    const SizedBox(width: AppDimens.paddingM),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    if (subs.isNotEmpty)
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.grey400,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // ── Sous-catégories ──
                            if (subs.isNotEmpty) ...[
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF0F0F0),
                              ),
                              ...subs.asMap().entries.map((entry) {
                                final i = entry.key;
                                final sub = entry.value;
                                final isLast = i == subs.length - 1;
                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () => context.push(
                                        AppRoutes.map,
                                        extra: {
                                          'subcategoryId': sub.id,
                                          'query': sub.name,
                                        },
                                      ),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: isLast
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
                                                sub.name,
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
                                    if (!isLast)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        indent: 76,
                                        color: Color(0xFFF5F5F5),
                                      ),
                                  ],
                                );
                              }),
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
