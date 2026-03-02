import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
                'Catégorie',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (selectedCategoryId != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: const Text('Effacer'),
                ),
            ],
          ),
        ),

        const Divider(),

        // Categories list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
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
                  category.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primaryGreen : null,
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

  @override
  void initState() {
    super.initState();
    _filteredWilayas = widget.wilayas;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterWilayas(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWilayas = widget.wilayas;
      } else {
        _filteredWilayas = widget.wilayas
            .where((w) =>
                w.name.toLowerCase().contains(query.toLowerCase()) ||
                w.code.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                'Wilaya',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.selectedWilayaId != null)
                TextButton(
                  onPressed: () => widget.onSelected(null),
                  child: const Text('Effacer'),
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
              hintText: 'Rechercher une wilaya...',
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
                          : AppColors.grey600,
                    ),
                  ),
                ),
                title: Text(
                  wilaya.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primaryGreen : null,
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
                'Note minimum',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (selectedRating != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: const Text('Effacer'),
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
                '$rating et plus',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primaryGreen : null,
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
      (sortBy: null, sortOrder: null, label: 'Pertinence', icon: Iconsax.flash),
      (sortBy: 'average_rating', sortOrder: 'desc', label: 'Mieux noté', icon: Iconsax.star),
      (sortBy: 'name', sortOrder: 'asc', label: 'A → Z', icon: Iconsax.text_block),
      (sortBy: 'created_at', sortOrder: 'desc', label: 'Plus récent', icon: Iconsax.clock),
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
              'Trier par',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  color: isSelected ? AppColors.primaryGreen : AppColors.grey500,
                ),
              ),
              title: Text(
                opt.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primaryGreen : null,
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
      ('\$', 'Économique'),
      ('\$\$', 'Modéré'),
      ('\$\$\$', 'Élevé'),
      ('\$\$\$\$', 'Luxe'),
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
                'Gamme de prix',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (selectedPriceRange != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: const Text('Effacer'),
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
                  color: isSelected ? AppColors.primaryGreen : null,
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
