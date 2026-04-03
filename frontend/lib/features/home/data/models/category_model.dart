import 'package:equatable/equatable.dart';

/// Helper function to parse double from dynamic value (String or num)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// ==================== CATEGORY ====================

class Category extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String slug;
  final String? description;
  final String? descriptionAr;
  final String? icon;
  final String? image;
  final String? color;
  final int order;
  final List<SubCategory>? subcategories;
  final int? establishmentsCount;

  const Category({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.slug,
    this.description,
    this.descriptionAr,
    this.icon,
    this.image,
    this.color,
    this.order = 0,
    this.subcategories,
    this.establishmentsCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      slug: json['slug'] ?? '',
      description: json['description'],
      descriptionAr: json['description_ar'],
      icon: json['icon'],
      image: json['image'],
      color: json['color'],
      order: json['order'] ?? 0,
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((e) => SubCategory.fromJson(e))
              .toList()
          : null,
      establishmentsCount: json['establishments_count'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        slug,
        icon,
        color,
        order,
        subcategories,
        establishmentsCount,
      ];
}

// ==================== SUBCATEGORY ====================

class SubCategory extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String slug;
  final String? description;
  final String? descriptionAr;
  final String? icon;
  final String? image;
  final int order;
  final String? categoryId;
  final Category? category;

  const SubCategory({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.slug,
    this.description,
    this.descriptionAr,
    this.icon,
    this.image,
    this.order = 0,
    this.categoryId,
    this.category,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      slug: json['slug'] ?? '',
      description: json['description'],
      descriptionAr: json['description_ar'],
      icon: json['icon'],
      image: json['image'],
      order: json['order'] ?? 0,
      categoryId: json['category_id'],
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, nameAr, slug, icon, order, categoryId];
}

// ==================== WILAYA ====================

class Wilaya extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final double? latitude;
  final double? longitude;
  final List<Commune>? communes;

  const Wilaya({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.latitude,
    this.longitude,
    this.communes,
  });

  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      communes: json['communes'] != null
          ? (json['communes'] as List)
              .map((e) => Commune.fromJson(e))
              .toList()
          : null,
    );
  }

  @override
  List<Object?> get props => [id, code, name, nameAr, latitude, longitude];
}

// ==================== COMMUNE ====================

class Commune extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? wilayaId;

  const Commune({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.wilayaId,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      postalCode: json['postal_code'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      wilayaId: json['wilaya_id'],
    );
  }

  @override
  List<Object?> get props => [id, code, name, nameAr, postalCode];
}
