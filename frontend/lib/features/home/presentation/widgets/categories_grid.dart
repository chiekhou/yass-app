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
      'slug': 'restaurants',
      'color': AppColors.categoryColors[0]
    },
    {
      'id': '2',
      'name': 'Hôtels',
      'slug': 'hebergement',
      'color': AppColors.categoryColors[1]
    },
    {
      'id': '3',
      'name': 'Santé',
      'slug': 'sante',
      'color': AppColors.categoryColors[2]
    },
    {
      'id': '4',
      'name': 'Shopping',
      'slug': 'shopping',
      'color': AppColors.categoryColors[3]
    },
    {
      'id': '5',
      'name': 'Services',
      'slug': 'services-locaux',
      'color': AppColors.categoryColors[4]
    },
    {
      'id': '6',
      'name': 'Éducation',
      'slug': 'education',
      'color': AppColors.categoryColors[5]
    },
    {
      'id': '7',
      'name': 'Sport',
      'slug': 'sports-activites-loisirs',
      'color': AppColors.categoryColors[6]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final realCats = (categories != null && categories!.isNotEmpty)
        ? categories!.take(7).toList()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          if (realCats != null) ...[
            ...realCats.asMap().entries.map((e) => _CategoryItem(
                  name: e.value.name,
                  slug: e.value.slug,
                  color: AppColors
                      .categoryColors[e.key % AppColors.categoryColors.length],
                  onTap: () => context.push(
                    '${AppRoutes.category.replaceFirst(':id', e.value.id)}?name=${Uri.encodeComponent(e.value.name)}',
                  ),
                )),
            _CategoryItem(
              name: 'Plus',
              slug: '__more__',
              color: AppColors.grey600,
              onTap: () =>
                  context.push(AppRoutes.allCategories, extra: categories),
            ),
          ] else ...[
            ...List.generate(_defaultCategories.length, (i) {
              final cat = _defaultCategories[i];
              return _CategoryItem(
                name: cat['name'] as String,
                slug: cat['slug'] as String,
                color: cat['color'] as Color,
                onTap: () => context.push(
                  '${AppRoutes.category.replaceFirst(':id', cat['id'] as String)}?name=${cat['name']}',
                ),
              );
            }),
            _CategoryItem(
              name: 'Plus',
              slug: '__more__',
              color: AppColors.grey600,
              onTap: () => context.push(AppRoutes.allCategories),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final String slug;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.name,
    required this.slug,
    required this.color,
    required this.onTap,
  });

  IconData _icon() {
    switch (slug) {
      case 'restaurants':
        return Iconsax.coffee;
      case 'hebergement':
      case 'hotels-sejours':
        return Iconsax.building_4;
      case 'sante':
      case 'sante-medical':
        return Iconsax.health;
      case 'shopping':
      case 'commerces':
        return Iconsax.bag_2;
      case 'services-locaux':
      case 'maison-services':
        return Iconsax.people;
      case 'education':
      case 'formation-enseignement':
        return Iconsax.book_1;
      case 'sports-activites-loisirs':
      case 'activites-loisirs':
        return Iconsax.weight;
      case 'beaute-bien-etre':
      case 'salons-beaute-spas':
        return Iconsax.lovely;
      case 'automobile':
        return Iconsax.car;
      case 'alimentation':
        return Iconsax.cup;
      case 'vie-nocturne':
        return Iconsax.moon;
      case 'art-loisirs':
        return Iconsax.brush_1;
      case 'animaux-compagnie':
        return Iconsax.pet;
      case 'services-financiers':
        return Iconsax.money_2;
      case 'voyage-tourisme':
        return Iconsax.airplane;
      case 'evenements':
      case 'organisation-evenements':
        return Iconsax.calendar_1;
      case 'media':
        return Iconsax.video_play;
      case 'organisation-religieuse':
        return Iconsax.star_1;
      case 'services-destines-professionnels':
      case 'services-professionnels':
        return Iconsax.briefcase;
      case 'maison-travaux':
        return Iconsax.home_2;
      default:
        return Iconsax.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMore = slug == '__more__';
    final iconData = isMore ? Iconsax.more : _icon();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color.lerp(Colors.white, color, 0.75)!,
                  color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Icon(iconData, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
