import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../home/data/models/category_model.dart';

/// Bottom sheet pour sélectionner une catégorie
class CategoryFilterSheet extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category?> onSelected;

  const CategoryFilterSheet({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onSelected,
  });

  static Future<Category?> show(
    BuildContext context, {
    required List<Category> categories,
    String? selectedCategoryId,
  }) async {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => CategoryFilterSheet(
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          onSelected: (category) => Navigator.pop(context, category),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final activeCategories = categories.where((c) => c.isActive).toList();
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.categoryFilter,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scaffoldBackground),
              ),
              if (selectedCategoryId != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: Text(context.l10n.clearFilters),
                ),
            ],
          ),
        ),

        const Divider(),

        // Categories list (inactive categories hidden)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS),
            itemCount: activeCategories.length,
            itemBuilder: (context, index) {
              final category = activeCategories[index];
              final isSelected = category.id == selectedCategoryId;

              return ListTile(
                onTap: () => onSelected(category),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: category.icon != null
                      ? Image.network(
                          category.icon!,
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => Icon(
                            Iconsax.category,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.grey500,
                          ),
                        )
                      : Icon(
                          Iconsax.category,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.grey500,
                        ),
                ),
                title: Text(
                  category.localizedName(lang),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.scaffoldBackground,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Iconsax.tick_circle5,
                        color: AppColors.primaryGreen)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet pour sélectionner une commune (liée à une wilaya)
class CommuneFilterSheet extends StatelessWidget {
  final List<Commune> communes;
  final String? selectedCommuneId;
  final ValueChanged<Commune?> onSelected;

  const CommuneFilterSheet({
    super.key,
    required this.communes,
    this.selectedCommuneId,
    required this.onSelected,
  });

  static Future<Commune?> show(
    BuildContext context, {
    required List<Commune> communes,
    String? selectedCommuneId,
  }) async {
    return showModalBottomSheet<Commune>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => CommuneFilterSheet(
          communes: communes,
          selectedCommuneId: selectedCommuneId,
          onSelected: (commune) => Navigator.pop(context, commune),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.commune,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scaffoldBackground),
              ),
              if (selectedCommuneId != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: Text(context.l10n.clearFilters),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS),
            itemCount: communes.length,
            itemBuilder: (context, index) {
              final commune = communes[index];
              final isSelected = commune.id == selectedCommuneId;
              return ListTile(
                onTap: () => onSelected(commune),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Icon(
                    Iconsax.location,
                    color:
                        isSelected ? AppColors.primaryGreen : AppColors.grey500,
                  ),
                ),
                title: Text(
                  commune.localizedName(lang),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.scaffoldBackground,
                  ),
                ),
                subtitle: commune.postalCode != null
                    ? Text(
                        commune.postalCode!,
                        style: const TextStyle(fontSize: 12, color: AppColors.scaffoldBackground),
                      )
                    : null,
                trailing: isSelected
                    ? const Icon(Iconsax.tick_circle5,
                        color: AppColors.primaryGreen)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet pour sélectionner une sous-catégorie
class SubcategoryFilterSheet extends StatelessWidget {
  final List<SubCategory> subcategories;
  final String? selectedSubcategoryId;
  final ValueChanged<SubCategory?> onSelected;

  const SubcategoryFilterSheet({
    super.key,
    required this.subcategories,
    this.selectedSubcategoryId,
    required this.onSelected,
  });

  static Future<SubCategory?> show(
    BuildContext context, {
    required List<SubCategory> subcategories,
    String? selectedSubcategoryId,
  }) async {
    return showModalBottomSheet<SubCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SubcategoryFilterSheet(
          subcategories: subcategories,
          selectedSubcategoryId: selectedSubcategoryId,
          onSelected: (sub) => Navigator.pop(context, sub),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.subcategoryLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scaffoldBackground),
              ),
              if (selectedSubcategoryId != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: Text(context.l10n.clearFilters),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final sub = subcategories[index];
              final isSelected = sub.id == selectedSubcategoryId;
              return ListTile(
                onTap: () => onSelected(sub),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Icon(
                    Iconsax.category_2,
                    color:
                        isSelected ? AppColors.primaryGreen : AppColors.grey500,
                  ),
                ),
                title: Text(
                  sub.localizedName(lang),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.scaffoldBackground,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Iconsax.tick_circle5,
                        color: AppColors.primaryGreen)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet pour sélectionner une wilaya
class WilayaFilterSheet extends StatefulWidget {
  final List<Wilaya> wilayas;
  final String? selectedWilayaId;
  final ValueChanged<Wilaya?> onSelected;

  const WilayaFilterSheet({
    super.key,
    required this.wilayas,
    this.selectedWilayaId,
    required this.onSelected,
  });

  static Future<Wilaya?> show(
    BuildContext context, {
    required List<Wilaya> wilayas,
    String? selectedWilayaId,
  }) async {
    return showModalBottomSheet<Wilaya>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => WilayaFilterSheet(
          wilayas: wilayas,
          selectedWilayaId: selectedWilayaId,
          onSelected: (wilaya) => Navigator.pop(context, wilaya),
        ),
      ),
    );
  }

  @override
  State<WilayaFilterSheet> createState() => _WilayaFilterSheetState();
}

class _WilayaFilterSheetState extends State<WilayaFilterSheet> {
  final _searchController = TextEditingController();
  List<Wilaya> _filteredWilayas = [];

  late final List<Wilaya> _activeWilayas;

  @override
  void initState() {
    super.initState();
    _activeWilayas = widget.wilayas.where((w) => w.isActive).toList();
    _filteredWilayas = _activeWilayas;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterWilayas(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWilayas = _activeWilayas;
      } else {
        _filteredWilayas = _activeWilayas
            .where((w) =>
                w.name.toLowerCase().contains(query.toLowerCase()) ||
                w.code.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.wilaya,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scaffoldBackground),
              ),
              if (widget.selectedWilayaId != null)
                TextButton(
                  onPressed: () => widget.onSelected(null),
                  child: Text(context.l10n.clearFilters),
                ),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: TextField(
            controller: _searchController,
            onChanged: _filterWilayas,
            decoration: InputDecoration(
              hintText: context.l10n.searchWilayaHint,
              prefixIcon: const Icon(Iconsax.search_normal, size: 20),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Wilayas list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS),
            itemCount: _filteredWilayas.length,
            itemBuilder: (context, index) {
              final wilaya = _filteredWilayas[index];
              final isSelected = wilaya.id == widget.selectedWilayaId;

              return ListTile(
                onTap: () => widget.onSelected(wilaya),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    wilaya.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.scaffoldBackground,
                    ),
                  ),
                ),
                title: Text(
                  wilaya.localizedName(lang),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.scaffoldBackground,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Iconsax.tick_circle5,
                        color: AppColors.primaryGreen)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet pour sélectionner une note minimum
class RatingFilterSheet extends StatelessWidget {
  final double? selectedRating;
  final ValueChanged<double?> onSelected;

  const RatingFilterSheet({
    super.key,
    this.selectedRating,
    required this.onSelected,
  });

  static Future<double?> show(
    BuildContext context, {
    double? selectedRating,
  }) async {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RatingFilterSheet(
        selectedRating: selectedRating,
        onSelected: (rating) => Navigator.pop(context, rating),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratings = [4.5, 4.0, 3.5, 3.0, 2.0];

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.filterMinRating,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scaffoldBackground),
              ),
              if (selectedRating != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: Text(context.l10n.clearFilters),
                ),
            ],
          ),

          const SizedBox(height: AppDimens.paddingM),

          // Rating options
          ...ratings.map((rating) {
            final isSelected = selectedRating == rating;
            return ListTile(
              onTap: () => onSelected(rating),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return Icon(
                    starValue <= rating
                        ? Icons.star_rounded
                        : starValue - 0.5 <= rating
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    color: AppColors.starFilled,
                    size: 20,
                  );
                }),
              ),
              title: Text(
                context.l10n.ratingAndAbove(rating.toString()),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.scaffoldBackground,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Iconsax.tick_circle5,
                      color: AppColors.primaryGreen)
                  : null,
            );
          }),

          const SizedBox(height: AppDimens.paddingM),
        ],
      ),
    );
  }
}

/// Bottom sheet pour trier les résultats
class SortFilterSheet extends StatelessWidget {
  final String? selectedSortBy;
  final String? selectedSortOrder;
  final void Function(String? sortBy, String? sortOrder) onSelected;

  const SortFilterSheet({
    super.key,
    this.selectedSortBy,
    this.selectedSortOrder,
    required this.onSelected,
  });

  static Future<({String? sortBy, String? sortOrder})?> show(
    BuildContext context, {
    String? selectedSortBy,
    String? selectedSortOrder,
  }) async {
    return showModalBottomSheet<({String? sortBy, String? sortOrder})>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SortFilterSheet(
        selectedSortBy: selectedSortBy,
        selectedSortOrder: selectedSortOrder,
        onSelected: (sortBy, sortOrder) =>
            Navigator.pop(context, (sortBy: sortBy, sortOrder: sortOrder)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      (sortBy: null, sortOrder: null, label: context.l10n.sortRelevance, icon: Iconsax.flash),
      (sortBy: 'average_rating', sortOrder: 'desc', label: context.l10n.sortBestRated, icon: Iconsax.star),
      (sortBy: 'name', sortOrder: 'asc', label: context.l10n.sortAlphabetical, icon: Iconsax.text_block),
      (sortBy: 'created_at', sortOrder: 'desc', label: context.l10n.sortRecentLabel, icon: Iconsax.clock),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.sortBy,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.scaffoldBackground),
            ),
          ),

          const SizedBox(height: AppDimens.paddingM),

          // Sort options
          ...options.map((opt) {
            final isSelected = selectedSortBy == opt.sortBy &&
                selectedSortOrder == opt.sortOrder;
            return ListTile(
              onTap: () => onSelected(opt.sortBy, opt.sortOrder),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen.withValues(alpha: 0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Icon(
                  opt.icon,
                  size: 20,
                  color:
                      isSelected ? AppColors.primaryGreen : AppColors.grey500,
                ),
              ),
              title: Text(
                opt.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.scaffoldBackground,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Iconsax.tick_circle5,
                      color: AppColors.primaryGreen)
                  : null,
            );
          }),

          const SizedBox(height: AppDimens.paddingM),
        ],
      ),
    );
  }
}

/// Bottom sheet pour sélectionner une gamme de prix
class PriceFilterSheet extends StatelessWidget {
  final String? selectedPriceRange;
  final ValueChanged<String?> onSelected;

  const PriceFilterSheet({
    super.key,
    this.selectedPriceRange,
    required this.onSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    String? selectedPriceRange,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PriceFilterSheet(
        selectedPriceRange: selectedPriceRange,
        onSelected: (price) => Navigator.pop(context, price),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceRanges = [
      ('\$', context.l10n.priceEconomicalLabel),
      ('\$\$', context.l10n.priceModerateLabel),
      ('\$\$\$', context.l10n.priceHighLabel),
      ('\$\$\$\$', context.l10n.priceLuxuryLabel),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.priceRange,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.scaffoldBackground),
              ),
              if (selectedPriceRange != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: Text(context.l10n.clearFilters),
                ),
            ],
          ),

          const SizedBox(height: AppDimens.paddingM),

          // Price options
          ...priceRanges.map((price) {
            final isSelected = selectedPriceRange == price.$1;
            return ListTile(
              onTap: () => onSelected(price.$1),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen.withValues(alpha: 0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                alignment: Alignment.center,
                child: Text(
                  price.$1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? AppColors.primaryGreen : AppColors.grey600,
                  ),
                ),
              ),
              title: Text(
                price.$2,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.scaffoldBackground,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Iconsax.tick_circle5,
                      color: AppColors.primaryGreen)
                  : null,
            );
          }),

          const SizedBox(height: AppDimens.paddingM),
        ],
      ),
    );
  }
}
