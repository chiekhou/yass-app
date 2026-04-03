import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../app_router.dart';
import '../../data/models/category_model.dart';

class CategoriesGrid extends StatelessWidget {
  final List<Category>? categories;

  const CategoriesGrid({super.key, this.categories});

  static final List<Map<String, dynamic>> _defaultCategories = [
    {
      'id': '1',
      'name': 'Restaurants',
      'icon': Iconsax.coffee,
      'color': AppColors.categoryColors[0]
    },
    {
      'id': '2',
      'name': 'Hôtels',
      'icon': Iconsax.building_4,
      'color': AppColors.categoryColors[1]
    },
    {
      'id': '3',
      'name': 'Santé',
      'icon': Iconsax.health,
      'color': AppColors.categoryColors[2]
    },
    {
      'id': '4',
      'name': 'Shopping',
      'icon': Iconsax.shop,
      'color': AppColors.categoryColors[3]
    },
    {
      'id': '5',
      'name': 'Services',
      'icon': Iconsax.setting_2,
      'color': AppColors.categoryColors[4]
    },
    {
      'id': '6',
      'name': 'Éducation',
      'icon': Iconsax.book_1,
      'color': AppColors.categoryColors[5]
    },
    {
      'id': '7',
      'name': 'Sport',
      'icon': Iconsax.weight,
      'color': AppColors.categoryColors[6]
    },
    {
      'id': '8',
      'name': 'Plus',
      'icon': Iconsax.more,
      'color': AppColors.grey600
    },
  ];

  IconData _getIconForCategory(String? icon) {
    switch (icon) {
      case 'restaurant':
        return Iconsax.coffee;
      case 'hotel':
        return Iconsax.building_4;
      case 'health':
        return Iconsax.health;
      default:
        return Iconsax.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCategories = categories != null && categories!.isNotEmpty
        ? categories!.take(8).toList()
        : null;

    final itemCount = displayCategories?.length ?? _defaultCategories.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: List.generate(itemCount, (index) {
          if (displayCategories != null) {
            final cat = displayCategories[index];
            return _CategoryItem(
                name: cat.name,
                icon: _getIconForCategory(cat.icon),
                color: AppColors
                    .categoryColors[index % AppColors.categoryColors.length],
                onTap: () => context.push(
                    '${AppRoutes.category.replaceFirst(':id', cat.id)}?name=${cat.name}'));
          }
          final cat = _defaultCategories[index];
          return _CategoryItem(
              name: cat['name'],
              icon: cat['icon'],
              color: cat['color'],
              onTap: () => context.push(
                  '${AppRoutes.category.replaceFirst(':id', cat['id'])}?name=${cat['name']}'));
        }),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem(
      {required this.name,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(name,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
